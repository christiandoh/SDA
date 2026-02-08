import 'dart:ui';
import 'package:flutter/material.dart';

/// Durée d'affichage par défaut du snackbar (3 secondes).
const Duration kGlassSnackBarDuration = Duration(seconds: 3);

/// Durée de l'animation d'entrée (affichage lent).
const Duration kGlassSnackBarEnterDuration = Duration(milliseconds: 800);

/// Affiche un SnackBar style glassmorphism qui s'affiche lentement et reste 3 secondes.
void showGlassSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = kGlassSnackBarDuration,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _GlassSnackBarOverlay(
      message: message,
      duration: duration,
      onDismiss: () {
        entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

/// Overlay du snackbar glassmorphism avec animation lente.
class _GlassSnackBarOverlay extends StatefulWidget {
  const _GlassSnackBarOverlay({
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_GlassSnackBarOverlay> createState() => _GlassSnackBarOverlayState();
}

class _GlassSnackBarOverlayState extends State<_GlassSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kGlassSnackBarEnterDuration,
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_controller);
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_controller);

    _controller.forward();
    Future.delayed(widget.duration + kGlassSnackBarEnterDuration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom + 24;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
