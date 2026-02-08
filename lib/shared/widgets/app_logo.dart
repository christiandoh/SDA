import 'package:flutter/material.dart';

/// Logo SOTASERV - CI SARL avec bordures arrondies.
/// Utilisable dans l'AppBar (leading) ou en plein écran.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.borderRadius});

  /// Taille du logo (carré).
  final double size;

  /// Rayon des bords arrondis. Par défaut size / 4.
  final BorderRadius? borderRadius;

  static const String _assetPath = 'assets/logo.jpeg';

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 4);
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.business,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
