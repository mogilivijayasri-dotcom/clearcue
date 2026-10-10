import 'medicine_data.dart';

class Finding {
  final String text;
  final String evidence; // original line from the scanned text
  Finding(this.text, this.evidence);
}

class Section {
  final String title;
  final List<Finding> items;
  Section(this.title, this.items);
}

class Answer {
  final String text;
  final List<String> evidence;
  final bool found;
  Answer(this.text, this.evidence, this.found);
}

class AnalysisResult {
  final List<Section> sections;
  final List<String> checklist;
  final List<String> warnings;
  final Map<String, String> glossary;
  AnalysisResult(this.sections, this.checklist, this.warnings, this.glossary);
}

class Analyzer {
  // Loaded from the SQLite database at app start (falls back to the built-in seed list).
  static List<MedicineInfo> medicines = medicineDb;

  static final _dateRe = RegExp(
    r'\b\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}\b|'
    r'\b\d{1,2}(st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?,?\s+\d{2,4}\b',
    caseSensitive: false,
  );
  static final _amountRe =
      RegExp(r'(₹|rs\.?|inr)\s?[\d,]+(\.\d+)?', caseSensitive: false);
  static final _numRe = RegExp(
      r'(?:₹|\b(?:rs\.?|inr))?\s?\d[\d,]*(?:\.\d+)?',
      caseSensitive: false);
  static final _currencyRe = RegExp(r'(₹|\brs\.?|\binr)', caseSensitive: false);
  static final _currencyStartRe = RegExp(r'^(₹|rs|inr)', caseSensitive: false);
  static const _unitWords = ['unit', 'kwh', 'reading', 'consumption'];
  static const _eligAnswerKeys = [
    'eligible', 'eligibility', 'minimum', 'criteria', 'must', 'percent', '%',
    'age limit', 'years'
  ];
  static const _generic = <String>{
    'total', 'amount', 'much', 'pay', 'payable', 'payment', 'bill', 'cost',
    'price', 'rupee', 'rupees', 'fee', 'charge', 'balance', 'tell', 'show',
    'give', 'whole', 'full', 'overall',
  };

  static const _docKeys = [
    'certificate', 'aadhaar', 'aadhar', 'marksheet', 'photo', 'passport',
    'document', 'proof', 'bank', 'copy', 'xerox'
  ];
  static const _eligKeys = [
    'eligible', 'eligibility', 'minimum', 'must', 'should', 'age', 'percent',
    '%', 'income', 'criteria'
  ];
  static const _deadlineKeys = [
    'last date', 'deadline', 'due date', 'before', 'on or before', 'closing'
  ];

  static const _glossaryDb = {
    'fixed charge': 'A fixed amount you pay every month, whether or not you use electricity.',
    'fixed charges': 'A fixed amount you pay every month, whether or not you use electricity.',
    'surcharge': 'An extra charge, usually added for late payment or a special reason.',
    'kwh': 'A unit of electricity. 1 kWh = 1 unit.',
    'units': 'The amount of electricity you have used.',
    'arrears': 'Amount still pending from earlier bills.',
    'electricity duty': 'A tax paid to the government.',
    'penalty': 'An extra amount you must pay if you are late.',
    'eligibility': 'The conditions you must meet to apply.',
    'deadline': 'The last date by which something must be done.',
    'self-attested': 'A copy that you have signed yourself.',
    'attested': 'A copy signed by an official person (such as a gazetted officer).',
    'bonafide': 'A certificate that proves you are studying in a college or school.',
    'income certificate': 'An official certificate that shows your family income.',
    'caste certificate': 'An official certificate that proves your category (SC/ST/BC etc.).',
    'renewal': 'Continuing something that already exists, for another period.',
    'dosage': 'How much medicine to take and when (only a doctor should decide this).',
    'contraindication': 'A situation in which a medicine should not be used.',
  };

