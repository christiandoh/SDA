import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/models/epi_model.dart';
import '../../data/models/incident_model.dart';
import '../../data/repositories/epi_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../core/services/pin_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_logo.dart';

/// Dashboard style fintech : KPIs, courbe des incidents, camemberts.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.onNavigateToStock,
    this.onNavigateToIncident,
  });

  /// Si fourni (ex. depuis MainShellPage), un tap sur Stock change d'onglet au lieu de push.
  final VoidCallback? onNavigateToStock;

  /// Si fourni, un tap sur Incidents change d'onglet au lieu de push.
  final VoidCallback? onNavigateToIncident;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final EpiRepository _epiRepo = EpiRepository();
  final IncidentRepository _incidentRepo = IncidentRepository();
  final PinService _pinService = PinService.instance;

  List<EpiModel> _criticalEpis = [];
  List<IncidentModel> _incidents = [];
  String? _userName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final critical = await _epiRepo.getCriticalEpis();
      final incidents = await _incidentRepo.getAll();
      final userName = await _pinService.getUserName();
      setState(() {
        _criticalEpis = critical;
        _incidents = incidents;
        _userName = userName;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Compte des incidents par mois (6 derniers mois).
  Map<String, int> get _incidentsByMonth {
    final now = DateTime.now();
    final map = <String, int>{};
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      map['${d.year}-${d.month.toString().padLeft(2, '0')}'] = 0;
    }
    for (final inc in _incidents) {
      try {
        final date = DateTime.parse(inc.date);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (map.containsKey(key)) map[key] = map[key]! + 1;
      } catch (_) {}
    }
    return map;
  }

  /// Compte des incidents par gravité (1 à 5).
  Map<int, int> get _incidentsBySeverity {
    final map = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final inc in _incidents) {
      final g = inc.gravite.clamp(1, 5);
      map[g] = map[g]! + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(size: 40, borderRadius: BorderRadius.circular(10)),
                if (_userName != null && _userName!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _userName!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        leadingWidth: _userName != null && _userName!.isNotEmpty ? 180 : 56,
        title: const Text('Tableau de bord'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildKpiRow(theme),
                  const SizedBox(height: 20),
                  _buildLineChartCard(theme),
                  const SizedBox(height: 20),
                  _buildPieChartCard(theme),
                  const SizedBox(height: 20),
                  _buildQuickActions(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiRow(ThemeData theme) {
    final criticalCount = _criticalEpis.length;
    final incidentCount = _incidents.length;
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Stock critique',
            value: '$criticalCount',
            subtitle: criticalCount == 0 ? 'OK' : 'À réappro.',
            icon: Icons.warning_amber_rounded,
            color: criticalCount == 0
                ? AppTheme.okColor
                : AppTheme.criticalColor,
            onTap: () {
              if (widget.onNavigateToStock != null) {
                widget.onNavigateToStock!();
              } else {
                Navigator.of(context).pushNamed(AppRoutes.stock);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: 'Incidents',
            value: '$incidentCount',
            subtitle: 'Total',
            icon: Icons.assignment_rounded,
            color: theme.colorScheme.primary,
            onTap: () {
              if (widget.onNavigateToIncident != null) {
                widget.onNavigateToIncident!();
              } else {
                Navigator.of(context).pushNamed(AppRoutes.incident);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLineChartCard(ThemeData theme) {
    final byMonth = _incidentsByMonth;
    final keys = byMonth.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (var i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), byMonth[keys[i]]!.toDouble()));
    }
    final maxY = spots.isEmpty
        ? 5.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b).toDouble() + 1)
              .clamp(1.0, 100.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.show_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Incidents par mois',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'Aucune donnée sur les 6 derniers mois',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= 0 && i < keys.length) {
                                final k = keys[i];
                                final parts = k.split('-');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${parts[1]}/${parts[0].substring(2)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (keys.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, data, index) =>
                                FlDotCirclePainter(
                                  radius: 3,
                                  color: theme.colorScheme.primary,
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 400),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(ThemeData theme) {
    final bySev = _incidentsBySeverity;
    final total = bySev.values.fold<int>(0, (a, b) => a + b);
    final colors = [
      AppTheme.okColor,
      Colors.lightGreen,
      Colors.orange,
      Colors.deepOrange,
      theme.colorScheme.error,
    ];
    final sections = <PieChartSectionData>[];
    for (var g = 1; g <= 5; g++) {
      final count = bySev[g]!;
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: count.toString(),
            color: colors[g - 1],
            radius: 48,
            titleStyle: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.pie_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Répartition par gravité',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: total == 0
                    ? Center(
                        child: Text(
                          'Aucun',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 24,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                        duration: const Duration(milliseconds: 400),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(5, (i) {
                    final g = i + 1;
                    final count = bySev[g]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gravité $g',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$count',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.stock),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock EPI',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Gérer le stock',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            onTap: () {
              if (widget.onNavigateToIncident != null) {
                widget.onNavigateToIncident!();
              } else {
                Navigator.of(context).pushNamed(AppRoutes.incident);
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.report_problem_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incident',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Déclarer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
