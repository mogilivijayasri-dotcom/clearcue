import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../medicine_data.dart';

/// Opens the on-device SQLite database and creates the tables on first run.
class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'clearcue.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            aliases TEXT NOT NULL,
            purpose TEXT NOT NULL,
            warnings TEXT NOT NULL,
            side_effects TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE scans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mode TEXT NOT NULL,
            title TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE qa(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scan_id INTEGER NOT NULL,
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            evidence TEXT NOT NULL,
            found INTEGER NOT NULL,
            FOREIGN KEY(scan_id) REFERENCES scans(id)
          )''');

        // Seed the medicine table on first run
        final batch = db.batch();
        for (final m in medicineDb) {
          batch.insert('medicines', {
            'name': m.name,
            'aliases': m.aliases.join('|'),
            'purpose': m.purpose,
            'warnings': m.warnings,
            'side_effects': m.sideEffects,
          });
        }
        await batch.commit(noResult: true);
      },
    );
    return _db!;
  }
}
