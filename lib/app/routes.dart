import 'package:flutter/material.dart';
import '../data/models/epi_model.dart';
import '../data/models/incident_model.dart';
import '../features/login/login_page.dart';
import '../features/welcome/welcome_page.dart';
import '../features/main_shell/main_shell_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/stock/stock_page.dart';
import '../features/stock/stock_form_page.dart';
import '../features/incidents/incident_page.dart';
import '../features/incidents/incident_form_page.dart';
import '../features/settings/settings_page.dart';

/// Noms des routes de l'application.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String welcome = '/';
  static const String main = '/main';
  static const String dashboard = '/dashboard';
  static const String stock = '/stock';
  static const String stockForm = '/stock/form';
  static const String incident = '/incident';
  static const String incidentForm = '/incident/form';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginPage(),
    welcome: (context) => const WelcomePage(),
    main: (context) => const MainShellPage(),
    dashboard: (context) => const DashboardPage(),
    stock: (context) => const StockPage(),
    stockForm: (context) => const StockFormPage(),
    incident: (context) => const IncidentPage(),
    incidentForm: (context) => const IncidentFormPage(),
    settings: (context) => const SettingsPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final args = settings.arguments;

    final hasRoute =
        name == stockForm ||
        name == incidentForm ||
        name == login ||
        routes.containsKey(name);
    if (!hasRoute) return null;

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        if (name == login) {
          return const LoginPage();
        }
        if (name == stockForm) {
          return StockFormPage(epi: args is EpiModel? ? args : null);
        }
        if (name == incidentForm) {
          return IncidentFormPage(
            incident: args is IncidentModel? ? args : null,
          );
        }
        return routes[name]!(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var fadeTween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
