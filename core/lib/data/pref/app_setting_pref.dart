import 'package:shared_preferences/shared_preferences.dart';

class AppSettingPref {
  final SharedPreferences prefs;

  static const String incomePref = 'income_pref';

  AppSettingPref({required this.prefs});

  Future<bool> setIncome(int income) async {
    try {
      bool result = await prefs.setInt(incomePref, income);
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<int?> getIncome() async {
    try {
      int? result = prefs.getInt(incomePref);
      return result;
    } catch (e) {
      return null;
    }
  }
}
