import 'package:core/data/pref/app_setting_pref.dart';
import 'package:core/data/pref/auth_pref.dart';
import 'package:core/util/poultry_registery.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

Future<void> init() async {
  try {
    PoultryRegistry.safeRegisterSingleton<FirebaseAuth>(FirebaseAuth.instance);
    PoultryRegistry.safeRegisterSingleton<AuthPref>(AuthPref(prefs: locator()));
    PoultryRegistry.safeRegisterSingleton<AppSettingPref>(
        AppSettingPref(prefs: locator()));
  } catch (e) {
    debugPrint(e.toString());
  }
}
