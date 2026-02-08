import 'dart:ui';
import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';
import '../stock/stock_page.dart';
import '../incidents/incident_page.dart';
import '../notifications/notifications_page.dart';
import '../settings/settings_page.dart';
import '../../data/repositories/epi_repository.dart';

/// Shell principal avec barre de navigation en bas (Tableau de bord, Stock, Incidents, Alertes, Paramètres).
/// Style « liquid glass » : flou d’arrière-plan, reflets, gouttes translucides (sans package oc_liquid_glass).
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, this.initialIndex = 0});

  /// Onglet affiché au premier affichage (0 = Dashboard, 1 = Stock, 2 = Incidents, 3 = Alertes, 4 = Paramètres).
  final int initialIndex;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _currentIndex;
  int _criticalCount = 0;
  final EpiRepository _epiRepo = EpiRepository();

  void _onCriticalCountUpdated(int count) {
    if (_criticalCount != count) setState(() => _criticalCount = count);
  }

  Future<void> _loadCriticalCount() async {
    final critical = await _epiRepo.getCriticalEpis();
    if (mounted && _criticalCount != critical.length) {
      setState(() => _criticalCount = critical.length);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _loadCriticalCount();
  }

  static const _navItems = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Tableau de bord',
    ),
    (
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Stock',
    ),
    (
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_turned_in_rounded,
      label: 'Incidents',
    ),
    (
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Alertes',
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Paramètres',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      DashboardPage(
        onNavigateToStock: () => setState(() => _currentIndex = 1),
        onNavigateToIncident: () => setState(() => _currentIndex = 2),
      ),
      StockPage(
        showBackButton: false,
        onCriticalCountUpdated: _onCriticalCountUpdated,
      ),
      const IncidentPage(showBackButton: false),
      NotificationsPage(onCriticalCountUpdated: _onCriticalCountUpdated),
      const SettingsPage(showBackButton: false),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.75),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final selected = _currentIndex == i;
                    final isNotifications = i == 3;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _GlassNavDroplet(
                          icon: selected ? item.activeIcon : item.icon,
                          label: item.label,
                          selected: selected,
                          theme: theme,
                          onTap: () {
                            setState(() => _currentIndex = i);
                            if (isNotifications) _loadCriticalCount();
                          },
                          badgeCount: isNotifications ? _criticalCount : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une « goutte » style verre : fond translucide, léger reflet (light band), coins arrondis.
class _GlassNavDroplet extends StatelessWidget {
  const _GlassNavDroplet({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount != null && badgeCount! > 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.15),
          ],
          stops: const [0.0, 0.5],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 0,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: selected ? 26 : 24,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount! > 99 ? '99+' : '$badgeCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
