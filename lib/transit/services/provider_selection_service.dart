import 'package:shared_preferences/shared_preferences.dart';

class ProviderSelectionService {
  static const _key = "enabled_provider_codes";

  Future<List<String>> getEnabledProviderCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> setEnabledProviderCodes(List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, codes);
  }

  Future<bool> hasCompletedSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }
}