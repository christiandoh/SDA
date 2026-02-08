import '../../core/services/local_db_service.dart';
import '../models/epi_model.dart';
import '../models/stock_movement_model.dart';

/// Repository EPI : CRUD et dénombrement stock critique.
/// Le stock affiché est recalculé à partir des mouvements (stock_movement).
class EpiRepository {
  final LocalDbService _db = LocalDbService.instance;

  static const String _table = 'epi';

  Future<List<EpiModel>> getAll() async {
    final db = _db.db;
    if (db == null) return [];
    final list = await db.query(_table, orderBy: 'designation');
    return list.map(EpiModel.fromMap).toList();
  }

  Future<EpiModel?> getById(int id) async {
    final db = _db.db;
    if (db == null) return null;
    final list = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (list.isEmpty) return null;
    return EpiModel.fromMap(list.first);
  }

  /// Stock actuel = somme(entrées) - somme(sorties) pour cet EPI.
  Future<int> getStockFromMovements(int epiId) async {
    final db = _db.db;
    if (db == null) return 0;
    final rows = await db.query(
      'stock_movement',
      columns: ['type', 'quantite'],
      where: 'epi_id = ?',
      whereArgs: [epiId],
    );
    int stock = 0;
    for (final row in rows) {
      final type = row['type'] as String?;
      final qty = row['quantite'] as int? ?? 0;
      if (type == StockMovementModel.typeEntree) {
        stock += qty;
      } else {
        stock -= qty;
      }
    }
    return stock;
  }

  /// Met à jour la colonne stock de l'EPI pour cohérence affichage (recalculée côté repo quand besoin).
  Future<void> _updateStockColumn(int epiId, int newStock) async {
    final db = _db.db;
    if (db == null) return;
    await db.update(
      _table,
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [epiId],
    );
  }

  Future<int> insert(EpiModel epi) async {
    final db = _db.db;
    if (db == null) return 0;
    return db.insert(_table, epi.toMap());
  }

  /// Met à jour un EPI existant (seules les colonnes modifiables sont écrites).
  Future<int> update(
    int id, {
    required String code,
    required String designation,
    required int seuilMin,
  }) async {
    final db = _db.db;
    if (db == null) return 0;
    final updated = await db.update(
      _table,
      {
        'code': code.isEmpty ? null : code,
        'designation': designation,
        'seuil_min': seuilMin,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated;
  }

  /// Met à jour un EPI à partir du modèle (pour compatibilité).
  Future<int> updateFromModel(EpiModel epi) async {
    if (epi.id == null) return 0;
    return update(
      epi.id!,
      code: epi.code,
      designation: epi.designation,
      seuilMin: epi.seuilMin,
    );
  }

  Future<int> delete(int id) async {
    final db = _db.db;
    if (db == null) return 0;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Liste des EPI dont le stock (calculé via mouvements) est <= seuil_min.
  Future<List<EpiModel>> getCriticalEpis() async {
    final all = await getAll();
    final critical = <EpiModel>[];
    for (final epi in all) {
      if (epi.id == null) continue;
      final stock = await getStockFromMovements(epi.id!);
      if (epi.seuilMin > 0 && stock <= epi.seuilMin) {
        critical.add(epi.copyWith(stock: stock));
      }
    }
    return critical;
  }

  /// Synchronise la colonne stock avec la somme des mouvements (utile après ajout mouvement).
  Future<void> syncStockFromMovements(int epiId) async {
    final stock = await getStockFromMovements(epiId);
    await _updateStockColumn(epiId, stock);
  }
}
