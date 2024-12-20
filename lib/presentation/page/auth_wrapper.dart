import 'package:core/domain/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:group_expense_tracker/presentation/page/home/home_page.dart';
import 'package:group_expense_tracker/presentation/page/login/login_page.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return wrapper(context);
  }

  Widget wrapper(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    if (user == null) {
      return const LoginPage();
    } else {
      return const HomePage();
    }
  }
}
