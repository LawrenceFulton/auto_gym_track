import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const String _unitKey = 'pref_unit';
  
  String _unit = 'kg';
  bool _isLoading = true;

  SettingsController({bool loadImmediately = true}) {
    if (!loadImmediately) {
      _isLoading = false;
    }
  }

  String get unit => _unit;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _unit = prefs.getString(_unitKey) ?? 'kg';
    } catch (e) {
      // In tests or if failing, default to kg
      _unit = 'kg';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUnit(String newUnit) async {
    if (newUnit != 'kg' && newUnit != 'lb') return;
    
    _unit = newUnit;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_unitKey, newUnit);
    } catch (e) {
      // Ignore if shared prefs not available (e.g. tests)
    }
    notifyListeners();
  }
}
