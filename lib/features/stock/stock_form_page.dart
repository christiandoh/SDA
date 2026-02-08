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
  late TextEditingController _movementQtyController;
  late TextEditingController _movementCommentController;

  bool _isEdit = false;
  int _currentStock = 0;
  MovementType _movementType = MovementType.entree;

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
    _movementQtyController = TextEditingController();
    _movementCommentController = TextEditingController();
    if (_isEdit && widget.epi?.id != null) {
      _loadStock();
    }
  }

  Future<void> _loadStock() async {
    if (widget.epi?.id == null) return;
    final s = await _epiRepo.getStockFromMovements(widget.epi!.id!);
    setState(() => _currentStock = s);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _designationController.dispose();
    _seuilMinController.dispose();
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

    if (_isEdit && widget.epi != null) {
      final updated = widget.epi!.copyWith(
        code: code.isEmpty ? null : code,
        designation: designation,
        seuilMin: seuilMin,
      );
      await _epiRepo.update(updated);
    } else {
      await _epiRepo.insert(
        EpiModel(
          code: code,
          designation: designation,
          stock: 0,
          seuilMin: seuilMin,
          dateCreation: now,
        ),
      );
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
    setState(() {});
    if (mounted) {
      showGlassSnackBar(context, message: 'Mouvement enregistré');
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
