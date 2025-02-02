import 'package:core/domain/model/expense_category_model.dart';
import 'package:flutter/material.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/expense_form_page.dart';
import 'package:group_expense_tracker/presentation/page/export_expense/export_expense_json_page.dart';
import 'package:group_expense_tracker/presentation/page/export_expense/export_expense_page.dart';
import 'package:group_expense_tracker/presentation/page/export_expense/export_expense_sheet_page.dart';
import 'package:group_expense_tracker/presentation/page/holiday/holiday_page.dart';
import 'package:group_expense_tracker/presentation/page/home/home_page.dart';
import 'package:group_expense_tracker/presentation/page/import_expense/import_expense_page.dart';
import 'package:group_expense_tracker/presentation/page/income/UpdateIncomePage.dart';
import 'package:group_expense_tracker/presentation/page/login/login_page.dart';
import 'package:group_expense_tracker/presentation/page/register/register_page.dart';
import 'package:group_expense_tracker/presentation/page/setting_firebase/setting_firebase_page.dart';
import 'package:group_expense_tracker/presentation/page/update_table/update_table_page.dart';

PageRoute router(RouteSettings settings) {
  switch (settings.name) {
    case LoginPage.routeName:
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case RegisterPage.routeName:
      return MaterialPageRoute(builder: (_) => const RegisterPage());
    case HomePage.routeName:
      return MaterialPageRoute(builder: (_) => const HomePage());
    case ImportExpensePage.routeName:
      return MaterialPageRoute(builder: (_) => const ImportExpensePage());
    case ExportExpensePage.routeName:
      return MaterialPageRoute(builder: (_) => const ExportExpensePage());
    case ExportExpenseJsonPage.routeName:
      return MaterialPageRoute(builder: (_) => const ExportExpenseJsonPage());
    case ExportExpenseSheetPage.routeName:
      return MaterialPageRoute(builder: (_) => const ExportExpenseSheetPage());
    case UpdateTablePage.routeName:
      return MaterialPageRoute(builder: (_) => const UpdateTablePage());
    case HolidayPage.routeName:
      return MaterialPageRoute(builder: (_) => const HolidayPage());
    case SettingFirebasePage.routeName:
      return MaterialPageRoute(builder: (_) => const HolidayPage());
    case UpdateIncomePage.routeName:
      return MaterialPageRoute(builder: (_) => const UpdateIncomePage());
    case ExpenseFormPage.routeName:
      return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => ExpenseFormPage(
              expenseCategory: settings.arguments as ExpenseCategoryModel?));
    default:
      return MaterialPageRoute(builder: (_) {
        return const Scaffold(body: Center(child: Text('Page not found :(')));
      });
  }
}
