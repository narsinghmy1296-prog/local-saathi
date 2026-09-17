import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'ls_lang';

  String lang = 'hi';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString(_key) ?? 'hi';
    AppStrings.lang = lang;
    notifyListeners();
  }

  Future<void> toggle() async {
    lang = lang == 'hi' ? 'en' : 'hi';
    AppStrings.lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
    notifyListeners();
  }
}
