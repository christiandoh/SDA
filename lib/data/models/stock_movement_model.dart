/// Type de mouvement : entrée ou sortie.
enum MovementType { entree, sortie }

/// Modèle mouvement de stock (entrée / sortie).
class StockMovementModel {
  final int? id;
  final int epiId;
  final MovementType type;
  final int quantite;
  final String date;
  final String? commentaire;

  const StockMovementModel({
    this.id,
    required this.epiId,
    required this.type,
    required this.quantite,
    required this.date,
    this.commentaire,
  });

  static const String typeEntree = 'entree';
  static const String typeSortie = 'sortie';

  String get typeRaw => type == MovementType.entree ? typeEntree : typeSortie;

  Map<String, Object?> toMap() => {
    'id': id,
    'epi_id': epiId,
    'type': typeRaw,
    'quantite': quantite,
    'date': date,
    'commentaire': commentaire,
  };

  static StockMovementModel fromMap(Map<String, Object?> map) {
    final t = map['type'] as String? ?? '';
    return StockMovementModel(
      id: map['id'] as int?,
      epiId: map['epi_id'] as int? ?? 0,
      type: t == typeSortie ? MovementType.sortie : MovementType.entree,
      quantite: map['quantite'] as int? ?? 0,
      date: map['date'] as String? ?? '',
      commentaire: map['commentaire'] as String?,
    );
  }
}
