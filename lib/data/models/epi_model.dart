/// Modèle EPI (Équipement de Protection Individuelle).
class EpiModel {
  final int? id;
  final String code;
  final String designation;

  /// Quantité en stock (nombre d'unités). En base, peut être 0 ; la quantité affichée est souvent recalculée à partir des mouvements (entrées/sorties).
  final int stock;
  final int seuilMin;
  final String dateCreation;

  const EpiModel({
    this.id,
    required this.code,
    required this.designation,
    required this.stock,
    required this.seuilMin,
    required this.dateCreation,
  });

  /// Alias pour [stock] : quantité d'unités en stock.
  int get quantity => stock;

  bool get isCritical => seuilMin > 0 && stock <= seuilMin;

  Map<String, Object?> toMap() => {
    'id': id,
    'code': code,
    'designation': designation,
    'stock': stock,
    'seuil_min': seuilMin,
    'date_creation': dateCreation,
  };

  static EpiModel fromMap(Map<String, Object?> map) {
    return EpiModel(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      stock: map['stock'] as int? ?? 0,
      seuilMin: map['seuil_min'] as int? ?? 0,
      dateCreation: map['date_creation'] as String? ?? '',
    );
  }

  EpiModel copyWith({
    int? id,
    String? code,
    String? designation,
    int? stock,
    int? seuilMin,
    String? dateCreation,
  }) {
    return EpiModel(
      id: id ?? this.id,
      code: code ?? this.code,
      designation: designation ?? this.designation,
      stock: stock ?? this.stock,
      seuilMin: seuilMin ?? this.seuilMin,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
