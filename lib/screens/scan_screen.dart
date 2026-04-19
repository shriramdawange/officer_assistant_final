// ============================================================
// screens/scan_screen.dart
// Google ML Kit OCR → AI Letter Formatter
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_provider.dart';
import '../core/theme.dart';
import '../widgets/shimmer_loaders.dart';
import 'editor_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _imageFile;
  String? _extractedText;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // ── Pick Image ────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _extractedText = null;
      });

      await _runOcr();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  // ── Run OCR ───────────────────────────────────────────────
  Future<void> _runOcr() async {
    if (_imageFile == null) return;

    setState(() => _isScanning = true);

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final recognized = await _textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognized.text;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
      }
    }
  }

  // ── Format with AI ────────────────────────────────────────
  Future<void> _formatWithAI() async {
    if (_extractedText == null || _extractedText!.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final letterProvider = context.read<LetterProvider>();

    await letterProvider.processScannedText(
      rawText: _extractedText!,
      userId: auth.profile.id,
    );

    if (!mounted) return;

    if (letterProvider.state == LetterState.ready) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
    } else if (letterProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(letterProvider.error!),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LetterProvider>();
    final isProcessing = provider.isProcessing;

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        title: const Text('Scan Document'),
        backgroundColor: AppTheme.navyBlue,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Source Buttons ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Image Preview ─────────────────────────
                if (_imageFile != null)
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 300)),
                    ],
                    child: Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                if (_isScanning) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.navyBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Scanning document...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Extracted Text ────────────────────────
                if (_extractedText != null && !_isScanning) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Extracted Text',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: SelectableText(
                      _extractedText!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Format button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : _formatWithAI,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Format as Government Letter'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Empty State ───────────────────────────
                if (_imageFile == null)
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: Container(
                      margin: const EdgeInsets.only(top: 32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.document_scanner_rounded,
                            size: 64,
                            color: AppTheme.navyBlue.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Scan a Document',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take a photo or pick from gallery.\nThe AI will extract and reformat the text.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // ── Processing Overlay ────────────────────────
          if (isProcessing)
            ProcessingOverlay(message: 'Formatting scanned document...'),
        ],
      ),
    );
  }
}

// ── Source Button ─────────────────────────────────────────────
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.navyBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.navyBlue, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
