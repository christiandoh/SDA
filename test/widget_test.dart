// Tests unitaires et widgets pour l'application HSE Offline.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sda/app/app.dart';
import 'package:sda/app/routes.dart';
import 'package:sda/features/welcome/welcome_page.dart';
import 'package:sda/shared/widgets/glass_snackbar.dart';

void main() {
  group('Page de bienvenue', () {
    testWidgets('affiche le titre SOTASERV et le bouton Commencer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const WelcomePage()));

      expect(find.text('SOTASERV - CI SARL'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('page de connexion affiche 4 champs et code par défaut 0000', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('Entrez votre code à 4 chiffres'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4));
    });
  });

  group('Routes', () {
    testWidgets('route initiale affiche la page de connexion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      expect(find.text('Connexion'), findsOneWidget);
    });
  });

  group('Glass SnackBar (glassmorphisme)', () {
    testWidgets('showGlassSnackBar affiche le message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showGlassSnackBar(
                    context,
                    message: 'Message test glassmorphism',
                  ),
                  child: const Text('Afficher'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Afficher'));
      await tester.pump();
      await tester.pump(kGlassSnackBarEnterDuration);

      expect(find.text('Message test glassmorphism'), findsOneWidget);

      // Laisser le timer de fermeture s'achever pour éviter "Timer is still pending"
      await tester.pump(kGlassSnackBarDuration + kGlassSnackBarEnterDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('le snackbar glass contient une icône info', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showGlassSnackBar(context, message: 'Alerte'),
                  child: const Text('Afficher'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Afficher'));
      await tester.pump();
      await tester.pump(kGlassSnackBarEnterDuration);

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Alerte'), findsOneWidget);

      await tester.pump(kGlassSnackBarDuration + kGlassSnackBarEnterDuration);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'durée par défaut est 3 secondes (const kGlassSnackBarDuration)',
      (WidgetTester tester) async {
        expect(kGlassSnackBarDuration, const Duration(seconds: 3));
      },
    );

    testWidgets('animation d\'entrée lente (kGlassSnackBarEnterDuration)', (
      WidgetTester tester,
    ) async {
      expect(kGlassSnackBarEnterDuration, const Duration(milliseconds: 800));
    });
  });
}
