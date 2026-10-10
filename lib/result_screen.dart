import 'package:flutter/material.dart';
import 'analyzer.dart';
import 'db/scan_repository.dart';

class _QA {
  final String question;
  final Answer answer;
  bool saved;
  _QA(this.question, this.answer, {this.saved = false});
}

class ResultScreen extends StatefulWidget {
  final AnalysisResult result;
  final String title;
  final String mode;
  final String text;
  final String question;
  final int? scanId; // set when opened from history (already saved)
  final List<Map<String, Object?>>? savedQa;
  const ResultScreen({
    super.key,
    required this.result,
    required this.title,
    required this.mode,
    required this.text,
    this.question = '',
    this.scanId,
    this.savedQa,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<bool> _checked;
  final List<_QA> _qa = [];
  final _askController = TextEditingController();
  int? _scanId;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.result.checklist.length, false);

    if (widget.scanId != null) {
      // Opened from history: load what was saved in the database
      _scanId = widget.scanId;
      for (final m in widget.savedQa ?? []) {
        final ev = (m['evidence'] as String? ?? '');
        _qa.add(_QA(
          m['question'] as String,
          Answer(
            m['answer'] as String,
            ev.isEmpty ? <String>[] : ev.split('\n'),
            (m['found'] as int? ?? 0) == 1,
          ),
          saved: true,
        ));
      }
    } else {
      if (widget.question.trim().isNotEmpty) {
        _qa.add(_QA(widget.question,
            Analyzer.answer(widget.question, widget.text, widget.mode)));
      }
      _saveNewScan();
    }
  }

  Future<void> _saveNewScan() async {
    try {
      final lines = widget.text
          .split(RegExp(r'[\r\n]+'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final first = lines.isEmpty ? 'Scan' : lines.first;
      final preview = first.length > 45 ? '${first.substring(0, 45)}...' : first;
      final id = await ScanRepository.insertScan(widget.mode, preview, widget.text);
      _scanId = id;
      for (final item in _qa) {
        if (!item.saved) {
          await ScanRepository.insertQa(id, item.question, item.answer);
          item.saved = true;
        }
      }
    } catch (_) {
      // Saving is optional; the app keeps working if it fails.
    }
  }

  Future<void> _saveQa(_QA item) async {
    final id = _scanId;
    if (id == null) return; // _saveNewScan will save it
    try {
      await ScanRepository.insertQa(id, item.question, item.answer);
      item.saved = true;
    } catch (_) {}
  }

  @override
  void dispose() {
    _askController.dispose();
    super.dispose();
  }

  void _ask() {
    final q = _askController.text.trim();
    if (q.isEmpty) return;
    final item = _QA(q, Analyzer.answer(q, widget.text, widget.mode));
    setState(() {
      _qa.insert(0, item);
      _askController.clear();
    });
    _saveQa(item);
    FocusScope.of(context).unfocus();
  }

  Widget _heading(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _qaCard(_QA item) {
    final ok = item.answer.found;
    return Card(
      color: ok ? Colors.teal.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.question,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(item.answer.text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (item.answer.evidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final e in item.answer.evidence)
                Text('From your text: $e',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _details(AnalysisResult r) {
    return [
      if (r.warnings.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please note',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...r.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $w'),
                  )),
            ],
          ),
        ),
      for (final s in r.sections) ...[
        _heading(s.title, Icons.label_important),
        for (final f in s.items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(f.text, style: const TextStyle(fontSize: 15)),
            ),
          ),
      ],
      if (r.checklist.isNotEmpty) ...[
        _heading('Action Checklist', Icons.checklist),
        for (int i = 0; i < r.checklist.length; i++)
          CheckboxListTile(
            value: _checked[i],
            onChanged: (v) => setState(() => _checked[i] = v ?? false),
            title: Text(
              r.checklist[i],
              style: TextStyle(
                decoration: _checked[i] ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
      ],
      if (r.glossary.isNotEmpty) ...[
        _heading('Simple Meanings', Icons.translate),
        for (final e in r.glossary.entries)
          ListTile(
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(e.value),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _askController,
                  onSubmitted: (_) => _ask(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Type your question here...',
                    prefixIcon: Icon(Icons.help_outline),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _ask, child: const Text('Ask')),
            ],
          ),
          const SizedBox(height: 12),
          if (_qa.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Type a question above and press Ask. The answer will appear here.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          for (final item in _qa) _qaCard(item),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: const Text('More details (optional)'),
              childrenPadding: const EdgeInsets.all(12),
              children: _details(r),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ClearCue is an informational assistant only. Please verify with '
            'official authorities, bill providers, pharmacists or healthcare professionals.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
