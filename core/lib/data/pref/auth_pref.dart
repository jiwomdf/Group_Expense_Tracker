import 'dart:convert';

import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/user_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPref {
  final SharedPreferences prefs;

  static const String userPref = 'user_pref';
  static const String isDarkModePref = 'is_dark_mode_pref';

  AuthPref({required this.prefs});

  Future<bool> setUserDataModel(UserDataModel userDataModel) async {
    try {
      Map<String, dynamic> userMap = userDataModel.toJson();
      bool result = await prefs.setString(userPref, jsonEncode(userMap));
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<ResourceUtil<UserDataModel>> getUserDataModel() async {
    try {
      String result = prefs.getString(userPref) ?? '';
      Map<String, dynamic> userMap = jsonDecode(result);

      if (result.isEmpty) {
        return ResourceUtil.error(const GeneralFailure('user data not found'));
      } else {
        return ResourceUtil.success(UserDataModel.fromMap(userMap));
      }
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<ResourceUtil<bool>> setIsDarkMode(bool isDarkMode) async {
    try {
      bool result = await prefs.setBool(isDarkModePref, isDarkMode);
      return ResourceUtil.success(result);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<ResourceUtil<bool>> getIsDarkMode() async {
    try {
      bool result = prefs.getBool(isDarkModePref) ?? false;
      return ResourceUtil.success(result);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }
}