  static const _stop = <String>{
    'the', 'is', 'are', 'was', 'were', 'and', 'for', 'what', 'which', 'who',
    'how', 'when', 'where', 'does', 'did', 'can', 'this', 'that', 'with',
    'from', 'there', 'any', 'about', 'tell', 'please', 'give', 'should',
    'will', 'have', 'has', 'you', 'your', 'not', 'but', 'its', 'also', 'get',
    'know', 'want', 'need', 'many', 'much', 'whom', 'whose', 'than', 'then',
  };

  static List<String> _lines(String text) => text
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  static bool _has(String line, List<String> keys) {
    final l = line.toLowerCase();
    return keys.any((k) => l.contains(k));
  }

  static List<Finding> _grab(List<String> lines, List<String> keys,
      {bool alsoDates = false, int max = 8}) {
    final out = <Finding>[];
    for (final line in lines) {
      if (_has(line, keys) || (alsoDates && _dateRe.hasMatch(line))) {
        out.add(Finding(line, line));
        if (out.length >= max) break;
      }
    }
    return out;
  }

  static bool _matchesAlias(String lower, String alias) =>
      RegExp('\\b${RegExp.escape(alias)}\\b').hasMatch(lower);

  // ---------------------------------------------------------------------
  // Full analysis (sections, checklist, warnings)
  // ---------------------------------------------------------------------
  static AnalysisResult analyze(String text, String mode) {
    final lines = _lines(text);
    final warnings = <String>[];
    final sections = <Section>[];
    final checklist = <String>[];

    if (text.trim().length < 20) {
      warnings.add('The text is too short or unclear. Please scan again.');
    }

    if (mode == 'doc') {
      final deadlines = _grab(lines, _deadlineKeys, alsoDates: true);
      final eligibility = _grab(lines, _eligKeys);
      final docs = _grab(lines, _docKeys);

      if (deadlines.isNotEmpty) sections.add(Section('Deadlines', deadlines));
      if (eligibility.isNotEmpty) sections.add(Section('Eligibility', eligibility));
      if (docs.isNotEmpty) sections.add(Section('Required Documents', docs));

      for (final d in docs) checklist.add('Keep ready: ${d.text}');
      for (final e in eligibility.take(3)) checklist.add('Check: ${e.text}');
      for (final d in deadlines) checklist.add('Complete before the deadline: ${d.text}');

      if (deadlines.isEmpty) warnings.add('No deadline or last date was found. Please check the original notice.');
      if (eligibility.isEmpty) warnings.add('No eligibility conditions were found.');
      if (docs.isEmpty) warnings.add('No list of required documents was found.');
    } else if (mode == 'bill') {
      final total = <Finding>[];
      for (final line in lines) {
        if (_has(line, ['total', 'amount payable', 'net amount', 'amount due', 'payable']) &&
            _amountRe.hasMatch(line)) {
          total.add(Finding(_amountRe.firstMatch(line)!.group(0)!, line));
        }
      }
      final due = _grab(lines, ['due date', 'last date', 'pay before', 'pay by']);
      final period = _grab(lines, ['billing period', 'bill period', 'period', 'from date', 'to date']);
      final units = _grab(lines, ['units', 'kwh', 'consumption', 'reading']);
      final charges = _grab(lines, [
        'charge', 'duty', 'surcharge', 'tax', 'fixed', 'penalty', 'arrears', 'gst'
      ], max: 12);

      if (total.isNotEmpty) sections.add(Section('Total Amount', total));
      if (due.isNotEmpty) sections.add(Section('Due Date', due));
      if (period.isNotEmpty) sections.add(Section('Billing Period', period));
      if (units.isNotEmpty) sections.add(Section('Units Consumed', units));
      if (charges.isNotEmpty) sections.add(Section('Charges Listed', charges));

      if (due.isNotEmpty) checklist.add('Pay before the due date: ${due.first.text}');
      if (total.isNotEmpty) checklist.add('Check the amount: ${total.first.text}');
      if (charges.isNotEmpty) checklist.add('Review the charges list and ask your bill provider about any charge you do not understand');

      if (total.isEmpty) warnings.add('The total amount was not found clearly.');
      if (due.isEmpty) warnings.add('No due date was found. Check the original bill to avoid a late fee.');
    } else {
      final lower = text.toLowerCase();
      final found = <Finding>[];
      for (final m in medicines) {
        final alias = m.aliases.where((a) => _matchesAlias(lower, a));
        if (alias.isNotEmpty) {
          found.add(Finding(
            '${m.name}\n\nPurpose: ${m.purpose}\n\nWarnings: ${m.warnings}\n\nPossible side effects: ${m.sideEffects}',
            alias.first,
          ));
        }
      }
      if (found.isNotEmpty) sections.add(Section('Medicine Information', found));

      final extra = _grab(lines, ['mg', 'tablet', 'capsule', 'syrup', 'composition', 'contains', 'exp', 'mfg', 'storage', 'store'], max: 8);
      if (extra.isNotEmpty) sections.add(Section('Details on Package', extra));

      if (found.isEmpty) {
        warnings.add('This medicine is not in our database, so it could not be verified. Please ask a pharmacist.');
      }
      warnings.add('Dosage is not provided here. Use the medicine only as your doctor or pharmacist advises.');
      checklist.add('Check the expiry date');
      checklist.add('Confirm with a doctor or pharmacist');
    }

    final lowerAll = text.toLowerCase();
    final glossary = <String, String>{};
    _glossaryDb.forEach((k, v) {
      if (lowerAll.contains(k)) glossary[k] = v;
    });

    return AnalysisResult(sections, checklist, warnings, glossary);
  }

