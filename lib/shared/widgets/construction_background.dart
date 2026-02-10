import 'package:flutter/material.dart';

/// Shared construction-site background (photo + subtle EPI/accident icons).
class ConstructionBackground extends StatelessWidget {
  const ConstructionBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/chantier.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Large, soft EPI + accident icons as translucent watermarks.
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Icon(
                  Icons.report_problem_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ],
            ),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.08)),
        child,
      ],
    );
  }
}
