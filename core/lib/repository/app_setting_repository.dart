import 'package:core/data/pref/app_setting_pref.dart';

class AppSettingRepository {
  final AppSettingPref _prefs;

  AppSettingRepository(this._prefs);

  Future<bool> updateIncome(int income) async {
    try {
      return _prefs.setIncome(income);
    } catch (e) {
      return false;
    }
  }

  Future<int?> getIncome() async {
    try {
      return _prefs.getIncome();
    } catch (e) {
      return null;
    }
  }
}
