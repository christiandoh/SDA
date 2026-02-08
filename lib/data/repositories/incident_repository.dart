import '../../core/services/local_db_service.dart';
import '../models/incident_model.dart';

/// Repository des accidents / incidents.
class IncidentRepository {
  final LocalDbService _db = LocalDbService.instance;

  static const String _table = 'incident';

  Future<List<IncidentModel>> getAll() async {
    final db = _db.db;
    if (db == null) return [];
    final list = await db.query(_table, orderBy: 'date DESC, id DESC');
    return list.map(IncidentModel.fromMap).toList();
  }

  Future<IncidentModel?> getById(int id) async {
    final db = _db.db;
    if (db == null) return null;
    final list = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (list.isEmpty) return null;
    return IncidentModel.fromMap(list.first);
  }

  Future<int> insert(IncidentModel incident) async {
    final db = _db.db;
    if (db == null) return 0;
    return db.insert(_table, incident.toMap());
  }

  Future<int> update(IncidentModel incident) async {
    if (incident.id == null) return 0;
    final db = _db.db;
    if (db == null) return 0;
    return db.update(
      _table,
      incident.toMap(),
      where: 'id = ?',
      whereArgs: [incident.id],
    );
  }

  Future<int> delete(int id) async {
    final db = _db.db;
    if (db == null) return 0;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = _db.db;
    if (db == null) return 0;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM $_table');
    return r.first['c'] as int? ?? 0;
  }
}
