// ============================================================
// services/supabase_service.dart
// Handles Auth (Google OAuth) + Database (Letters, Profiles)
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/letter_model.dart';
import '../models/user_profile.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────

  /// Returns the currently signed-in user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Google OAuth (opens browser/webview).
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.rajpatraai://login-callback',
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Profile ───────────────────────────────────────────────

  /// Fetch or create the user profile from Supabase.
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      throw SupabaseServiceException('Failed to fetch profile: $e');
    }
  }

  /// Upsert (create or update) a user profile.
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    try {
      final response = await _client
          .from(AppConstants.profilesTable)
          .upsert(profile.toJson())
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw SupabaseServiceException('Failed to upsert profile: $e');
    }
  }

  // ── Letters ───────────────────────────────────────────────

  /// Fetch all letters for the current user, sorted by date desc.
  Future<List<LetterModel>> fetchHistory({String? searchQuery}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw SupabaseServiceException('Not authenticated.');

      var query = _client
          .from(AppConstants.lettersTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final response = await query;

      final letters = (response as List<dynamic>)
          .map((json) => LetterModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Client-side search filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return letters
            .where(
              (l) =>
                  l.subject.toLowerCase().contains(q) ||
                  l.letterContent.toLowerCase().contains(q) ||
                  l.transcript.toLowerCase().contains(q),
            )
            .toList();
      }

      return letters;
    } catch (e) {
      if (e is SupabaseServiceException) rethrow;
      throw SupabaseServiceException('Failed to fetch history: $e');
    }
  }

  /// Save a new letter to Supabase.
  Future<LetterModel> saveLetter(LetterModel letter) async {
    try {
      final response = await _client
          .from(AppConstants.lettersTable)
          .insert(letter.toJson())
          .select()
          .single();

      return LetterModel.fromJson(response);
    } catch (e) {
      throw SupabaseServiceException('Failed to save letter: $e');
    }
  }

  /// Update an existing letter.
  Future<LetterModel> updateLetter(LetterModel letter) async {
    try {
      final response = await _client
          .from(AppConstants.lettersTable)
          .update({
            'letter_content': letter.letterContent,
            'subject': letter.subject,
            'status': letter.status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', letter.id)
          .select()
          .single();

      return LetterModel.fromJson(response);
    } catch (e) {
      throw SupabaseServiceException('Failed to update letter: $e');
    }
  }

  /// Delete a letter by ID.
  Future<void> deleteLetter(String letterId) async {
    try {
      await _client.from(AppConstants.lettersTable).delete().eq('id', letterId);
    } catch (e) {
      throw SupabaseServiceException('Failed to delete letter: $e');
    }
  }

  /// Fetch a single letter by ID.
  Future<LetterModel?> fetchLetterById(String letterId) async {
    try {
      final response = await _client
          .from(AppConstants.lettersTable)
          .select()
          .eq('id', letterId)
          .maybeSingle();

      if (response == null) return null;
      return LetterModel.fromJson(response);
    } catch (e) {
      throw SupabaseServiceException('Failed to fetch letter: $e');
    }
  }

  /// Fetch letters created on a specific date (for calendar view).
  Future<List<LetterModel>> fetchLettersByDate(DateTime date) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw SupabaseServiceException('Not authenticated.');

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from(AppConstants.lettersTable)
          .select()
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => LetterModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SupabaseServiceException('Failed to fetch letters by date: $e');
    }
  }
}

// ── Custom Exception ──────────────────────────────────────────
class SupabaseServiceException implements Exception {
  final String message;
  const SupabaseServiceException(this.message);

  @override
  String toString() => 'SupabaseServiceException: $message';
}
