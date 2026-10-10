import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'analyzer.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  final String mode; // doc | bill | medicine
  final String title;
  const ScanScreen({super.key, required this.mode, required this.title});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _controller = TextEditingController();
  final _questionController = TextEditingController();
  TextRecognizer? _recognizer;
  File? _image;
  bool _loading = false;

  String get _questionHint {
    switch (widget.mode) {
      case 'bill':
        return 'Example: What is the total amount and due date?';
      case 'medicine':
        return 'Example: What is this medicine used for?';
      default:
        return 'Example: What documents are required?';
    }
  }

  String get _sampleText {
    switch (widget.mode) {
      case 'bill':
        return 'Billing Period: 01/09/2026 to 30/09/2026\n'
            'Units Consumed: 245 kWh\n'
            'Fixed Charges: Rs. 120\n'
            'Electricity Duty: Rs. 35\n'
            'Surcharge: Rs. 50\n'
            'Total Amount Payable: Rs. 1,450\n'
            'Due Date: 15/10/2026';
      case 'medicine':
        return 'Dolo 650 Tablet\n'
            'Paracetamol Tablets IP 650 mg\n'
            'Each tablet contains Paracetamol 650 mg\n'
            'Mfg: 01/2026  Exp: 12/2027';
      default:
        return 'Scholarship Notification\n'
            'Last date to apply: 25/10/2026\n'
            'Eligibility: Minimum 60% in previous year. Family income below Rs. 2,50,000.\n'
            'Required: Income certificate, Aadhaar copy, Marksheet, Passport size photo';
    }
  }

  String get _sampleQuestion {
    switch (widget.mode) {
      case 'bill':
        return 'What is the total amount and due date?';
      case 'medicine':
        return 'What is this medicine used for?';
      default:
        return 'What documents are required?';
    }
  }

  void _useSample() {
    setState(() {
      _controller.text = _sampleText;
      _questionController.text = _sampleQuestion;
    });
  }

  Future<void> _pick(ImageSource source) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Photo scanning works only on the phone app. Please paste the text here.')),
      );
      return;
    }
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;
      setState(() {
        _image = File(picked.path);
        _loading = true;
      });
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
      final input = InputImage.fromFilePath(picked.path);
      final result = await _recognizer!.processImage(input);
      setState(() {
        _controller.text = result.text;
        _loading = false;
      });
      if (!mounted) return;
      if (result.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No text found in the image. Try a clearer photo or paste the text.')),
        );
      } else {
        _analyze(); // go straight to the explanation
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not read the image. Please paste the text instead.')),
      );
    }
  }

  void _analyze() {
    final text = _controller.text;
    final result = Analyzer.analyze(text, widget.mode);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: result,
          title: widget.title,
          mode: widget.mode,
          text: text,
          question: _questionController.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _questionController.dispose();
    _recognizer?.close();
    super.dispose();
  }

  Widget _step(String number, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.teal,
            child: Text(number,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _step('1', 'Take a photo, or paste the text'),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _useSample,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Try a sample'),
            ),
          ),
          if (_image != null && !kIsWeb)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_image!, height: 160, fit: BoxFit.cover),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 7,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'The text from your photo appears here. You can also paste text here.',
            ),
          ),
          const SizedBox(height: 16),
          _step('2', 'Ask a question (optional)'),
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _questionHint,
              prefixIcon: const Icon(Icons.help_outline),
            ),
          ),
          const SizedBox(height: 16),
          _step('3', 'Press the button to get your answer'),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _controller.text.trim().isEmpty ? null : _analyze,
              icon: const Icon(Icons.search),
              label: const Text('Get Answer'),
            ),
          ),
        ],
      ),
    );
  }
}
