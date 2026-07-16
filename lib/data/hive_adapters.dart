import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nomnom/models/recipe.dart';
import 'package:nomnom/models/recipe_folder.dart';

class RecipeFolderAdapter extends TypeAdapter<RecipeFolder> {
  @override
  final int typeId = 0;

  @override
  RecipeFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeFolder(
      id: fields[0] as String,
      name: fields[1] as String,
      color: Color(fields[2] as int),
    );
  }

  @override
  void write(BinaryWriter writer, RecipeFolder obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color.toARGB32());
  }
}

class IngredientAdapter extends TypeAdapter<Ingredient> {
  @override
  final int typeId = 1;

  @override
  Ingredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final unitName = fields[1] as String?;
    return Ingredient(
      quantity: (fields[0] as num).toDouble(),
      unit: unitName == null
          ? null
          : IngredientUnit.values.byName(unitName),
      name: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Ingredient obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.quantity)
      ..writeByte(1)
      ..write(obj.unit?.name)
      ..writeByte(2)
      ..write(obj.name);
  }
}

class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 2;

  @override
  Recipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recipe(
      id: fields[0] as String,
      name: fields[1] as String,
      ingredients: (fields[2] as List).cast<Ingredient>(),
      preparationMinutes: fields[3] as int,
      timesOfDay: (fields[4] as List)
          .cast<String>()
          .map(TimeOfDayOption.values.byName)
          .toList(),
      folderId: fields[5] as String,
      daysOfWeek: (fields[6] as List)
          .cast<String>()
          .map(DayOfWeekOption.values.byName)
          .toList(),
      link: fields[7] as String? ?? '',
      instructions: fields[8] as String? ?? '',
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ingredients)
      ..writeByte(3)
      ..write(obj.preparationMinutes)
      ..writeByte(4)
      ..write(obj.timesOfDay.map((e) => e.name).toList())
      ..writeByte(5)
      ..write(obj.folderId)
      ..writeByte(6)
      ..write(obj.daysOfWeek.map((e) => e.name).toList())
      ..writeByte(7)
      ..write(obj.link)
      ..writeByte(8)
      ..write(obj.instructions)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
