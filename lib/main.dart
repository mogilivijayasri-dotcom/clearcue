import 'package:flutter/material.dart';
import 'analyzer.dart';
import 'db/medicine_repository.dart';
import 'scan_screen.dart';
import 'screens/history_screen.dart';
import 'screens/medicine_library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Load medicine data from the SQLite database
    Analyzer.medicines = await MedicineRepository.all();
  } catch (_) {
    // If the database fails, the built-in list is used.
  }
  runApp(const ClearCueApp());
}

class ClearCueApp extends StatelessWidget {
  const ClearCueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearCue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _card(BuildContext context, String title, String subtitle,
      IconData icon, Widget Function() page) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal.shade50,
          child: Icon(icon, color: Colors.teal, size: 26),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClearCue'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Understand Before You Act',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Scan it, ask a question, and understand it simply.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          _card(context, 'Document / Notice',
              'Scholarships, forms, public notices', Icons.description,
              () => const ScanScreen(mode: 'doc', title: 'Document / Notice')),
          _card(context, 'Bill Analysis', 'Electricity and other bills',
              Icons.receipt_long,
              () => const ScanScreen(mode: 'bill', title: 'Bill Analysis')),
          _card(context, 'Medicine Scanner',
              'Information printed on a strip or box', Icons.medication,
              () => const ScanScreen(mode: 'medicine', title: 'Medicine Scanner')),
          _card(context, 'Medicine Library', 'Search medicines in the database',
              Icons.local_pharmacy, () => const MedicineLibraryScreen()),
          _card(context, 'Scan History', 'Your saved scans and answers',
              Icons.history, () => const HistoryScreen()),
          const SizedBox(height: 12),
          const Text(
            'Note: ClearCue is an informational assistant only. It does not '
            'replace official authorities, bill providers, pharmacists or doctors.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