  // ---------------------------------------------------------------------
  // Question answering (no AI - keyword matching on the scanned text)
  // ---------------------------------------------------------------------
  static bool _asks(Set<String> words, String q, List<String> keys) {
    return keys.any((k) {
      if (k.contains(' ')) return q.contains(k);
      return words.any((w) => w == k || (k.length >= 5 && w.startsWith(k)));
    });
  }

  static String _stem(String w) =>
      (w.length > 3 && w.endsWith('s')) ? w.substring(0, w.length - 1) : w;

  static MedicineInfo? _medicineFor(String q, String lowerText) {
    for (final m in medicines) {
      if (m.aliases.any((a) => _matchesAlias(q, a))) return m;
    }
    for (final m in medicines) {
      if (m.aliases.any((a) => _matchesAlias(lowerText, a))) return m;
    }
    return null;
  }

  static Answer? _medicineAnswer(
      String q, Set<String> words, MedicineInfo m, List<String> lines) {
    if (_asks(words, q, ['side effect', 'side effects', 'reaction', 'reactions'])) {
      return Answer('${m.name}: possible side effects - ${m.sideEffects}', [m.name], true);
    }
    if (_asks(words, q, ['dose', 'dosage', 'how often', 'how many', 'how much', 'when to take', 'timing'])) {
      final ev = lines.where((l) => _has(l, ['mg', 'dose', 'dosage'])).take(2).toList();
      return Answer(
          'ClearCue does not give dosage advice. Follow your doctor\'s prescription or ask a pharmacist.',
          ev,
          true);
    }
    if (_asks(words, q, ['warning', 'warnings', 'precaution', 'careful', 'safe', 'avoid', 'pregnant', 'pregnancy', 'alcohol'])) {
      return Answer('${m.name}: ${m.warnings}', [m.name], true);
    }
    if (_asks(words, q, ['use', 'used', 'purpose', 'treat', 'why', 'for what', 'what is', 'fever', 'pain'])) {
      return Answer('${m.name}: ${m.purpose}', [m.name], true);
    }
    return null;
  }

  // ---- helpers for the simple answer engine ----
  static bool _hasNumber(String line) =>
      _numRe.hasMatch(line.replaceAll(_dateRe, ' '));

  static bool _hasDate(String line) => _dateRe.hasMatch(line);

