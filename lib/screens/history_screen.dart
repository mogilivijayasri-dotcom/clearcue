import 'package:flutter/material.dart';
import '../analyzer.dart';
import '../db/scan_repository.dart';
import '../result_screen.dart';

String modeLabel(String mode) {
  switch (mode) {
    case 'bill':
      return 'Bill Analysis';
    case 'medicine':
      return 'Medicine Scanner';
    default:
      return 'Document / Notice';
  }
}

String formatDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, $hh:$mm';
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = ScanRepository.listScans();
  }

  void _reload() {
    setState(() => _future = ScanRepository.listScans());
  }

  IconData _icon(String mode) {
    switch (mode) {
      case 'bill':
        return Icons.receipt_long;
      case 'medicine':
        return Icons.medication;
      default:
        return Icons.description;
    }
  }

  Future<void> _open(ScanRecord r) async {
    final qa = await ScanRepository.qaFor(r.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: Analyzer.analyze(r.text, r.mode),
          title: modeLabel(r.mode),
          mode: r.mode,
          text: r.text,
          scanId: r.id,
          savedQa: qa,
        ),
      ),
    );
    _reload();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('All saved scans and answers will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ScanRepository.clearAll();
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: FutureBuilder<List<ScanRecord>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Could not load history.'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No scans yet. Your scans and answers will be saved here automatically.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Icon(_icon(r.mode), color: Colors.teal),
                  ),
                  title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${modeLabel(r.mode)}  •  ${formatDate(r.createdAt)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ScanRepository.deleteScan(r.id);
                      _reload();
                    },
                  ),
                  onTap: () => _open(r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
