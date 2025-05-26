import 'dart:async';

import 'package:core/data/pref/auth_pref.dart';
import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/user_model.dart';
import 'package:dartz/dartz.dart';
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

  Future<Either<Failure, bool>> register(String email, String password) async {
    try {
      final UserCredential credential =
          await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        bool isSuccess = await authPref.setUserDataModel(UserDataModel(
          uid: credential.user?.uid ?? '',
          email: credential.user?.email ?? '',
          name: credential.user?.displayName ?? '',
        ));

        return Right(isSuccess);
      }
      return const Left(GeneralFailure("credential user empty"));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  Future<Either<Failure, UserDataModel>> login(
      String email, String password) async {
    try {
      final UserCredential credential =
          await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final data = UserDataModel(
          uid: credential.user?.uid ?? '',
          email: credential.user?.email ?? '',
          name: credential.user?.displayName ?? '',
        );
        await authPref.setUserDataModel(data);
        return Right(data);
      }
      return const Left(GeneralFailure("credential user empty"));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  Future<Either<Failure, UserDataModel>> getUserDataModel() async =>
      authPref.getUserDataModel();

  Future<Either<Failure, bool>> setIsDarkMode(bool isDarkMode) async =>
      authPref.setIsDarkMode(isDarkMode);

  Future<Either<Failure, bool>> getIsDarkMode() async =>
      authPref.getIsDarkMode();
}
