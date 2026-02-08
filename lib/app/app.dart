import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

/// Point d'entrée UI de l'application HSE.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOTASERV - CI SARL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
