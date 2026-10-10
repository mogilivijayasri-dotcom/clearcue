import '../medicine_data.dart';
import 'app_database.dart';

class MedicineRepository {
  static Future<List<MedicineInfo>> all() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('medicines', orderBy: 'name ASC');
    if (rows.isEmpty) return medicineDb;
    return rows
        .map((r) => MedicineInfo(
              r['name'] as String,
              (r['aliases'] as String).split('|'),
              r['purpose'] as String,
              r['warnings'] as String,
              r['side_effects'] as String,
            ))
        .toList();
  }
}
