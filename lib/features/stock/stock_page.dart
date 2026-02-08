import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/epi_model.dart';
import '../../data/repositories/epi_repository.dart';

/// Liste des EPI, stock (recalculé via mouvements), alertes seuil.
class StockPage extends StatefulWidget {
  const StockPage({super.key, this.showBackButton = true});

  /// Si false (ex. dans MainShellPage avec bottom nav), pas de bouton retour.
  final bool showBackButton;

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final EpiRepository _epiRepo = EpiRepository();
  final NotificationService _notif = NotificationService.instance;

  List<EpiModel> _epis = [];
  final Map<int, int> _stockByEpi = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final epis = await _epiRepo.getAll();
      final Map<int, int> stocks = {};
      for (final e in epis) {
        if (e.id != null) {
          stocks[e.id!] = await _epiRepo.getStockFromMovements(e.id!);
        }
      }
      setState(() {
        _epis = epis;
        _stockByEpi.clear();
        _stockByEpi.addAll(stocks);
        _loading = false;
      });
      for (final e in _epis) {
        if (e.id != null) {
          final s = _stockByEpi[e.id!] ?? 0;
          if (e.seuilMin > 0 && s <= e.seuilMin) {
            _notif.showStockAlert(e.designation, s);
          }
        }
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock EPI'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.stockForm);
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _epis.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 40,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucun EPI',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre premier équipement',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.stockForm);
                      _load();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter un EPI'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _epis.length,
                itemBuilder: (context, i) {
                  final epi = _epis[i];
                  final stock = epi.id != null
                      ? (_stockByEpi[epi.id!] ?? 0)
                      : epi.stock;
                  final critical = epi.seuilMin > 0 && stock <= epi.seuilMin;
                  final iconData = _iconForEpi(epi.designation);
                  final iconColor = critical
                      ? AppTheme.criticalColor
                      : theme.colorScheme.primary;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: critical
                            ? AppTheme.criticalColor.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.stockForm, arguments: epi);
                            _load();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    iconData,
                                    size: 24,
                                    color: iconColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        epi.designation,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (epi.code.isNotEmpty)
                                        Text(
                                          epi.code,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stock : $stock'
                                        '${epi.seuilMin > 0 ? ' (seuil min. ${epi.seuilMin})' : ''}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: critical
                                                  ? AppTheme.criticalColor
                                                  : null,
                                              fontWeight: critical
                                                  ? FontWeight.w600
                                                  : null,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (critical)
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.criticalColor,
                                    size: 24,
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  IconData _iconForEpi(String designation) {
    final d = designation.toLowerCase();
    if (d.contains('casque')) return Icons.construction_rounded;
    if (d.contains('gant')) return Icons.back_hand_rounded;
    if (d.contains('gilet')) return Icons.checkroom_rounded;
    if (d.contains('chaussure')) return Icons.directions_walk_rounded;
    if (d.contains('botte')) return Icons.directions_walk_rounded;
    return Icons.shield_rounded;
  }
}
