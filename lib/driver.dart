import 'Screens/login_view.dart';
import 'Screens/home_view.dart';
import 'package:flutter/material.dart';
import 'authenticate.dart';

class AppDriver extends StatelessWidget {
  AppDriver({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Authenticate().authorizedUser() == null
        ? const LoginPage()
        : HomePage();
  }
}
