import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/data/hive_boxes.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/pages/add_recipe_page.dart';
import 'package:nomnom/pages/calculate_cost_page.dart';
import 'package:nomnom/pages/plan_week_page.dart';
import 'package:nomnom/pages/recipes_page.dart';
import 'package:nomnom/pages/spin_wheel_page.dart';
import 'package:nomnom/pages/view_recipe_page.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/gradient_button.dart';
import 'package:nomnom/widgets/recipe_card.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  final store = RecipeStore();
  await store.load();
  final settings = AppSettings();
  await settings.load();
  runApp(MyApp(store: store, settings: settings));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, RecipeStore? store, AppSettings? settings})
      : store = store ?? RecipeStore(),
        settings = settings ?? AppSettings();

  final RecipeStore store;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: settings,
      child: RecipeStoreScope(
        store: store,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            return MaterialApp(
              title: 'NomNom',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(nightMode: settings.nightMode),
              home: const HomePage(),
            );
          },
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final colors = nomnomTheme(context);
    final recent = store.recentRecipes;
    final titleStyle = GoogleFonts.antic(
      color: colors.text,
      fontSize: 28,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "What's the next meal?",
                      style: titleStyle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => showAppSettingsDialog(context),
                    icon: const Icon(Icons.settings),
                    color: colors.text,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gridHeight = 248.0;
                  final tileWidth = (constraints.maxWidth - 16) / 2;
                  final tileHeight = (gridHeight - 32) / 3;
                  return SizedBox(
                    height: gridHeight,
                    child: GridView.count(
                      crossAxisCount: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: tileWidth / tileHeight,
                      children: [
                        GradientButton(
                          label: 'Plan week',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PlanWeekPage(),
                              ),
                            );
                          },
                        ),
                        GradientButton(
                          label: 'Spin Wheel',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SpinWheelPage(),
                              ),
                            );
                          },
                        ),
                        GradientButton(
                          label: 'Add recipe',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddRecipePage(),
                              ),
                            );
                          },
                        ),
                        GradientButton(
                          label: 'View recipes',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RecipesPage(),
                              ),
                            );
                          },
                        ),
                        GradientButton(
                          label: 'Calculate',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CalculateCostPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Recent recipes',
                style: titleStyle,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final recipe = recent[index];
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ViewRecipePage(recipeId: recipe.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
