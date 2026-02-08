/// Modèle accident / incident de travail.
class IncidentModel {
  final int? id;
  final String date;
  final String zone;
  final String type;
  final int gravite; // 1 à 5
  final String cause;
  final String action;
  final String responsable;

  const IncidentModel({
    this.id,
    required this.date,
    required this.zone,
    required this.type,
    required this.gravite,
    required this.cause,
    required this.action,
    required this.responsable,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'date': date,
    'zone': zone,
    'type': type,
    'gravite': gravite,
    'cause': cause,
    'action': action,
    'responsable': responsable,
  };

  static IncidentModel fromMap(Map<String, Object?> map) {
    return IncidentModel(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      zone: map['zone'] as String? ?? '',
      type: map['type'] as String? ?? '',
      gravite: map['gravite'] as int? ?? 1,
      cause: map['cause'] as String? ?? '',
      action: map['action'] as String? ?? '',
      responsable: map['responsable'] as String? ?? '',
    );
  }
}
