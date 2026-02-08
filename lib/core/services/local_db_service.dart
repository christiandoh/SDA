import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Service d'accès à la base SQLite locale (offline-first).
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  static const String _dbName = 'hse_offline.db';
  static const int _dbVersion = 1;
  Database? _db;

  Database? get db => _db;

  /// Initialise la base et crée les tables si nécessaire.
  Future<void> init() async {
    if (_db != null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final path = join(appDir.path, _dbName);
    _db = await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE epi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        designation TEXT,
        stock INTEGER,
        seuil_min INTEGER,
        date_creation TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_movement (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        epi_id INTEGER,
        type TEXT,
        quantite INTEGER,
        date TEXT,
        commentaire TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE incident (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        zone TEXT,
        type TEXT,
        gravite INTEGER,
        cause TEXT,
        action TEXT,
        responsable TEXT
      )
    ''');
  }

  /// Ferme la base (utile pour les tests ou arrêt propre).
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
