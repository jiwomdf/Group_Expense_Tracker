import 'dart:convert';

import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/firebase_options_android_model.dart';
import 'package:core/domain/model/firebase_options_ios_model.dart';
import 'package:core/domain/model/firebase_options_web_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseOptionsPref {
  final SharedPreferences prefs;

  static const String foAndroidPref = 'fo_android_pref';
  static const String foIOSPref = 'fo_ios_pref';
  static const String foWebPref = 'fo_web_pref';

  FirebaseOptionsPref({required this.prefs});

  Future<bool> setFirebaseOptionsModelAndroid(
      FirebaseOptionsAndroidModel foModel) async {
    try {
      Map<String, dynamic> model = foModel.toJson();
      bool result = await prefs.setString(foAndroidPref, jsonEncode(model));
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<ResourceUtil<FirebaseOptionsAndroidModel>>
      getFirebaseOptionsModelAndroid() async {
    try {
      String result = prefs.getString(foAndroidPref) ?? '';
      Map<String, dynamic> model = jsonDecode(result);

      if (result.isEmpty) {
        return ResourceUtil.error(const GeneralFailure('user data not found'));
      } else {
        return ResourceUtil.success(FirebaseOptionsAndroidModel.fromMap(model));
      }
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<bool> setFirebaseOptionsModeliOS(
      FirebaseOptionsIOSModel foModel) async {
    try {
      Map<String, dynamic> model = foModel.toJson();
      bool result = await prefs.setString(foIOSPref, jsonEncode(model));
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<ResourceUtil<FirebaseOptionsIOSModel>>
      getFirebaseOptionsModeliOS() async {
    try {
      String result = prefs.getString(foIOSPref) ?? '';
      Map<String, dynamic> model = jsonDecode(result);

      if (result.isEmpty) {
        return ResourceUtil.error(const GeneralFailure('user data not found'));
      } else {
        return ResourceUtil.success(FirebaseOptionsIOSModel.fromMap(model));
      }
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<bool> setFirebaseOptionsModelWeb(
      FirebaseOptionsWebModel foModel) async {
    try {
      Map<String, dynamic> model = foModel.toJson();
      bool result = await prefs.setString(foWebPref, jsonEncode(model));
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<ResourceUtil<FirebaseOptionsWebModel>>
      getFirebaseOptionsModelWeb() async {
    try {
      String result = prefs.getString(foWebPref) ?? '';
      Map<String, dynamic> model = jsonDecode(result);

      if (result.isEmpty) {
        return ResourceUtil.error(const GeneralFailure('user data not found'));
      } else {
        return ResourceUtil.success(FirebaseOptionsWebModel.fromMap(model));
      }
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }
}
