import 'package:core/util/poultry_registery.dart';
import 'package:get_it/get_it.dart';
import 'package:group_expense_tracker/presentation/bloc/category/category_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/fcm/fcm_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/holidays/holiday_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/income/income_cubit.dart';
import 'package:group_expense_tracker/presentation/bloc/login/login_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/logout/logout_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/register/register_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/usermodel/userdatamodel_bloc.dart';

final locator = GetIt.instance;

Future<void> init() async {
  PoultryRegistry.safeRegisterFactory<LoginBloc>(() => LoginBloc(locator()));
  PoultryRegistry.safeRegisterFactory<RegisterBloc>(
      () => RegisterBloc(locator()));
  PoultryRegistry.safeRegisterSingleton<LogoutBloc>(LogoutBloc(locator()));
  PoultryRegistry.safeRegisterSingleton<UserDataModelBloc>(
      UserDataModelBloc(locator()));
  PoultryRegistry.safeRegisterSingleton<ExpenseBloc>(ExpenseBloc(locator()));
  PoultryRegistry.safeRegisterSingleton<CategoryBloc>(CategoryBloc(locator()));
  PoultryRegistry.safeRegisterSingleton<SubcategoryBloc>(
      SubcategoryBloc(locator()));
  PoultryRegistry.safeRegisterSingleton<FcmBloc>(FcmBloc(locator()));
  PoultryRegistry.safeRegisterFactory<HolidayBloc>(
      () => HolidayBloc(locator()));
  PoultryRegistry.safeRegisterFactory<IncomeCubit>(
      () => IncomeCubit(locator()));
}
