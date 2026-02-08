import 'package:flutter/material.dart';

/// Carte avec animation optionnelle pour le dashboard HSE.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.color});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    return Material(
      color: color ?? theme.cardTheme.color,
      elevation: theme.cardTheme.elevation ?? 2,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
