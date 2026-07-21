import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nomnom/data/hive_boxes.dart';
import 'package:nomnom/models/recipe.dart';

class AppSettings extends ChangeNotifier {
  bool _nightMode = false;
  bool _showCost = false;
  bool _showCalorie = false;
  bool _showProtein = false;
  MeasurementSystem _measurementSystem = MeasurementSystem.metric;
  bool _loaded = false;

  bool get nightMode => _nightMode;
  bool get showCost => _showCost;
  bool get showCalorie => _showCalorie;
  bool get showProtein => _showProtein;
  MeasurementSystem get measurementSystem => _measurementSystem;
  bool get isLoaded => _loaded;

  bool get _hiveReady => Hive.isBoxOpen(HiveBoxes.meta);

  Future<void> load() async {
    if (!_hiveReady) {
      _loaded = true;
      notifyListeners();
      return;
    }

    final metaBox = HiveBoxes.metaBox;
    _nightMode =
        metaBox.get(HiveBoxes.metaNightMode, defaultValue: false) as bool;
    _showCost =
        metaBox.get(HiveBoxes.metaShowCost, defaultValue: false) as bool;
    _showCalorie =
        metaBox.get(HiveBoxes.metaShowCalorie, defaultValue: false) as bool;
    _showProtein =
        metaBox.get(HiveBoxes.metaShowProtein, defaultValue: false) as bool;
    final systemName = metaBox.get(
      HiveBoxes.metaMeasurementSystem,
      defaultValue: MeasurementSystem.metric.name,
    ) as String;
    _measurementSystem = MeasurementSystem.values.byName(systemName);

    _loaded = true;
    notifyListeners();
  }

  void setNightMode(bool value) {
    if (_nightMode == value) return;
    _nightMode = value;
    if (_hiveReady) {
      HiveBoxes.metaBox.put(HiveBoxes.metaNightMode, value);
    }
    notifyListeners();
  }

  void setShowCost(bool value) {
    if (_showCost == value) return;
    _showCost = value;
    if (_hiveReady) {
      HiveBoxes.metaBox.put(HiveBoxes.metaShowCost, value);
    }
    notifyListeners();
  }

  void setShowCalorie(bool value) {
    if (_showCalorie == value) return;
    _showCalorie = value;
    if (_hiveReady) {
      HiveBoxes.metaBox.put(HiveBoxes.metaShowCalorie, value);
    }
    notifyListeners();
  }

  void setShowProtein(bool value) {
    if (_showProtein == value) return;
    _showProtein = value;
    if (_hiveReady) {
      HiveBoxes.metaBox.put(HiveBoxes.metaShowProtein, value);
    }
    notifyListeners();
  }

  void setMeasurementSystem(MeasurementSystem value) {
    if (_measurementSystem == value) return;
    _measurementSystem = value;
    if (_hiveReady) {
      HiveBoxes.metaBox.put(HiveBoxes.metaMeasurementSystem, value.name);
    }
    notifyListeners();
  }

  void setCustomMeasuringSystem(bool enabled) {
    setMeasurementSystem(
      enabled ? MeasurementSystem.custom : MeasurementSystem.metric,
    );
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'No AppSettingsScope found in context');
    return scope!.notifier!;
  }
}