  // Scanned bills often put the label on one line and the value on the next.
  // Returns [mergedLines, tailLines].
  static List<List<String>> _pairs(
      List<String> lines, bool Function(String) test) {
    final merged = <String>[];
    final tails = <String>[];
    for (var i = 0; i < lines.length - 1; i++) {
      final cur = lines[i];
      final next = lines[i + 1];
      final letters = RegExp(r'[A-Za-z]').allMatches(next).length;
      if (!test(cur) &&
          !RegExp(r'\d').hasMatch(cur) &&
          test(next) &&
          cur.length <= 60 &&
          !next.contains(':') &&
          next.length <= 30 &&
          letters <= 12) {
        merged.add('$cur: $next');
        tails.add(next);
      }
    }
    return [merged, tails];
  }

  static String? _moneyValue(String line) {
    final cleaned = line.replaceAll(_dateRe, ' ');
    final vals =
        _numRe.allMatches(cleaned).map((m) => m.group(0)!.trim()).toList();
    if (vals.isEmpty) return null;
    for (final v in vals) {
      if (_currencyStartRe.hasMatch(v)) return v;
    }
    return vals.last;
  }

  static String _labelOf(String line, String value) {
    final idx = line.indexOf(value);
    if (idx < 0) return '';
    return line.substring(0, idx).replaceAll(RegExp(r'[:\-–=\s]+$'), '').trim();
  }

  static Answer? _moneyAnswer(
      String q, Set<String> words, List<String> lines, Set<String> tokens) {
    final p = _pairs(lines, _hasNumber);
    final all = [...lines.where((l) => !p[1].contains(l)), ...p[0]];
    final pool =
        all.where((l) => !_has(l, _unitWords) && _hasNumber(l)).toList();
    if (pool.isEmpty) return null;

    if (words.contains('charges') || words.contains('breakdown')) {
      final ch = pool
          .where((l) => _has(l, [
                'charge', 'duty', 'tax', 'gst', 'surcharge', 'fixed',
                'penalty', 'arrears', 'fee'
              ]))
          .take(6)
          .toList();
      if (ch.isNotEmpty) return Answer(ch.join('\n'), [], true);
    }

    final specific = tokens.where((t) => !_generic.contains(t)).toList();
    final usePriority = specific.isEmpty ||
        _asks(words, q, [
          'total', 'payable', 'net', 'grand', 'pay', 'due', 'owe',
          'bill amount', 'how much', 'amount to', 'overall'
        ]);

    String? pick;
    if (!usePriority) {
      for (final l in pool) {
        final low = l.toLowerCase();
        if (specific.any((t) => low.contains(t))) {
          pick = l;
          break;
        }
      }
    }
    if (pick == null) {
      const prio = [
        'grand total', 'amount payable', 'net payable', 'net amount',
        'total amount', 'amount due', 'total', 'payable', 'amount', 'fee', 'pay'
      ];
      for (final k in prio) {
        final m = pool.where((l) => l.toLowerCase().contains(k)).toList();
        if (m.isEmpty) continue;
        pick = m.firstWhere((l) => _currencyRe.hasMatch(l),
            orElse: () => m.first);
        break;
      }
    }
    if (pick == null) return null;
    final value = _moneyValue(pick);
    if (value == null) return null;
    final label = _labelOf(pick, value);
    final text = label.isEmpty ? value : '$label: $value';
    return Answer(text, pick.trim() == text.trim() ? <String>[] : [pick], true);
  }

  static Answer? _dateAnswer(String q, Set<String> words, List<String> lines) {
    final p = _pairs(lines, _hasDate);
    final all = [...lines.where((l) => !p[1].contains(l)), ...p[0]];
    final dl = all.where(_hasDate).toList();

    List<String> pref;
    if (words.contains('due')) {
      pref = ['due date', 'due', 'pay before', 'pay by'];
    } else if (_asks(words, q, ['last', 'deadline', 'apply', 'submission'])) {
      pref = [
        'last date', 'deadline', 'apply', 'submission', 'closing', 'before',
        'on or before'
      ];
    } else if (_asks(words, q, ['expiry', 'expire', 'expires', 'exp'])) {
      pref = ['exp', 'expiry', 'valid'];
    } else if (words.contains('period')) {
      pref = ['period', 'from'];
    } else if (_asks(words, q, ['mfg', 'manufacturing'])) {
      pref = ['mfg', 'manufactur'];
    } else {
      pref = [];
    }

    var cand = <String>[];
    if (pref.isNotEmpty) {
      cand = dl.where((l) => _has(l, pref)).toList();
      if (cand.isEmpty) cand = all.where((l) => _has(l, pref)).toList();
    }
    if (cand.isEmpty) cand = dl;
    cand = cand.take(3).toList();
    if (cand.isEmpty) return null;
    return Answer(cand.join('\n'), [], true);
  }

