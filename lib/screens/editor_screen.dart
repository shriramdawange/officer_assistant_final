// ============================================================
// screens/editor_screen.dart
// Digital Paper letter editor with Refine + Export
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/app_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/pdf_service.dart';
import '../widgets/shimmer_loaders.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    final letter = context.read<LetterProvider>().currentLetter;
    _controller = TextEditingController(text: letter?.letterContent ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Save Letter ───────────────────────────────────────────
  Future<void> _saveLetter() async {
    final provider = context.read<LetterProvider>();
    provider.updateLetterContent(_controller.text);
    await provider.saveLetter();

    if (!mounted) return;
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Letter saved successfully!')));
  }

  // ── Export PDF ────────────────────────────────────────────
  Future<void> _exportPdf() async {
    final provider = context.read<LetterProvider>();
    final auth = context.read<AuthProvider>();

    if (provider.currentLetter == null) return;

    // Save first if not saved
    if (!_isSaved) {
      provider.updateLetterContent(_controller.text);
      await provider.saveLetter();
    }

    try {
      await PdfService.instance.shareLetter(
        letter: provider.currentLetter!,
        profile: auth.profile,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF export failed: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  // ── Refine Dialog ─────────────────────────────────────────
  void _showRefineDialog() {
    final refineController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Refine Letter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell the AI how to improve this letter',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: refineController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText:
                    'e.g. "Make it more formal", "Add urgency", "Shorten the body"',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final instruction = refineController.text.trim();
                  if (instruction.isEmpty) return;

                  Navigator.pop(ctx);
                  await context.read<LetterProvider>().refineLetter(
                    instruction,
                  );

                  if (mounted) {
                    final updated = context
                        .read<LetterProvider>()
                        .currentLetter;
                    if (updated != null) {
                      _controller.text = updated.letterContent;
                    }
                  }
                },
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Refine with AI'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LetterProvider>();
    final letter = provider.currentLetter;
    final isProcessing = provider.isProcessing;

    // Sync controller when letter updates from AI refinement
    if (!_isEditing &&
        letter != null &&
        _controller.text != letter.letterContent) {
      _controller.text = letter.letterContent;
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        title: const Text('Letter Editor'),
        backgroundColor: AppTheme.navyBlue,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit manually',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Done editing',
              onPressed: () {
                setState(() => _isEditing = false);
                provider.updateLetterContent(_controller.text);
              },
            ),
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Save',
            onPressed: _saveLetter,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Main Content ──────────────────────────────
          Column(
            children: [
              // ── Transcript Banner ─────────────────────
              if (provider.transcript != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppTheme.navyBlue.withValues(alpha: 0.06),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.record_voice_over_rounded,
                        size: 16,
                        color: AppTheme.navyBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transcript: ${provider.transcript}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.navyBlue,
                                fontStyle: FontStyle.italic,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Digital Paper ─────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                      SlideEffect(
                        begin: Offset(0, 0.1),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 400),
                      ),
                    ],
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.paperWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppTheme.divider, width: 1),
                      ),
                      child: Column(
                        children: [
                          // Paper header strip
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.navyBlue,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'GOVERNMENT OF MAHARASHTRA',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isSaved
                                        ? AppTheme.gold
                                        : Colors.white.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Gold divider
                          Container(height: 2, color: AppTheme.gold),

                          // Letter content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: _isEditing
                                ? TextField(
                                    controller: _controller,
                                    maxLines: null,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontFamily: 'monospace',
                                          height: 1.8,
                                        ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      filled: false,
                                    ),
                                  )
                                : SelectableText(
                                    letter?.letterContent ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.8),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Action Bar ────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing ? null : _showRefineDialog,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                          ),
                          label: const Text(AppConstants.refineLetter),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : _exportPdf,
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 18,
                          ),
                          label: const Text(AppConstants.exportPdfText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Processing Overlay ────────────────────────
          if (isProcessing)
            ProcessingOverlay(message: 'Refining your letter...'),
        ],
      ),
    );
  }
}
