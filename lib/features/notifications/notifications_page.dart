import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/epi_model.dart';
import '../../data/repositories/epi_repository.dart';

/// Page listant les alertes stock critique (EPI dont le stock ≤ seuil min).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.onCriticalCountUpdated});

  /// Appelé avec le nombre d'EPI en stock critique (pour le badge de la navbar).
  final void Function(int count)? onCriticalCountUpdated;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final EpiRepository _epiRepo = EpiRepository();
  List<EpiModel> _criticalEpis = [];
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
      setState(() {
        _criticalEpis = critical;
        _loading = false;
      });
      widget.onCriticalCountUpdated?.call(critical.length);
    } catch (_) {
      setState(() => _loading = false);
      widget.onCriticalCountUpdated?.call(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes'), leading: null),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _criticalEpis.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune alerte',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun stock en dessous du seuil minimum',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _criticalEpis.length,
                itemBuilder: (context, i) {
                  final epi = _criticalEpis[i];
                  final stock = epi.stock;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppTheme.criticalColor.withValues(alpha: 0.08),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.criticalColor.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.criticalColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        epi.designation,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Stock : $stock (seuil min. ${epi.seuilMin}) — À réapprovisionner',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.criticalColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
