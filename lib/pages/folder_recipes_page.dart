import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/pages/add_recipe_page.dart';
import 'package:nomnom/pages/view_recipe_page.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/delete_folders_dialog.dart';
import 'package:nomnom/widgets/move_recipes_sheet.dart';
import 'package:nomnom/widgets/recipe_action_bar.dart';
import 'package:nomnom/widgets/recipe_card.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

class FolderRecipesPage extends StatefulWidget {
  const FolderRecipesPage({super.key, required this.folderId});

  final String folderId;

  @override
  State<FolderRecipesPage> createState() => _FolderRecipesPageState();
}

class _FolderRecipesPageState extends State<FolderRecipesPage> {
  static const _debounceDuration = Duration(milliseconds: 300);

  bool _selectionMode = false;
  final Set<String> _selectedRecipeIds = {};

  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  String _debouncedQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedRecipeIds.clear();
    });
  }

  void _enterSearchMode() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _exitSearchMode() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _searching = false;
      _debouncedQuery = '';
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      setState(() => _debouncedQuery = value.trim());
    });
  }

  List<Recipe> _filteredRecipes(List<Recipe> recipes) {
    final query = _debouncedQuery.toLowerCase();
    if (query.isEmpty) return recipes;
    return recipes
        .where((r) => r.name.toLowerCase().contains(query))
        .toList();
  }

  void _toggleSelected(String recipeId) {
    setState(() {
      if (_selectedRecipeIds.contains(recipeId)) {
        _selectedRecipeIds.remove(recipeId);
        if (_selectedRecipeIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedRecipeIds.add(recipeId);
      }
    });
  }

  void _onLongPressRecipe(String recipeId) {
    setState(() {
      _selectionMode = true;
      _selectedRecipeIds
        ..clear()
        ..add(recipeId);
    });
  }

  Future<void> _deleteSelected(RecipeStore store) async {
    if (_selectedRecipeIds.isEmpty) return;

    final confirmed = await showDeleteFoldersDialog(context);
    if (!mounted || !confirmed) return;

    store.deleteRecipes(_selectedRecipeIds);
    _exitSelectionMode();
  }

  Future<void> _moveSelected(RecipeStore store) async {
    if (_selectedRecipeIds.isEmpty) return;

    final folders = store.assignableFolders;
    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No folders available')),
      );
      return;
    }

    final folderId = await showMoveRecipesSheet(context, folders: folders);
    if (!mounted || folderId == null) return;

    store.moveRecipes(ids: _selectedRecipeIds, folderId: folderId);
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final titleStyle = GoogleFonts.antic(
      color: nomnomTheme(context).text,
      fontSize: 24,
    );

    return Scaffold(
      backgroundColor: nomnomTheme(context).background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final folder = store.folderById(widget.folderId);
                  return Row(
                    children: [
                      if (_selectionMode)
                        IconButton(
                          onPressed: _exitSelectionMode,
                          icon: Icon(Icons.close),
                          color: nomnomTheme(context).text,
                          tooltip: 'Cancel',
                        )
                      else if (_searching)
                        IconButton(
                          onPressed: _exitSearchMode,
                          icon: Icon(Icons.close),
                          color: nomnomTheme(context).text,
                          tooltip: 'Close search',
                        )
                      else
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back),
                          color: nomnomTheme(context).text,
                        ),
                      Expanded(
                        child: _selectionMode
                            ? Text(
                                '${_selectedRecipeIds.length} selected',
                                style: titleStyle,
                                overflow: TextOverflow.ellipsis,
                              )
                            : _searching
                                ? TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    style: GoogleFonts.antic(
                                      color: nomnomTheme(context).text,
                                      fontSize: 20,
                                    ),
                                    cursorColor: nomnomTheme(context).text,
                                    decoration: InputDecoration(
                                      hintText: 'Search recipes...',
                                      hintStyle: GoogleFonts.antic(
                                        color: nomnomTheme(context).text.withValues(
                                          alpha: 0.55,
                                        ),
                                        fontSize: 20,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: _onSearchChanged,
                                    textInputAction: TextInputAction.search,
                                  )
                                : Text(
                                    folder?.name ?? '',
                                    style: titleStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                      ),
                      if (!_selectionMode && !_searching) ...[
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddRecipePage(
                                  initialFolderId: widget.folderId,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.add),
                          color: nomnomTheme(context).text,
                        ),
                        IconButton(
                          onPressed: _enterSearchMode,
                          icon: Icon(Icons.search),
                          color: nomnomTheme(context).text,
                          tooltip: 'Search',
                        ),
                        IconButton(
                          onPressed: () => showAppSettingsDialog(context),
                          icon: Icon(Icons.settings),
                          color: nomnomTheme(context).text,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final recipes = _filteredRecipes(
                    store.recipesInFolder(widget.folderId),
                  );
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: recipes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      final isSelected =
                          _selectedRecipeIds.contains(recipe.id);
                      return RecipeCard(
                        key: ValueKey('recipe-${recipe.id}'),
                        recipe: recipe,
                        selected: isSelected,
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelected(recipe.id);
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ViewRecipePage(recipeId: recipe.id),
                            ),
                          );
                        },
                        onLongPress: () => _onLongPressRecipe(recipe.id),
                      );
                    },
                  );
                },
              ),
            ),
            if (_selectionMode)
              RecipeActionBar(
                enabled: _selectedRecipeIds.isNotEmpty,
                onDelete: () => _deleteSelected(store),
                onMove: () => _moveSelected(store),
              ),
          ],
        ),
      ),
    );
  }
}
