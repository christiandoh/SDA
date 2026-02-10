import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/models/epi_model.dart';
import '../../shared/widgets/glass_snackbar.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/repositories/epi_repository.dart';
import '../../data/repositories/stock_movement_repository.dart';

/// Formulaire EPI (création / édition) + entrée / sortie de stock.
class StockFormPage extends StatefulWidget {
  const StockFormPage({super.key, this.epi});

  /// Si non null, mode édition + mouvements.
  final EpiModel? epi;

  @override
  State<StockFormPage> createState() => _StockFormPageState();
}

class _StockFormPageState extends State<StockFormPage> {
  final EpiRepository _epiRepo = EpiRepository();
  final StockMovementRepository _movementRepo = StockMovementRepository();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _designationController;
  late TextEditingController _seuilMinController;
  late TextEditingController _quantiteInitialeController;
  late TextEditingController _movementQtyController;
  late TextEditingController _movementCommentController;

  bool _isEdit = false;
  int _currentStock = 0;
  MovementType _movementType = MovementType.entree;
  List<StockMovementModel> _movements = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.epi != null;
    _codeController = TextEditingController(text: widget.epi?.code ?? '');
    _designationController = TextEditingController(
      text: widget.epi?.designation ?? '',
    );
    _seuilMinController = TextEditingController(
      text: widget.epi?.seuilMin.toString() ?? '0',
    );
    _quantiteInitialeController = TextEditingController(text: '0');
    _movementQtyController = TextEditingController();
    _movementCommentController = TextEditingController();
    if (_isEdit && widget.epi?.id != null) {
      _loadStock();
    }
  }

  Future<void> _loadStock() async {
    if (widget.epi?.id == null) return;
    final s = await _epiRepo.getStockFromMovements(widget.epi!.id!);
    final moves = await _movementRepo.getByEpiId(widget.epi!.id!);
    setState(() {
      _currentStock = s;
      _movements = moves;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _designationController.dispose();
    _seuilMinController.dispose();
    _quantiteInitialeController.dispose();
    _movementQtyController.dispose();
    _movementCommentController.dispose();
    super.dispose();
  }

  Future<void> _saveEpi() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _codeController.text.trim();
    final designation = _designationController.text.trim();
    final seuilMin = int.tryParse(_seuilMinController.text.trim()) ?? 0;
    final now = DateTime.now().toIso8601String();

    if (_isEdit && widget.epi != null && widget.epi!.id != null) {
      await _epiRepo.update(
        widget.epi!.id!,
        code: code,
        designation: designation,
        seuilMin: seuilMin,
      );
      if (mounted)
        showGlassSnackBar(context, message: 'Modifications enregistrées');
    } else {
      final id = await _epiRepo.insert(
        EpiModel(
          code: code,
          designation: designation,
          stock: 0,
          seuilMin: seuilMin,
          dateCreation: now,
        ),
      );
      final qteInit =
          int.tryParse(_quantiteInitialeController.text.trim()) ?? 0;
      if (id > 0 && qteInit > 0) {
        await _movementRepo.insert(
          StockMovementModel(
            epiId: id,
            type: MovementType.entree,
            quantite: qteInit,
            date: now,
            commentaire: 'Quantité initiale',
          ),
        );
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _addMovement() async {
    final qty = int.tryParse(_movementQtyController.text.trim());
    if (widget.epi?.id == null || qty == null || qty <= 0) {
      showGlassSnackBar(context, message: 'Quantité invalide');
      return;
    }
    if (_movementType == MovementType.sortie && qty > _currentStock) {
      showGlassSnackBar(
        context,
        message: 'Quantité en sortie supérieure au stock actuel',
      );
      return;
    }
    await _movementRepo.insert(
      StockMovementModel(
        epiId: widget.epi!.id!,
        type: _movementType,
        quantite: qty,
        date: DateTime.now().toIso8601String(),
        commentaire: _movementCommentController.text.trim().isEmpty
            ? null
            : _movementCommentController.text.trim(),
      ),
    );
    _movementQtyController.clear();
    _movementCommentController.clear();
    await _loadStock();
    if (mounted) {
      showGlassSnackBar(context, message: 'Mouvement enregistré');
    }
  }

  Future<void> _deleteMovement(StockMovementModel m) async {
    if (widget.epi?.id == null || m.id == null) return;
    final theme = Theme.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.25),
          builder: (ctx) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.12),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Supprimer le mouvement ?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cette entrée/sortie sera définitivement supprimée et le stock sera recalculé.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error
                                    .withValues(alpha: 0.85),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
    if (!confirmed) return;

    await _movementRepo.delete(m.id!, widget.epi!.id!);
    await _loadStock();
    if (mounted) {
      showGlassSnackBar(context, message: 'Mouvement supprimé');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEdit ? 'Modifier l\'EPI' : 'Nouvel EPI'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code',
                hintText: 'Ex. EPI-CASQUE-01',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: const InputDecoration(
                labelText: 'Désignation',
                hintText: 'Casque, gants, gilet...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _seuilMinController,
              decoration: const InputDecoration(
                labelText: 'Seuil minimum (alerte)',
                hintText: '0 = pas d\'alerte',
              ),
              keyboardType: TextInputType.number,
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantiteInitialeController,
                decoration: const InputDecoration(
                  labelText: 'Quantité initiale (optionnel)',
                  hintText: '0 = vous ajouterez des entrées plus tard',
                  helperText:
                      'Stock de départ : sera enregistré comme une entrée.',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Text(
                'Historique des mouvements',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_movements.isEmpty)
                Text(
                  'Aucun mouvement enregistré pour cet EPI.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _movements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = _movements[index];
                    final isEntree = m.type == MovementType.entree;
                    final color = isEntree
                        ? Colors.green.shade600
                        : theme.colorScheme.error;
                    final sign = isEntree ? '+' : '-';
                    String dateLabel;
                    try {
                      final d = DateTime.parse(m.date);
                      dateLabel =
                          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                    } catch (_) {
                      dateLabel = m.date;
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isEntree
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 18,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$sign${m.quantite}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                if (m.commentaire != null &&
                                    m.commentaire!.isNotEmpty)
                                  Text(
                                    m.commentaire!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              size: 22,
                            ),
                            color: theme.colorScheme.error,
                            onPressed: () => _deleteMovement(m),
                            tooltip: 'Supprimer ce mouvement',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEpi,
                  child: const Text('Enregistrer l\'EPI'),
                ),
              ),
            ],
            if (_isEdit) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Stock actuel',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$_currentStock',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Mouvement de stock', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<MovementType>(
                segments: const [
                  ButtonSegment(
                    value: MovementType.entree,
                    icon: Icon(Icons.add_circle_rounded),
                    label: Text('Entrée'),
                  ),
                  ButtonSegment(
                    value: MovementType.sortie,
                    icon: Icon(Icons.remove_circle_rounded),
                    label: Text('Sortie'),
                  ),
                ],
                selected: {_movementType},
                onSelectionChanged: (s) =>
                    setState(() => _movementType = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _movementQtyController,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _movementCommentController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _addMovement,
                      child: const Text('Enregistrer le mouvement'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEpi,
                  child: const Text('Enregistrer les modifications'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
