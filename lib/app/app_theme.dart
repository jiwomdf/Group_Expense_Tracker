import 'package:flutter/material.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';

final ThemeData defaultThemeData = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: AppColors.blue.bgDarkBlue,
  scaffoldBackgroundColor: AppColors.white.primary,
  cardColor: AppColors.purple.bgLightPurple,
  canvasColor: AppColors.purple.bgLightPurple,
  dialogTheme: DialogTheme(backgroundColor: AppColors.white.primary),
);

final ThemeData darkThemeData = ThemeData.dark(
  useMaterial3: true,
).copyWith(
  scaffoldBackgroundColor: AppColors.blue.bgDarkBlue,
  cardColor: AppColors.blue.bgCardDarkBlue,
  canvasColor: AppColors.blue.bgCardDarkBlue,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark, // <-- the only line added
    seedColor: AppColors.blue.bgDarkBlue,
  ),
  dialogTheme: DialogThemeData(backgroundColor: AppColors.blue.bgDarkBlue),
);
