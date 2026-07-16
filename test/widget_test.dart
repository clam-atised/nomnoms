import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/data/app_settings.dart';
import 'package:nomnom/data/recipe_store.dart';
import 'package:nomnom/main.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/theme/app_colors.dart';
import 'package:nomnom/widgets/recipe_card.dart';
import 'package:nomnom/widgets/settings_dialog.dart';

void main() {
  testWidgets('Home screen shows title and action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text("What's the next meal?"), findsOneWidget);
    expect(find.text('Plan week'), findsOneWidget);
    expect(find.text('Spin Wheel'), findsOneWidget);
    expect(find.text('Add recipe'), findsOneWidget);
    expect(find.text('View recipes'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
    expect(find.text('Recent recipes'), findsOneWidget);
  });

  testWidgets('Calculate opens page and back returns home', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MyApp());

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.text('Calculate:'), findsOneWidget);
    expect(find.text('cost'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text("What's the next meal?"), findsOneWidget);
  });

  testWidgets('Plan week opens Plan Week page and back returns home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());

    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    expect(find.text('Plan Week'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Noon'), findsOneWidget);
    expect(find.text('Night'), findsOneWidget);
    expect(find.text('Criteria:'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
    expect(find.text('Time: Morning, Lunch, Dinner'), findsNothing);
    expect(find.text('Day: Everyday'), findsNothing);
    expect(find.text('Frequency: Different every day'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text("What's the next meal?"), findsOneWidget);
    expect(find.text('Plan Week'), findsNothing);
  });

  testWidgets('Dropdown switches between week and month views', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());

    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    expect(find.text('Morning'), findsOneWidget);

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthLabel = 'Plan Month: ${monthNames[DateTime.now().month - 1]}';

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    await tester.tap(find.text(monthLabel).last);
    await tester.pumpAndSettle();

    expect(find.text(monthLabel), findsOneWidget);
    expect(find.text('MON'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    // Week meal headers are not used in month view (slots use M/N/Ni).
    expect(find.text('Morning'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan Week').last);
    await tester.pumpAndSettle();

    expect(find.text('Plan Week'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('MON'), findsNothing);
  });

  testWidgets('Plan Week hides cost and calorie when toggles off', (
    WidgetTester tester,
  ) async {
    final store = RecipeStore();
    store.addRecipe(
      Recipe(
        id: store.nextRecipeId(),
        name: 'Soup',
        ingredients: const [Ingredient(quantity: 1, name: 'Salt')],
        preparationMinutes: 5,
        folderId: RecipeStore.recentFolderId,
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    await tester.pumpWidget(MyApp(store: store));
    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    expect(find.text('Cost:'), findsNothing);
    expect(find.text('Calorie:'), findsNothing);
  });

  testWidgets('Plan Week shows Cost and Calorie when toggles on', (
    WidgetTester tester,
  ) async {
    final store = RecipeStore();
    store.addRecipe(
      Recipe(
        id: store.nextRecipeId(),
        name: 'Soup',
        ingredients: const [Ingredient(quantity: 2, name: 'Eggs')],
        preparationMinutes: 5,
        folderId: RecipeStore.recentFolderId,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    store.setIngredientCost('Eggs', 1.5);
    store.setIngredientCalorie('Eggs', 800);

    final settings = AppSettings();
    settings.setShowCost(true);
    settings.setShowCalorie(true);

    await tester.pumpWidget(MyApp(store: store, settings: settings));
    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    // 7 days × 3 slots × (2 × 1.5) = 63; calories 7×3×1600 = 33600 → 33.6k
    expect(find.text('Cost:'), findsOneWidget);
    expect(find.text('63'), findsOneWidget);
    expect(find.text('Calorie:'), findsOneWidget);
    expect(find.text('33.6k'), findsOneWidget);
  });

  testWidgets('Plan Week incomplete cost label shows info tooltip', (
    WidgetTester tester,
  ) async {
    final store = RecipeStore();
    store.addRecipe(
      Recipe(
        id: store.nextRecipeId(),
        name: 'Soup',
        ingredients: const [Ingredient(quantity: 1, name: 'Salt')],
        preparationMinutes: 5,
        folderId: RecipeStore.recentFolderId,
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    final settings = AppSettings();
    settings.setShowCost(true);

    await tester.pumpWidget(MyApp(store: store, settings: settings));
    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    expect(find.text('Cost:'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    final costLabel = find.text('Cost:');
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: costLabel, matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, RecipeStore.costEstimateInfoMessage);
    expect(tooltip.triggerMode, TooltipTriggerMode.tap);
  });

  testWidgets('Plan Month shows estimates with night mode text color', (
    WidgetTester tester,
  ) async {
    final store = RecipeStore();
    store.addRecipe(
      Recipe(
        id: store.nextRecipeId(),
        name: 'Soup',
        ingredients: const [Ingredient(quantity: 1, name: 'Eggs')],
        preparationMinutes: 5,
        folderId: RecipeStore.recentFolderId,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    store.setIngredientCost('Eggs', 2);

    final settings = AppSettings();
    settings.setShowCost(true);
    settings.setNightMode(true);

    await tester.pumpWidget(MyApp(store: store, settings: settings));
    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthLabel = 'Plan Month: ${monthNames[DateTime.now().month - 1]}';

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text(monthLabel).last);
    await tester.pumpAndSettle();

    expect(find.text('Cost:'), findsOneWidget);
    final costText = tester.widget<Text>(find.text('Cost:'));
    expect(costText.style?.color, kNightText);
  });

  Future<void> openRecipesPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View recipes'));
    await tester.pumpAndSettle();
  }

  Future<void> createFolder(
    WidgetTester tester, {
    required String name,
  }) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add New Recipe Folder'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Folder name...'),
      name,
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
  }

  Future<void> openFolderByName(WidgetTester tester, String name) async {
    final folder = find.text(name);
    await tester.ensureVisible(folder);
    await tester.pumpAndSettle();
    await tester.tap(folder);
    await tester.pumpAndSettle();
  }

  Future<void> addIngredientRow(
    WidgetTester tester, {
    required String name,
    String quantity = '1',
  }) async {
    final qtyField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.keyboardType == TextInputType.number,
    );
    await tester.enterText(qtyField.first, quantity);
    final addField = find.widgetWithText(TextField, 'Add..');
    await tester.enterText(addField, name);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Future<void> navigateHomeFromRecipes(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }

  Future<void> openSpinWheel(WidgetTester tester) async {
    await tester.tap(find.text('Spin Wheel'));
    await tester.pumpAndSettle();
  }

  Future<void> spinWheelForMeringue(WidgetTester tester) async {
    await tester.tap(find.text('Meringue').first);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);
  }

  Future<void> toggleSettingSwitch(WidgetTester tester, int index) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(index));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }

  Future<void> createMeringueInDesserts(WidgetTester tester) async {
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Desserts');
    await openFolderByName(tester, 'Desserts');

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '').first,
      'Meringue',
    );

    await addIngredientRow(tester, name: 'Eggs');

    await tester.ensureVisible(find.text('Set timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
  }

  testWidgets('Calculatelists unique ingredients and saves price', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.text('cost'), findsOneWidget);
    expect(find.text('eggs'), findsOneWidget);
    expect(find.text('price'), findsOneWidget);

    await tester.tap(find.text('price'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1.20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('1.20'), findsOneWidget);
    expect(find.text('price'), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Ingredient cost adds up, record estimate cost for a single item',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Switch to calories: unset values show 0; cost is preserved on switch back.
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('calories').last);
    await tester.pumpAndSettle();

    expect(find.text('calories'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('1.20'), findsNothing);

    await tester.tap(find.text('0').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '52');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('52'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('cost').last);
    await tester.pumpAndSettle();

    expect(find.text('cost'), findsOneWidget);
    expect(find.text('1.20'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('calories').last);
    await tester.pumpAndSettle();

    expect(find.text('52'), findsOneWidget);
  });

  testWidgets('View recipes shows only Recent recipes by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);

    expect(find.text('Recipies'), findsOneWidget);
    expect(find.text('Recent recipes'), findsOneWidget);
    expect(find.text('Desserts'), findsNothing);
    expect(find.text('Pescatarian'), findsNothing);
  });

  testWidgets('Add folder dialog creates colored folder on grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Snacks');

    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('Recent recipes'), findsOneWidget);
  });

  testWidgets('View recipes opens folder grid and folder shows name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Desserts');
    await openFolderByName(tester, 'Desserts');

    expect(find.text('Desserts'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Create recipe shows card without unset optional fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    expect(find.text('Add Recipe'), findsNothing);
    expect(find.text('Meringue'), findsOneWidget);
    expect(find.text('Contains:'), findsOneWidget);
    expect(find.text('1 Eggs'), findsOneWidget);
    expect(find.text('Preparation Time: 5 minutes'), findsOneWidget);
    expect(find.textContaining('Day of Week:'), findsNothing);
    expect(find.textContaining('Time of Day:'), findsNothing);
  });

  testWidgets('Recipe appears in Recent folder and on Home cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    // Back to Recipies grid, then Recent recipes folder
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    final recent = find.byKey(const ValueKey('folder-recent'));
    await tester.ensureVisible(recent);
    await tester.pumpAndSettle();
    await tester.tap(recent);
    await tester.pumpAndSettle();

    expect(find.text('Recent recipes'), findsOneWidget);
    expect(find.text('Meringue'), findsOneWidget);

    // Back to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text("What's the next meal?"), findsOneWidget);
    expect(find.text('Plan week'), findsOneWidget);
    expect(find.byType(RecipeCard), findsOneWidget);
    expect(find.text('Meringue'), findsOneWidget);

    // Header remains while recent list can scroll
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.text("What's the next meal?"), findsOneWidget);
    expect(find.text('Spin Wheel'), findsOneWidget);
  });

  testWidgets('Home Add recipe defaults folder to Recent recipes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Add recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Add Recipe'), findsOneWidget);
    expect(find.text('Select folder'), findsNothing);
    expect(find.text('Recent recipes'), findsOneWidget);
  });

  testWidgets('Create recipe without user folders appears in Recent history', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Add recipe'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '').first,
      'Toast',
    );

    await addIngredientRow(tester, name: 'Bread');

    await tester.ensureVisible(find.text('Set timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Back on home — Recent history card
    expect(find.text("What's the next meal?"), findsOneWidget);
    expect(find.text('Toast'), findsOneWidget);
    expect(find.byType(RecipeCard), findsOneWidget);

    // Also visible inside Recent recipes folder
    await tester.tap(find.text('View recipes'));
    await tester.pumpAndSettle();
    final recent = find.byKey(const ValueKey('folder-recent'));
    await tester.ensureVisible(recent);
    await tester.tap(recent);
    await tester.pumpAndSettle();

    expect(find.text('Recent recipes'), findsOneWidget);
    expect(find.text('Toast'), findsOneWidget);
  });

  testWidgets('Spin Wheel result opens View Recipe without check', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    // Navigate home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spin Wheel'));
    await tester.pumpAndSettle();

    expect(find.text('Spin Wheel:'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    // Recent folder (default index 0) includes the recipe on the wheel
    await tester.tap(find.text('Meringue').first);
    // Allow fortune wheel animation to complete
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Selected'), findsOneWidget);

    // Tap recipe name in dialog
    await tester.tap(find.text('Meringue').last);
    await tester.pumpAndSettle();

    expect(find.text('View Recipe'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('Recipe Name:'), findsOneWidget);
  });

  testWidgets('Spin Wheel result hides cost and calories when toggles off', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);
    await navigateHomeFromRecipes(tester);
    await openSpinWheel(tester);
    await spinWheelForMeringue(tester);

    expect(find.text('Cost'), findsNothing);
    expect(find.text('Calories'), findsNothing);
  });

  testWidgets('Spin Wheel result shows estimated cost with info tooltip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);
    await navigateHomeFromRecipes(tester);
    await openSpinWheel(tester);
    await toggleSettingSwitch(tester, 1);
    await spinWheelForMeringue(tester);

    expect(find.text('Cost'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    final dialog = find.byType(AlertDialog);
    final infoIcon = find.descendant(
      of: dialog,
      matching: find.byIcon(Icons.info_outline),
    );
    expect(infoIcon, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: infoIcon, matching: find.byType(Tooltip)),
    );
    expect(
      tooltip.message,
      'Estimated cost. Please fill for more accurate estimate cost',
    );
  });

  testWidgets('Spin Wheel result shows complete cost without info icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);
    await navigateHomeFromRecipes(tester);

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('price'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1.20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await openSpinWheel(tester);
    await toggleSettingSwitch(tester, 1);
    await spinWheelForMeringue(tester);

    expect(find.text('Cost'), findsOneWidget);
    expect(find.text('1.20'), findsOneWidget);

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.byIcon(Icons.info_outline)),
      findsNothing,
    );
  });

  testWidgets('Spin Wheel result shows estimated calories with info tooltip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);
    await navigateHomeFromRecipes(tester);
    await openSpinWheel(tester);
    await toggleSettingSwitch(tester, 2);
    await spinWheelForMeringue(tester);

    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    final dialog = find.byType(AlertDialog);
    final infoIcon = find.descendant(
      of: dialog,
      matching: find.byIcon(Icons.info_outline),
    );
    expect(infoIcon, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: infoIcon, matching: find.byType(Tooltip)),
    );
    expect(
      tooltip.message,
      'Estimated calories. Please fill for more accurate estimate calorie count',
    );
  });

  testWidgets('Spin Wheel result shows complete calories without info icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);
    await navigateHomeFromRecipes(tester);

    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('calories').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('0').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '52');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await openSpinWheel(tester);
    await toggleSettingSwitch(tester, 2);
    await spinWheelForMeringue(tester);

    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('52'), findsOneWidget);

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.byIcon(Icons.info_outline)),
      findsNothing,
    );
  });

  testWidgets('Spin Wheel result shows both cost and calories when enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);
    await navigateHomeFromRecipes(tester);
    await openSpinWheel(tester);
    await toggleSettingSwitch(tester, 1);
    await toggleSettingSwitch(tester, 2);
    await spinWheelForMeringue(tester);

    expect(find.text('Cost'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
  });

  testWidgets('Spin Wheel folder dropdown switches folders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    // Navigate home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spin Wheel'));
    await tester.pumpAndSettle();

    expect(find.text('Recent recipes'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desserts').last);
    await tester.pumpAndSettle();

    expect(find.text('Spin Wheel:'), findsOneWidget);
    expect(find.text('Desserts'), findsOneWidget);
    expect(find.text('Meringue'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text("What's the next meal?"), findsOneWidget);
  });

  Future<void> longPressFolderByName(WidgetTester tester, String name) async {
    final folder = find.text(name);
    await tester.ensureVisible(folder);
    await tester.pumpAndSettle();
    await tester.longPress(folder);
    await tester.pumpAndSettle();
  }

  testWidgets('Long press folder shows edit and delete actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Snacks');

    await longPressFolderByName(tester, 'Snacks');

    expect(find.text('Edit folder name'), findsOneWidget);
    expect(find.text('Delete folder'), findsOneWidget);
  });

  testWidgets('Rename folder updates name on grid', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Snacks');

    await longPressFolderByName(tester, 'Snacks');
    await tester.tap(find.text('Edit folder name'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Folder Name'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Snacks'),
      'Treats',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Treats'), findsOneWidget);
    expect(find.text('Snacks'), findsNothing);
  });

  testWidgets('Delete single folder removes it from grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Snacks');

    await longPressFolderByName(tester, 'Snacks');
    await tester.tap(find.text('Delete folder'));
    await tester.pumpAndSettle();

    expect(find.text('Delete forever?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Snacks'), findsNothing);
    expect(find.text('Recent recipes'), findsOneWidget);
  });

  testWidgets('Delete folder removes recipes from Recent and Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    // Back to Recipies grid
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await longPressFolderByName(tester, 'Desserts');
    await tester.tap(find.text('Delete folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Desserts'), findsNothing);

    // Open Recent recipes — Meringue should be gone
    final recent = find.byKey(const ValueKey('folder-recent'));
    await tester.ensureVisible(recent);
    await tester.pumpAndSettle();
    await tester.tap(recent);
    await tester.pumpAndSettle();

    expect(find.text('Meringue'), findsNothing);

    // Back to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text("What's the next meal?"), findsOneWidget);
    expect(find.text('Meringue'), findsNothing);
    expect(find.byType(RecipeCard), findsNothing);
  });

  testWidgets('Multi-select delete removes multiple folders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Snacks');
    await createFolder(tester, name: 'Mains');

    await longPressFolderByName(tester, 'Snacks');
    // Dismiss action sheet without choosing (tap outside / barrier)
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Mains'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Snacks'), findsNothing);
    expect(find.text('Mains'), findsNothing);
    expect(find.text('Recent recipes'), findsOneWidget);
  });

  testWidgets('Edit disabled when multiple folders selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);
    await createFolder(tester, name: 'Snacks');
    await createFolder(tester, name: 'Mains');

    await longPressFolderByName(tester, 'Snacks');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mains'));
    await tester.pumpAndSettle();

    final editButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.edit),
    );
    expect(editButton.onPressed, isNull);
  });

  testWidgets('Long press on Recent recipes does nothing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await openRecipesPage(tester);

    await longPressFolderByName(tester, 'Recent recipes');

    expect(find.text('Edit folder name'), findsNothing);
    expect(find.text('Delete folder'), findsNothing);
    expect(find.text('selected'), findsNothing);
  });

  testWidgets('Tap recipe in folder opens View Recipe', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.tap(find.text('Meringue'));
    await tester.pumpAndSettle();

    expect(find.text('View Recipe'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('Long press recipe shows Delete and Move actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.longPress(find.text('Meringue'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Move to folder'), findsOneWidget);
  });

  testWidgets('Delete recipe removes it from folder and Recent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.longPress(find.text('Meringue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Meringue'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    final recent = find.byKey(const ValueKey('folder-recent'));
    await tester.ensureVisible(recent);
    await tester.tap(recent);
    await tester.pumpAndSettle();

    expect(find.text('Meringue'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Meringue'), findsNothing);
  });

  testWidgets('Move recipe to another folder removes it from source', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await createFolder(tester, name: 'Snacks');
    await openFolderByName(tester, 'Desserts');

    await tester.longPress(find.text('Meringue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to folder'));
    await tester.pumpAndSettle();

    expect(find.text('Move to folder'), findsWidgets);
    await tester.tap(find.text('Snacks').last);
    await tester.pumpAndSettle();

    expect(find.text('Meringue'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await openFolderByName(tester, 'Snacks');

    expect(find.text('Meringue'), findsOneWidget);
  });

  testWidgets('Edit icon switches to Edit Recipe and save succeeds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.tap(find.text('Meringue'));
    await tester.pumpAndSettle();

    expect(find.text('View Recipe'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edit Recipe'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'French Meringue');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.text('View Recipe'), findsOneWidget);
    expect(find.text('French Meringue'), findsOneWidget);
  });

  testWidgets('Plan Week fills meal cells when recipes exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    expect(find.text('Plan Week'), findsOneWidget);
    // 7 days × 3 meals with a single recipe → Meringue in every cell
    expect(find.text('Meringue'), findsNWidgets(21));
  });

  testWidgets('Plan Month fills from today through end of month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await createMeringueInDesserts(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthLabel = 'Plan Month: ${monthNames[now.month - 1]}';
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = daysInMonth - now.day + 1;

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text(monthLabel).last);
    await tester.pumpAndSettle();

    expect(find.text(monthLabel), findsOneWidget);
    expect(find.text('M Meringue'), findsNWidgets(remainingDays));
    expect(find.text('N Meringue'), findsNWidgets(remainingDays));
    expect(find.text('Ni Meringue'), findsNWidgets(remainingDays));
  });

  testWidgets('Spin Add Criteria offers prep contains repeat but not folder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Spin Wheel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    expect(find.text('Add Criteria'), findsOneWidget);
    expect(find.text('Preparation time'), findsOneWidget);
    expect(find.text('Contains ingredient'), findsOneWidget);
    expect(find.text('Repeating recipe'), findsOneWidget);
    expect(find.text('By folder'), findsNothing);
  });

  testWidgets('Plan Week Add Criteria includes By folder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Plan week'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    expect(find.text('Add Criteria'), findsOneWidget);
    expect(find.text('By folder'), findsOneWidget);
    expect(find.text('Preparation time'), findsOneWidget);
    expect(find.text('Repeating recipe'), findsOneWidget);
  });

  testWidgets('Night Mode toggles background and text colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());

    expect(
      Theme.of(tester.element(find.byType(Scaffold).first))
          .scaffoldBackgroundColor,
      kBackground,
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsDialog), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(HomePage)));
    expect(theme.scaffoldBackgroundColor, kNightBackground);
    expect(theme.extension<NomNomTheme>()!.text, kNightText);
    expect(theme.extension<NomNomTheme>()!.background, kNightBackground);

    final title = tester.widget<Text>(find.text("What's the next meal?"));
    expect(title.style?.color, kNightText);
  });
}