  // ---- main entry: answers only what was asked ----
  static Answer answer(String question, String text, String mode) {
    final q = question.toLowerCase().trim();
    final lines = _lines(text);
    if (lines.isEmpty) {
      return Answer(
          'There is no text yet. Please scan or paste the text first.', [], false);
    }

    final words = q
        .replaceAll(RegExp(r'[^a-z0-9% ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toSet();

    if (mode == 'medicine') {
      final med = _medicineFor(q, text.toLowerCase());
      if (med != null) {
        final a = _medicineAnswer(q, words, med, lines);
        if (a != null) return a;
      }
    }

    final tokens = words
        .where((w) => w.length > 2 && !_stop.contains(w))
        .map(_stem)
        .toSet();

    final parts = <Answer>[];

    if (_asks(words, q, [
      'how much', 'amount', 'total', 'pay', 'payable', 'payment', 'cost',
      'fee', 'fees', 'price', 'charge', 'charges', 'rupees', 'balance',
      'breakdown', 'bill amount'
    ])) {
      final r = _moneyAnswer(q, words, lines, tokens);
      if (r != null) parts.add(r);
    }
    if (_asks(words, q, [
      'when', 'date', 'deadline', 'last day', 'by when', 'due', 'expiry',
      'expire', 'expires', 'period', 'mfg'
    ])) {
      final r = _dateAnswer(q, words, lines);
      if (r != null) parts.add(r);
    }
    if (_asks(words, q,
        ['units', 'unit', 'consumption', 'kwh', 'usage', 'reading'])) {
      final l = lines.where((x) => _has(x, _unitWords)).take(3).toList();
      if (l.isNotEmpty) parts.add(Answer(l.join('\n'), [], true));
    }
    if (_asks(words, q, [
      'document', 'documents', 'certificate', 'certificates', 'required',
      'submit', 'attach', 'bring', 'proof', 'upload'
    ])) {
      final l = lines.where((x) => _has(x, _docKeys)).take(4).toList();
      if (l.isNotEmpty) parts.add(Answer(l.join('\n'), [], true));
    }
    if (_asks(words, q, [
      'eligible', 'eligibility', 'who can', 'can i', 'qualify', 'criteria',
      'qualification'
    ])) {
      final l = lines.where((x) => _has(x, _eligAnswerKeys)).take(4).toList();
      if (l.isNotEmpty) parts.add(Answer(l.join('\n'), [], true));
    }

    if (parts.isNotEmpty) {
      return Answer(
        parts.map((p) => p.text).join('\n'),
        parts.expand((p) => p.evidence).toList(),
        true,
      );
    }

    // Fallback: the line(s) that share the most words with the question
    final scores = <int>[];
    for (final line in lines) {
      final low = line.toLowerCase();
      var s = 0;
      for (final t in tokens) {
        if (low.contains(t)) s += 2;
      }
      scores.add(s);
    }
    var best = 0;
    for (final s in scores) {
      if (s > best) best = s;
    }

    if (best < 2) {
      if (_asks(words, q, ['summary', 'summarize', 'about', 'explain', 'overview'])) {
        return Answer(lines.take(3).join('\n'), [], true);
      }
      return Answer('I could not find this in your text.', [], false);
    }

    final idx = List<int>.generate(lines.length, (i) => i)
      ..sort((a, b) {
        final c = scores[b].compareTo(scores[a]);
        return c != 0 ? c : a.compareTo(b);
      });
    final top = idx
        .where((i) => scores[i] >= 2 && scores[i] >= best - 2)
        .take(2)
        .map((i) => lines[i])
        .toList();
    return Answer(top.join('\n'), [], true);
  }
}
