import 'package:nomnom/models/recipe.dart';

sealed class PlanCriterion {
  String get label;

  bool matches(Recipe recipe);
}

class PrepTimeRangeCriterion extends PlanCriterion {
  PrepTimeRangeCriterion({
    required this.minMinutes,
    required this.maxMinutes,
  });

  final int minMinutes;
  final int maxMinutes;

  @override
  String get label {
    if (minMinutes <= 0) {
      return 'Preparation: under $maxMinutes min';
    }
    return 'Preparation: $minMinutes–$maxMinutes min';
  }

  @override
  bool matches(Recipe recipe) {
    final prep = recipe.preparationMinutes;
    if (minMinutes <= 0) {
      return prep <= maxMinutes;
    }
    return prep >= minMinutes && prep <= maxMinutes;
  }
}

class ContainsIngredientsCriterion extends PlanCriterion {
  ContainsIngredientsCriterion(this.ingredients);

  final List<String> ingredients;

  @override
  String get label => 'Contains: ${ingredients.join(', ')}';

  @override
  bool matches(Recipe recipe) {
    if (ingredients.isEmpty) return true;
    final names =
        recipe.ingredients.map((i) => i.name.toLowerCase()).toList();
    return ingredients.every((needed) {
      final query = needed.toLowerCase();
      return names.any((n) => n.contains(query));
    });
  }
}

class FolderCriterion extends PlanCriterion {
  FolderCriterion({
    required this.folderIds,
    required this.folderNames,
  });

  final Set<String> folderIds;
  final List<String> folderNames;

  @override
  String get label => 'Folders: ${folderNames.join(', ')}';

  @override
  bool matches(Recipe recipe) => folderIds.contains(recipe.folderId);
}

class RepeatRecipeCriterion extends PlanCriterion {
  RepeatRecipeCriterion({
    required this.recipeId,
    required this.recipeName,
    required this.times,
  });

  final String recipeId;
  final String recipeName;

  /// 0 = exclude from pool; 1–7 = place exactly that many times in plan.
  final int times;

  @override
  String get label => times == 0
      ? 'Exclude: $recipeName'
      : 'Repeat: $recipeName × $times';

  @override
  bool matches(Recipe recipe) {
    if (times == 0) return recipe.id != recipeId;
    return true;
  }
}

List<Recipe> filterRecipesByCriteria(
  List<Recipe> recipes,
  List<PlanCriterion> criteria,
) {
  var result = List<Recipe>.of(recipes);
  for (final criterion in criteria) {
    result = result.where(criterion.matches).toList();
  }
  return result;
}
