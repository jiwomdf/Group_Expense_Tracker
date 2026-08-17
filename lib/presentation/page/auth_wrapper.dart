import 'package:core/domain/model/auth_state.dart';
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
    final authState = Provider.of<AuthState>(context);
    if (!authState.isResolved) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (authState.isAuthenticated) {
      return const HomePage();
    }
    return const LoginPage();
  }
}
