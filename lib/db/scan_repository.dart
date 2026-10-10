import '../analyzer.dart';
import 'app_database.dart';

class ScanRecord {
  final int id;
  final String mode;
  final String title;
  final String text;
  final String createdAt;
  ScanRecord(this.id, this.mode, this.title, this.text, this.createdAt);
}

/// All reads and writes for scan history and saved questions.
class ScanRepository {
  static Future<int> insertScan(String mode, String title, String text) async {
    final db = await AppDatabase.instance;
    return db.insert('scans', {
      'mode': mode,
      'title': title,
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> insertQa(int scanId, String question, Answer a) async {
    final db = await AppDatabase.instance;
    await db.insert('qa', {
      'scan_id': scanId,
      'question': question,
      'answer': a.text,
      'evidence': a.evidence.join('\n'),
      'found': a.found ? 1 : 0,
    });
  }

  static Future<List<ScanRecord>> listScans() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('scans', orderBy: 'id DESC');
    return rows
        .map((r) => ScanRecord(
              r['id'] as int,
              r['mode'] as String,
              r['title'] as String,
              r['text'] as String,
              r['created_at'] as String,
            ))
        .toList();
  }

  static Future<List<Map<String, Object?>>> qaFor(int scanId) async {
    final db = await AppDatabase.instance;
    return db.query('qa',
        where: 'scan_id = ?', whereArgs: [scanId], orderBy: 'id DESC');
  }

  static Future<void> deleteScan(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('qa', where: 'scan_id = ?', whereArgs: [id]);
    await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    final db = await AppDatabase.instance;
    await db.delete('qa');
    await db.delete('scans');
  }
}
