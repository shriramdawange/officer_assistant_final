// ============================================================
// core/app_provider.dart
// Central state management via Provider
// Direct-access mode — no login required
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/letter_model.dart';
import '../models/user_profile.dart';
import '../services/groq_service.dart';

// ── Guest Profile (hardcoded, no auth) ───────────────────────
const _kGuestProfile = UserProfile(
  id: 'guest-officer-001',
  email: 'officer@maharashtra.gov.in',
  fullName: 'Officer Saheb',
  designation: 'Government Officer',
  department: 'Government of Maharashtra',
  avatarUrl: null,
  createdAt: null,
);

// ── Auth Provider ─────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  // Always authenticated as guest — no login screen
  final UserProfile _profile = _kGuestProfile;

  UserProfile get profile => _profile;
  bool get isLoading => false;
  String? get error => null;
  bool get isAuthenticated => true; // always true

  void clearError() {}
}

// ── Letter Provider ───────────────────────────────────────────
enum LetterState { idle, recording, transcribing, generating, ready, error }

class LetterProvider extends ChangeNotifier {
  final List<LetterModel> _letters = [];
  LetterModel? _currentLetter;
  LetterState _state = LetterState.idle;
  String? _error;
  String? _transcript;
  bool _isLoadingHistory = false;
  String _searchQuery = '';

  List<LetterModel> get letters => _filteredLetters;
  LetterModel? get currentLetter => _currentLetter;
  LetterState get state => _state;
  String? get error => _error;
  String? get transcript => _transcript;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isProcessing =>
      _state == LetterState.transcribing || _state == LetterState.generating;

  List<LetterModel> get _filteredLetters {
    if (_searchQuery.isEmpty) return List.unmodifiable(_letters);
    final q = _searchQuery.toLowerCase();
    return _letters
        .where(
          (l) =>
              l.subject.toLowerCase().contains(q) ||
              l.letterContent.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Process Audio → Letter ────────────────────────────────
  Future<void> processAudio({
    required String audioPath,
    required String userId,
  }) async {
    _state = LetterState.transcribing;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Transcribe
      _transcript = await GroqService.instance.transcribeAudio(audioPath);

      _state = LetterState.generating;
      notifyListeners();

      // Step 2: Generate letter
      final letterContent = await GroqService.instance.generateLetter(
        _transcript!,
      );

      // Step 3: Extract subject
      final subject = _extractSubject(letterContent);

      // Step 4: Create model
      _currentLetter = LetterModel(
        id: const Uuid().v4(),
        userId: userId,
        transcript: _transcript!,
        letterContent: letterContent,
        subject: subject,
        createdAt: DateTime.now(),
        status: 'draft',
      );

      _state = LetterState.ready;
      notifyListeners();
    } on GroqException catch (e) {
      _error = e.message;
      _state = LetterState.error;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = LetterState.error;
      notifyListeners();
    }
  }

  // ── Process Scanned Text → Letter ────────────────────────
  Future<void> processScannedText({
    required String rawText,
    required String userId,
  }) async {
    _state = LetterState.generating;
    _error = null;
    notifyListeners();

    try {
      final letterContent = await GroqService.instance.formatScannedText(
        rawText,
      );
      final subject = _extractSubject(letterContent);

      _currentLetter = LetterModel(
        id: const Uuid().v4(),
        userId: userId,
        transcript: rawText,
        letterContent: letterContent,
        subject: subject,
        createdAt: DateTime.now(),
        status: 'draft',
      );

      _state = LetterState.ready;
      notifyListeners();
    } on GroqException catch (e) {
      _error = e.message;
      _state = LetterState.error;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = LetterState.error;
      notifyListeners();
    }
  }

  // ── Refine Letter ─────────────────────────────────────────
  Future<void> refineLetter(String instruction) async {
    if (_currentLetter == null) return;

    _state = LetterState.generating;
    _error = null;
    notifyListeners();

    try {
      final refined = await GroqService.instance.refineLetter(
        currentLetter: _currentLetter!.letterContent,
        instruction: instruction,
      );

      _currentLetter = _currentLetter!.copyWith(
        letterContent: refined,
        updatedAt: DateTime.now(),
      );

      _state = LetterState.ready;
      notifyListeners();
    } on GroqException catch (e) {
      _error = e.message;
      _state = LetterState.error;
      notifyListeners();
    }
  }

  // ── Save Letter ───────────────────────────────────────────
  /// Saves locally (in-memory). No Supabase required.
  Future<void> saveLetter() async {
    if (_currentLetter == null) return;
    final existing = _letters.indexWhere((l) => l.id == _currentLetter!.id);
    if (existing == -1) {
      _letters.insert(0, _currentLetter!);
    } else {
      _letters[existing] = _currentLetter!;
    }
    notifyListeners();
  }

  // ── Update Letter Content ─────────────────────────────────
  void updateLetterContent(String content) {
    if (_currentLetter == null) return;
    _currentLetter = _currentLetter!.copyWith(
      letterContent: content,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // ── Load History ──────────────────────────────────────────
  /// Letters are already in-memory — nothing to fetch.
  Future<void> loadHistory() async {
    _isLoadingHistory = false;
    notifyListeners();
  }

  // ── Delete Letter ─────────────────────────────────────────
  Future<void> deleteLetter(String letterId) async {
    _letters.removeWhere((l) => l.id == letterId);
    if (_currentLetter?.id == letterId) _currentLetter = null;
    notifyListeners();
  }

  // ── Set Current Letter ────────────────────────────────────
  void setCurrentLetter(LetterModel letter) {
    _currentLetter = letter;
    _state = LetterState.ready;
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────
  void reset() {
    _currentLetter = null;
    _transcript = null;
    _state = LetterState.idle;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────
  String _extractSubject(String letterContent) {
    final lines = letterContent.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('subject:')) {
        return trimmed.substring(8).trim();
      }
    }
    // Fallback: use first non-empty line
    for (final line in lines) {
      if (line.trim().isNotEmpty) return line.trim();
    }
    return 'Government Letter';
  }
}
