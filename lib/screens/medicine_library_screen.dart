import 'package:flutter/material.dart';
import '../analyzer.dart';
import '../medicine_data.dart';

class MedicineLibraryScreen extends StatefulWidget {
  const MedicineLibraryScreen({super.key});

  @override
  State<MedicineLibraryScreen> createState() => _MedicineLibraryScreenState();
}

class _MedicineLibraryScreenState extends State<MedicineLibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase().trim();
    final List<MedicineInfo> list = Analyzer.medicines.where((m) {
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.aliases.any((a) => a.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Library'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search by name or brand (e.g. Dolo)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No medicine found in the database.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final m = list[i];
                      return Card(
                        child: ExpansionTile(
                          title: Text(m.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Also known as: ${m.aliases.join(', ')}'),
                          childrenPadding: const EdgeInsets.all(14),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Purpose: ${m.purpose}'),
                            const SizedBox(height: 8),
                            Text('Warnings: ${m.warnings}'),
                            const SizedBox(height: 8),
                            Text('Possible side effects: ${m.sideEffects}'),
                            const SizedBox(height: 8),
                            const Text(
                              'Dosage is not provided. Ask a doctor or pharmacist.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
