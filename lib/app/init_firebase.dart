// ignore_for_file: unnecessary_null_comparison

import 'package:core/data/pref/firebase_options_pref.dart';
import 'package:core/domain/model/firebase_options_android_model.dart';
import 'package:core/domain/model/firebase_options_ios_model.dart';
import 'package:core/domain/model/firebase_options_web_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:group_expense_tracker/util/platform_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> initFirebase() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  FirebaseOptionsPref firebaseOptionsPref = FirebaseOptionsPref(prefs: prefs);
  bool isAlreadyInit = false;

  if (PlatformUtil.isAndroid()) {
    final fAndroid = await firebaseOptionsPref.getFirebaseOptionsModelAndroid();

    switch (fAndroid.status) {
      case Status.success:
        if (fAndroid.data != null) {
          final nonNullValue = fAndroid.data as FirebaseOptionsAndroidModel;
          isAlreadyInit = await initAndroid(nonNullValue);
        }
        break;
      case Status.error:
        break;
    }
  } else if (PlatformUtil.isIOS()) {
    final fIos = await firebaseOptionsPref.getFirebaseOptionsModeliOS();

    switch (fIos.status) {
      case Status.success:
        if (fIos.data != null) {
          final nonNullValue = fIos.data as FirebaseOptionsIOSModel;
          isAlreadyInit = await initIos(nonNullValue);
        }
        break;
      case Status.error:
        break;
    }
  } else if (kIsWeb) {
    final fWeb = await firebaseOptionsPref.getFirebaseOptionsModelWeb();

    switch (fWeb.status) {
      case Status.success:
        if (fWeb.data != null) {
          final nonNullValue = fWeb.data as FirebaseOptionsWebModel;
          isAlreadyInit = await initWeb(nonNullValue);
        }
        break;
      case Status.error:
        break;
    }
  }

  return isAlreadyInit;
}

Future<bool> initIos(FirebaseOptionsIOSModel r) async {
  var result = await Firebase.initializeApp(
      name: r.fName,
      options: FirebaseOptions(
        apiKey: r.apiKey,
        appId: r.appId,
        messagingSenderId: r.messagingSenderId,
        projectId: r.projectId,
        storageBucket: r.storageBucket,
        iosBundleId: r.iosBundleId,
      ));

  return (result != null);
}

Future<bool> initAndroid(FirebaseOptionsAndroidModel r) async {
  var result = await Firebase.initializeApp(
      name: r.fName,
      options: FirebaseOptions(
        apiKey: r.apiKey,
        appId: r.appId,
        messagingSenderId: r.messagingSenderId,
        projectId: r.projectId,
        storageBucket: r.storageBucket,
      ));

  return (result != null);
}

Future<bool> initWeb(FirebaseOptionsWebModel r) async {
  var result = await Firebase.initializeApp(
      name: r.fName,
      options: FirebaseOptions(
        apiKey: r.apiKey,
        authDomain: r.authDomain,
        projectId: r.projectId,
        storageBucket: r.storageBucket,
        messagingSenderId: r.messagingSenderId,
        appId: r.appId,
        measurementId: r.measurementId,
      ));
  return (result != null);
}
