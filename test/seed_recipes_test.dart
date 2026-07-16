import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/data/seed_recipes.dart';
import 'package:nomnom/models/recipe.dart';

void main() {
  group('parseSeedJson', () {
    const source = '''
{
  "folders": [
    {
      "id": "seed_folder_malaysian_cuisine",
      "name": "Malaysian Cuisine",
      "color": "#edd312"
    }
  ],
  "recipes": [
    {
      "id": "seed_recipe_nasi_lemak",
      "name": "Nasi Lemak",
      "folderId": "seed_folder_malaysian_cuisine",
      "preparationMinutes": 30,
      "timesOfDay": ["morning"],
      "daysOfWeek": [],
      "link": "https://nomadette.com/nasi-lemak/",
      "instructions": "Cook rice.\\n\\nMake sambal.",
      "ingredients": [
        { "quantity": 2, "unit": "cup", "name": "basmati rice" },
        { "quantity": 1.5, "unit": "cup", "name": "water" },
        { "quantity": 2, "unit": null, "name": "pandan" },
        { "quantity": 0.5, "unit": "tsp", "name": "salt" }
      ]
    }
  ]
}
''';

    test('maps folder color and recipe fields to model types', () {
      final createdAt = DateTime.utc(2026, 7, 16);
      final seed = parseSeedJson(source, createdAt: createdAt);

      expect(seed.folders, hasLength(1));
      final folder = seed.folders.single;
      expect(folder.id, 'seed_folder_malaysian_cuisine');
      expect(folder.name, 'Malaysian Cuisine');
      expect(folder.color, const Color(0xFFEDD312));

      expect(seed.recipes, hasLength(1));
      final recipe = seed.recipes.single;
      expect(recipe.id, 'seed_recipe_nasi_lemak');
      expect(recipe.name, 'Nasi Lemak');
      expect(recipe.folderId, 'seed_folder_malaysian_cuisine');
      expect(recipe.preparationMinutes, 30);
      expect(recipe.timesOfDay, [TimeOfDayOption.morning]);
      expect(recipe.daysOfWeek, isEmpty);
      expect(recipe.link, 'https://nomadette.com/nasi-lemak/');
      expect(recipe.instructions, 'Cook rice.\n\nMake sambal.');
      expect(recipe.createdAt, createdAt);

      expect(recipe.ingredients[0].quantity, 2);
      expect(recipe.ingredients[0].unit, IngredientUnit.cup);
      expect(recipe.ingredients[0].name, 'basmati rice');
      expect(recipe.ingredients[0].label, '2 cup basmati rice');

      expect(recipe.ingredients[1].quantity, 1.5);
      expect(recipe.ingredients[1].label, '1.5 cup water');

      expect(recipe.ingredients[2].unit, isNull);
      expect(recipe.ingredients[2].label, '2 pandan');

      expect(recipe.ingredients[3].quantity, 0.5);
      expect(recipe.ingredients[3].unit, IngredientUnit.tsp);
      expect(recipe.ingredients[3].label, '0.5 tsp salt');
    });

    test('parses bundled assets/seed/recipes.json', () {
      final file = File('assets/seed/recipes.json');
      expect(file.existsSync(), isTrue);

      final seed = parseSeedJson(file.readAsStringSync());
      expect(seed.folders.single.name, 'Malaysian Cuisine');
      expect(seed.folders.single.color, const Color(0xFFEDD312));
      expect(seed.recipes, hasLength(3));

      final nasiLemak = seed.recipes.firstWhere(
        (r) => r.id == 'seed_recipe_nasi_lemak',
      );
      expect(nasiLemak.name, 'Nasi Lemak');
      expect(nasiLemak.preparationMinutes, 30);
      expect(nasiLemak.timesOfDay, [TimeOfDayOption.morning]);
      expect(nasiLemak.daysOfWeek, isEmpty);
      expect(nasiLemak.link, 'https://nomadette.com/nasi-lemak/');
      expect(nasiLemak.ingredients, hasLength(13));
      expect(nasiLemak.ingredients[2].quantity, 1.5);
      expect(nasiLemak.ingredients[2].unit, IngredientUnit.cup);
      expect(nasiLemak.ingredients[3].unit, isNull);
      expect(nasiLemak.ingredients[6].quantity, 0.5);
      expect(nasiLemak.ingredients[10].unit, IngredientUnit.tbsp);

      final tosai = seed.recipes.firstWhere(
        (r) => r.id == 'seed_recipe_tosai',
      );
      expect(tosai.name, 'Tosai (Dosa)');
      expect(tosai.folderId, 'seed_folder_malaysian_cuisine');
      expect(tosai.preparationMinutes, 15);
      expect(tosai.timesOfDay, [
        TimeOfDayOption.morning,
        TimeOfDayOption.noon,
      ]);
      expect(tosai.daysOfWeek, isEmpty);
      expect(
        tosai.link,
        'https://www.indianhealthyrecipes.com/dosa-recipe-dosa-batter/',
      );
      expect(tosai.ingredients, hasLength(7));
      expect(tosai.ingredients[0].label, '3 cup raw rice');
      expect(tosai.ingredients[1].unit, IngredientUnit.cup);
      expect(tosai.ingredients[2].unit, IngredientUnit.tbsp);
      expect(tosai.ingredients[4].quantity, 800);
      expect(tosai.ingredients[4].unit, IngredientUnit.ml);
      expect(tosai.ingredients[6].unit, IngredientUnit.tsp);

      final watTanHor = seed.recipes.firstWhere(
        (r) => r.id == 'seed_recipe_wat_tan_hor',
      );
      expect(
        watTanHor.name,
        'Wat Tan Hor (Silky Egg Gravy Flat Noodles)',
      );
      expect(watTanHor.folderId, 'seed_folder_malaysian_cuisine');
      expect(watTanHor.preparationMinutes, 20);
      expect(watTanHor.timesOfDay, [
        TimeOfDayOption.noon,
        TimeOfDayOption.night,
      ]);
      expect(watTanHor.daysOfWeek, isEmpty);
      expect(
        watTanHor.link,
        'https://www.ajinomoto.com.my/recipes/wat-tan-hor-set',
      );
      expect(watTanHor.ingredients, hasLength(7));
      expect(watTanHor.ingredients[0].label, '400 g flat rice noodles');
      expect(watTanHor.ingredients[1].unit, IngredientUnit.g);
      expect(watTanHor.ingredients[2].unit, isNull);
      expect(watTanHor.ingredients[2].name, 'bok choy');
      expect(watTanHor.ingredients[5].unit, IngredientUnit.cup);
      expect(watTanHor.ingredients[6].unit, IngredientUnit.tbsp);
    });
  });

  group('Ingredient.formatQuantity', () {
    test('formats whole and fractional amounts', () {
      expect(Ingredient.formatQuantity(2), '2');
      expect(Ingredient.formatQuantity(1.5), '1.5');
      expect(Ingredient.formatQuantity(0.5), '0.5');
    });
  });
}
