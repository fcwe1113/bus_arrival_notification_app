import 'package:shared_preferences/shared_preferences.dart';

class LocaleSelectionService {
  static const _key = "enabled_locales";

  Future<List<String>> getEnabledLocales() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> setEnabledLocales(List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, codes);
  }

  Future<bool> hasCompletedSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }
}