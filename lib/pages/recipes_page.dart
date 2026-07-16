import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/models/recipe_folder.dart';
import 'package:nomnom/pages/folder_recipes_page.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/add_folder_dialog.dart';
import 'package:nomnom/widgets/delete_folders_dialog.dart';
import 'package:nomnom/widgets/edit_folder_dialog.dart';
import 'package:nomnom/widgets/folder_action_sheet.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  bool _selectionMode = false;
  final Set<String> _selectedFolderIds = {};

  Future<void> _onAddFolder(BuildContext context, RecipeStore store) async {
    final result = await showAddFolderDialog(context);
    if (result == null) return;
    store.addFolder(name: result.name, color: result.color);
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedFolderIds.clear();
    });
  }

  void _toggleSelected(String folderId) {
    if (folderId == RecipeStore.recentFolderId) return;
    setState(() {
      if (_selectedFolderIds.contains(folderId)) {
        _selectedFolderIds.remove(folderId);
        if (_selectedFolderIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedFolderIds.add(folderId);
      }
    });
  }

  Future<void> _onLongPressFolder(RecipeFolder folder, RecipeStore store) async {
    if (folder.id == RecipeStore.recentFolderId) return;

    setState(() {
      _selectionMode = true;
      _selectedFolderIds
        ..clear()
        ..add(folder.id);
    });

    final action = await showFolderActionSheet(context);
    if (!mounted || action == null) return;

    switch (action) {
      case FolderAction.edit:
        if (_selectedFolderIds.length == 1) {
          await _editSelectedFolder(store);
        }
      case FolderAction.delete:
        await _deleteSelectedFolders(store);
    }
  }

  Future<void> _editSelectedFolder(RecipeStore store) async {
    if (_selectedFolderIds.length != 1) return;
    final id = _selectedFolderIds.first;
    final folder = store.folderById(id);
    if (folder == null) return;

    final newName = await showEditFolderDialog(
      context,
      initialName: folder.name,
    );
    if (!mounted || newName == null) return;

    store.renameFolder(id: id, name: newName);
    _exitSelectionMode();
  }

  Future<void> _deleteSelectedFolders(RecipeStore store) async {
    if (_selectedFolderIds.isEmpty) return;

    final confirmed = await showDeleteFoldersDialog(context);
    if (!mounted || !confirmed) return;

    store.deleteFolders(_selectedFolderIds);
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
              child: Row(
                children: [
                  if (_selectionMode)
                    IconButton(
                      onPressed: _exitSelectionMode,
                      icon: Icon(Icons.close),
                      color: nomnomTheme(context).text,
                      tooltip: 'Cancel',
                    )
                  else
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back),
                      color: nomnomTheme(context).text,
                    ),
                  Expanded(
                    child: Text(
                      _selectionMode
                          ? '${_selectedFolderIds.length} selected'
                          : 'Recipies',
                      style: titleStyle,
                    ),
                  ),
                  if (_selectionMode) ...[
                    IconButton(
                      onPressed: _selectedFolderIds.length == 1
                          ? () => _editSelectedFolder(store)
                          : null,
                      icon: Icon(Icons.edit),
                      color: nomnomTheme(context).text,
                      tooltip: 'Edit folder name',
                    ),
                    IconButton(
                      onPressed: _selectedFolderIds.isNotEmpty
                          ? () => _deleteSelectedFolders(store)
                          : null,
                      icon: Icon(Icons.delete),
                      color: nomnomTheme(context).text,
                      tooltip: 'Delete folder',
                    ),
                  ] else ...[
                    IconButton(
                      onPressed: () => _onAddFolder(context, store),
                      icon: Icon(Icons.add),
                      color: nomnomTheme(context).text,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.search),
                      color: nomnomTheme(context).text,
                    ),
                    IconButton(
                      onPressed: () => showAppSettingsDialog(context),
                      icon: Icon(Icons.settings),
                      color: nomnomTheme(context).text,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: store.folders.length,
                    itemBuilder: (context, index) {
                      final folder = store.folders[index];
                      final isRecent =
                          folder.id == RecipeStore.recentFolderId;
                      final isSelected =
                          _selectedFolderIds.contains(folder.id);

                      return _FolderTile(
                        key: ValueKey('folder-${folder.id}'),
                        folder: folder,
                        selected: isSelected,
                        onTap: () {
                          if (_selectionMode) {
                            if (!isRecent) {
                              _toggleSelected(folder.id);
                            }
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FolderRecipesPage(folderId: folder.id),
                            ),
                          );
                        },
                        onLongPress: isRecent
                            ? null
                            : () => _onLongPressFolder(folder, store),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    super.key,
    required this.folder,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final RecipeFolder folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = nomnomTheme(context);
    final displayColor = folder.id == RecipeStore.recentFolderId
        ? colors.text
        : folder.color;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: colors.text, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          color: selected
              ? colors.text.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(88, 72),
                    painter: _FolderIconPainter(color: displayColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    folder.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.antic(
                      color: displayColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.check_circle,
                    color: colors.text,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderIconPainter extends CustomPainter {
  _FolderIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final tabWidth = size.width * 0.4;
    final tabHeight = size.height * 0.18;
    final bodyTop = tabHeight * 0.7;

    final path = Path()
      ..moveTo(0, bodyTop)
      ..lineTo(0, tabHeight)
      ..lineTo(tabWidth * 0.15, 0)
      ..lineTo(tabWidth, 0)
      ..lineTo(tabWidth + tabHeight * 0.3, bodyTop)
      ..lineTo(size.width, bodyTop)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FolderIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
