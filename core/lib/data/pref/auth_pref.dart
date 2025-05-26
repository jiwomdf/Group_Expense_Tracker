import 'dart:convert';

import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/user_model.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPref {
  final SharedPreferences prefs;

  static const String userPref = 'user_pref';

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

  Future<Either<Failure, UserDataModel>> getUserDataModel() async {
    try {
      String result = prefs.getString(userPref) ?? '';
      Map<String, dynamic> userMap = jsonDecode(result);

      if (result.isEmpty) {
        return const Left(GeneralFailure('user data not found'));
      } else {
        return Right(UserDataModel.fromMap(userMap));
      }
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> setIsDarkMode(bool isDarkMode) async {
    try {
      bool result = await prefs.setBool(userPref, isDarkMode);
      return Right(result);
    } catch (e) {
      //TODO JIWO
      print("eee + ${e.toString()}");
      return Left(GeneralFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> getIsDarkMode() async {
    try {
      bool result = prefs.getBool(userPref) ?? false;
      return Right(result);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }
}
