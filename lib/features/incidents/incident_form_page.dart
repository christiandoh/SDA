import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/widgets/glass_snackbar.dart';
import '../../data/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';

/// Formulaire de déclaration d'un accident / incident (gravité 1 à 5).
class IncidentFormPage extends StatefulWidget {
  const IncidentFormPage({super.key, this.incident});

  /// Si non null, mode édition.
  final IncidentModel? incident;

  @override
  State<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends State<IncidentFormPage> {
  final IncidentRepository _repo = IncidentRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _zoneController;
  late TextEditingController _typeController;
  late TextEditingController _causeController;
  late TextEditingController _actionController;
  late TextEditingController _responsableController;
  int _gravite = 1;

  @override
  void initState() {
    super.initState();
    final inc = widget.incident;
    _dateController = TextEditingController(
      text: inc?.date != null && inc!.date.isNotEmpty
          ? _toDisplayDate(inc.date)
          : _toDisplayDate(DateTime.now().toIso8601String()),
    );
    _zoneController = TextEditingController(text: inc?.zone ?? '');
    _typeController = TextEditingController(text: inc?.type ?? '');
    _causeController = TextEditingController(text: inc?.cause ?? '');
    _actionController = TextEditingController(text: inc?.action ?? '');
    _responsableController = TextEditingController(
      text: inc?.responsable ?? '',
    );
    _gravite = inc?.gravite ?? 1;
  }

  String _toDisplayDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _toIsoDate(String display) {
    final parts = display.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d).toIso8601String();
      }
    }
    return DateTime.now().toIso8601String();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _zoneController.dispose();
    _typeController.dispose();
    _causeController.dispose();
    _actionController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final date = _toIsoDate(_dateController.text.trim());
    final incident = IncidentModel(
      id: widget.incident?.id,
      date: date,
      zone: _zoneController.text.trim(),
      type: _typeController.text.trim(),
      gravite: _gravite,
      cause: _causeController.text.trim(),
      action: _actionController.text.trim(),
      responsable: _responsableController.text.trim(),
    );
    if (incident.id != null) {
      await _repo.update(incident);
    } else {
      await _repo.insert(incident);
    }
    if (mounted) {
      showGlassSnackBar(context, message: 'Incident enregistré');
      Navigator.of(context).pop(true);
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
        title: Text(
          widget.incident != null ? 'Modifier l\'incident' : 'Nouvel incident',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                hintText: 'JJ/MM/AAAA',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'Zone',
                hintText: 'Lieu de l\'incident',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Type',
                hintText: 'Accident, incident, quasi-accident...',
              ),
            ),
            const SizedBox(height: 16),
            Text('Gravité (1 à 5)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final g = i + 1;
                final selected = _gravite == g;
                final color = AppTheme.severityColor(g);
                return ChoiceChip(
                  label: Text('$g'),
                  selected: selected,
                  onSelected: (_) => setState(() => _gravite = g),
                  selectedColor: color.withOpacity(0.3),
                  side: BorderSide(
                    color: selected ? color : theme.dividerColor,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _causeController,
              decoration: const InputDecoration(
                labelText: 'Cause',
                hintText: 'Description des causes',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actionController,
              decoration: const InputDecoration(
                labelText: 'Action corrective',
                hintText: 'Mesures prises ou prévues',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _responsableController,
              decoration: const InputDecoration(
                labelText: 'Responsable',
                hintText: 'Nom du responsable',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
