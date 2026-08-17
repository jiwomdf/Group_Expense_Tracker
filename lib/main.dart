import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:group_expense_tracker/app/apps/app_home.dart';
import 'package:group_expense_tracker/app/apps/app_setting.dart';
import 'package:group_expense_tracker/app/init_app_module.dart';
import 'package:group_expense_tracker/app/init_app_setting_module.dart';
import 'package:group_expense_tracker/app/init_firebase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional, the firebase options form simply stays empty when there is no
  // `.env` file bundled with the build, or when the file is empty.
  try {
    await dotenv.load(fileName: "assets/env/.env", isOptional: true);
  } catch (_) {
    dotenv.testLoad();
  }
  await initAppSettingModule();
  //FcmBackgroundHandler().init();

  runApp(Phoenix(
    child: Builder(builder: (context) {
      return initFirebaseFuture();
    }),
  ));
}

FutureBuilder<bool> initFirebaseFuture() {
  return FutureBuilder(
      future: initFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            return initAppModuleFuture();
          } else {
            return const AppSetting();
          }
        }
        return const SizedBox();
      });
}

FutureBuilder<void> initAppModuleFuture() {
  return FutureBuilder(
      future: initAppModule(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const AppHome();
        } else {
          return const SizedBox();
        }
      });
}
