import 'package:core/domain/model/user_model.dart';
import 'package:core/repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:group_expense_tracker/app/app_theme.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/presentation/bloc/category/category_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/fcm/fcm_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/logout/logout_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/usermodel/userdatamodel_bloc.dart';
import 'package:group_expense_tracker/presentation/page/auth_wrapper.dart';
import 'package:group_expense_tracker/router.dart';
import 'package:group_expense_tracker/util/app/route_observers.dart';
import 'package:provider/provider.dart';

class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => AppHomeState();

  static AppHomeState of(BuildContext context) =>
      context.findAncestorStateOfType<AppHomeState>()!;
}

class AppHomeState extends State<AppHome> {
  ThemeMode _themeMode = ThemeMode.light;
  final _getIt = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setSystemUIOverlayStyle(_themeMode == ThemeMode.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light);

    return StreamProvider<UserModel?>.value(
        value: _getIt<AuthRepository>().user,
        initialData: null,
        child: MultiProvider(
          providers: [
            BlocProvider(create: (_) => di.locator<UserDataModelBloc>()),
            BlocProvider(create: (_) => di.locator<ExpenseBloc>()),
            BlocProvider(create: (_) => di.locator<CategoryBloc>()),
            BlocProvider(create: (_) => di.locator<SubcategoryBloc>()),
            BlocProvider(create: (_) => di.locator<FcmBloc>()),
            BlocProvider(create: (_) => di.locator<LogoutBloc>()),
          ],
          child: initMaterialApp(_themeMode),
        ));
  }

  void changeTheme(ThemeMode themeMode) async {
    final isDarkMode = themeMode == ThemeMode.dark;
    await di.locator<AuthRepository>().setIsDarkMode(isDarkMode);
    setState(() {
      _themeMode = themeMode;
    });
  }

  Future<bool> getIsDarkMode() async {
    final isDarkMode = await di.locator<AuthRepository>().getIsDarkMode();
    return isDarkMode.fold((failure) {
      return false;
    }, (result) {
      return result;
    });
  }
}

initMaterialApp(ThemeMode themeMode) {
  return MaterialApp(
    onGenerateTitle: (BuildContext context) => S.of(context).appTitle,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      S.delegate
    ],
    supportedLocales: const [
      Locale('en'), // English
    ],
    theme: defaultThemeData,
    darkTheme: darkThemeData,
    themeMode: themeMode,
    home: const AuthWrapper(),
    navigatorObservers: [routeObserver],
    onGenerateRoute: (RouteSettings settings) => router(settings),
  );
}
