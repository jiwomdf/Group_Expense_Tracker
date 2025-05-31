import 'dart:async';

import 'package:core/data/pref/auth_pref.dart';
import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/user_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth firebaseAuth;
  final AuthPref authPref;

  AuthRepository({required this.firebaseAuth, required this.authPref});

  Stream<UserModel?> get user {
    return firebaseAuth.authStateChanges().map((User? user) {
      return user != null ? UserModel(uid: user.uid) : null;
    });
  }

  Future<ResourceUtil<bool>> register(String email, String password) async {
    try {
      final UserCredential credential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user == null) {
        return ResourceUtil.error(
            const GeneralFailure("credential user empty"));
      }

      bool isSuccess = await authPref.setUserDataModel(UserDataModel(
        uid: credential.user?.uid ?? '',
        email: credential.user?.email ?? '',
        name: credential.user?.displayName ?? '',
      ));

      return ResourceUtil.success(isSuccess);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<ResourceUtil<UserDataModel>> login(
      String email, String password) async {
    try {
      final UserCredential credential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        final data = UserDataModel(
          uid: credential.user?.uid ?? '',
          email: credential.user?.email ?? '',
          name: credential.user?.displayName ?? '',
        );
        await authPref.setUserDataModel(data);
        return ResourceUtil.success(data);
      }
      return ResourceUtil.error(const GeneralFailure("credential user empty"));
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  Future<ResourceUtil<UserDataModel>> getUserDataModel() async =>
      authPref.getUserDataModel();

  Future<ResourceUtil<bool>> setIsDarkMode(bool isDarkMode) async =>
      authPref.setIsDarkMode(isDarkMode);

  Future<ResourceUtil<bool>> getIsDarkMode() async => authPref.getIsDarkMode();
}
