import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'ls_seller_lang';
  String lang = 'hi';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString(_key) ?? 'hi';
    notifyListeners();
  }

  Future<void> toggle() async {
    lang = lang == 'hi' ? 'en' : 'hi';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
    notifyListeners();
  }
}
