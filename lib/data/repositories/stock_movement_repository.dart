import '../../core/services/local_db_service.dart';
import '../models/stock_movement_model.dart';
import 'epi_repository.dart';

/// Repository des mouvements de stock. Recalcul du stock EPI après chaque mouvement.
class StockMovementRepository {
  final LocalDbService _db = LocalDbService.instance;
  final EpiRepository _epiRepo = EpiRepository();

  static const String _table = 'stock_movement';

  Future<int> insert(StockMovementModel m) async {
    final db = _db.db;
    if (db == null) return 0;
    final id = await db.insert(_table, m.toMap());
    await _epiRepo.syncStockFromMovements(m.epiId);
    return id;
  }

  Future<List<StockMovementModel>> getByEpiId(int epiId) async {
    final db = _db.db;
    if (db == null) return [];
    final list = await db.query(
      _table,
      where: 'epi_id = ?',
      whereArgs: [epiId],
      orderBy: 'date DESC, id DESC',
    );
    return list.map(StockMovementModel.fromMap).toList();
  }

  Future<List<StockMovementModel>> getAll() async {
    final db = _db.db;
    if (db == null) return [];
    final list = await db.query(_table, orderBy: 'date DESC, id DESC');
    return list.map(StockMovementModel.fromMap).toList();
  }
}
