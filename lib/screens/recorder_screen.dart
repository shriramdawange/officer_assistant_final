// ============================================================
// screens/recorder_screen.dart
// Pulsating mic UI → Whisper → LLaMA → Editor
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../core/app_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/shimmer_loaders.dart';
import 'editor_screen.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasRecorded = false;
  String? _audioPath;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  // Pulse animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // ── Permission Check ──────────────────────────────────────
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio.'),
          ),
        );
      }
      return false;
    }
    return true;
  }

  // ── Start Recording ───────────────────────────────────────
  Future<void> _startRecording() async {
    if (!await _checkPermission()) return;

    try {
      final dir = await getTemporaryDirectory();
      _audioPath =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _audioPath!,
      );

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _recordDuration = Duration.zero;
      });

      _pulseController.repeat(reverse: true);
      _waveController.repeat();

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  // ── Stop Recording ────────────────────────────────────────
  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _waveController.stop();

    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
      }
    }
  }

  // ── Process Audio ─────────────────────────────────────────
  Future<void> _processAudio() async {
    if (_audioPath == null) return;

    final auth = context.read<AuthProvider>();
    final letterProvider = context.read<LetterProvider>();
    final userId = auth.profile.id;

    await letterProvider.processAudio(audioPath: _audioPath!, userId: userId);

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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final letterProvider = context.watch<LetterProvider>();
    final isProcessing = letterProvider.isProcessing;

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        title: const Text('Voice Recorder'),
        backgroundColor: AppTheme.navyBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── Main Content ──────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // ── Status Text ──────────────────────
                  Animate(
                    key: ValueKey(_isRecording),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 300)),
                    ],
                    child: Column(
                      children: [
                        Text(
                          _isRecording
                              ? 'Recording...'
                              : _hasRecorded
                              ? 'Recording Complete'
                              : AppConstants.recordingHint,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: _isRecording
                                    ? AppTheme.navyBlue
                                    : AppTheme.textDark,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isRecording) ...[
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(_recordDuration),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: AppTheme.navyBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Pulsating Mic Button ─────────────
                  _buildMicButton(),

                  const SizedBox(height: 48),

                  // ── Hint ─────────────────────────────
                  if (!_isRecording && !_hasRecorded)
                    Text(
                      'Speak clearly in Marathi.\nThe AI will draft a formal English letter.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const Spacer(),

                  // ── Action Buttons ────────────────────
                  if (_hasRecorded && !isProcessing)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _processAudio,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Generate Letter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.navyBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _hasRecorded = false;
                                _audioPath = null;
                                _recordDuration = Duration.zero;
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Record Again'),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Processing Overlay ────────────────────────
          if (isProcessing)
            ProcessingOverlay(
              message: letterProvider.state == LetterState.transcribing
                  ? 'Transcribing your Marathi speech...'
                  : AppConstants.processingText,
            ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse rings
          if (_isRecording) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value * 1.4,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.navyBlue.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value * 1.2,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.navyBlue.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ],

          // Main button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isRecording
                  ? const LinearGradient(
                      colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppTheme.navyGradient,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : AppTheme.navyBlue)
                      .withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
