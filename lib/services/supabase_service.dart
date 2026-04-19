// ============================================================
// services/supabase_service.dart
// Handles Database operations: Letters, Profiles, Officer Notes
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
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
    await _safeCall(
      () => _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.rajpatraai://login-callback',
      ),
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _safeCall(() => _client.auth.signOut());
  }

  // ── Profile ───────────────────────────────────────────────

  /// Fetch or create the user profile from Supabase.
  Future<UserProfile?> fetchProfile(String userId) async {
    return _safeCall(() async {
      final response = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    });
  }

  /// Upsert (create or update) a user profile.
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    return _safeCall(() async {
      final response = await _client
          .from(AppConstants.profilesTable)
          .upsert(profile.toJson())
          .select()
          .single();

      return UserProfile.fromJson(response);
    });
  }

  // ── Letters ───────────────────────────────────────────────

  /// Fetch all letters for the current user, sorted by date desc.
  Future<List<LetterModel>> fetchHistory({String? searchQuery}) async {
    return _safeCall(() async {
      final userId = currentUser?.id;
      if (userId == null) throw SupabaseServiceException('Not authenticated.');

      final response = await _client
          .from(AppConstants.lettersTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final letters = (response as List<dynamic>)
          .map((json) => LetterModel.fromJson(json as Map<String, dynamic>))
          .toList();

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
    });
  }

  /// Save a new letter to Supabase.
  Future<LetterModel> saveLetter(LetterModel letter) async {
    return _safeCall(() async {
      final response = await _client
          .from(AppConstants.lettersTable)
          .insert(letter.toJson())
          .select()
          .single();

      return LetterModel.fromJson(response);
    });
  }

  /// Update an existing letter.
  Future<LetterModel> updateLetter(LetterModel letter) async {
    return _safeCall(() async {
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
    });
  }

  /// Delete a letter by ID.
  Future<void> deleteLetter(String letterId) async {
    await _safeCall(
      () => _client.from(AppConstants.lettersTable).delete().eq('id', letterId),
    );
  }

  /// Fetch a single letter by ID.
  Future<LetterModel?> fetchLetterById(String letterId) async {
    return _safeCall(() async {
      final response = await _client
          .from(AppConstants.lettersTable)
          .select()
          .eq('id', letterId)
          .maybeSingle();

      if (response == null) return null;
      return LetterModel.fromJson(response);
    });
  }

  /// Fetch letters created on a specific date (for calendar view).
  Future<List<LetterModel>> fetchLettersByDate(DateTime date) async {
    return _safeCall(() async {
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
    });
  }

  // ── Officer Notes ─────────────────────────────────────────
  // Table schema expected in Supabase:
  //   officer_notes (
  //     id          uuid primary key default gen_random_uuid(),
  //     user_id     uuid references auth.users,
  //     title       text,
  //     content     text,
  //     created_at  timestamptz default now(),
  //     updated_at  timestamptz default now()
  //   )

  /// Fetch all notes for the current user.
  Future<List<OfficerNote>> fetchNotes() async {
    return _safeCall(() async {
      final userId = currentUser?.id;
      if (userId == null) throw SupabaseServiceException('Not authenticated.');

      final response = await _client
          .from(AppConstants.officerNotesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => OfficerNote.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Save a new note.
  Future<OfficerNote> saveNote({
    required String title,
    required String content,
  }) async {
    return _safeCall(() async {
      final userId = currentUser?.id;
      if (userId == null) throw SupabaseServiceException('Not authenticated.');

      final response = await _client
          .from(AppConstants.officerNotesTable)
          .insert({
            'user_id': userId,
            'title': title,
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return OfficerNote.fromJson(response);
    });
  }

  /// Update an existing note.
  Future<OfficerNote> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    return _safeCall(() async {
      final response = await _client
          .from(AppConstants.officerNotesTable)
          .update({
            'title': title,
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', noteId)
          .select()
          .single();

      return OfficerNote.fromJson(response);
    });
  }

  /// Delete a note by ID.
  Future<void> deleteNote(String noteId) async {
    await _safeCall(
      () => _client
          .from(AppConstants.officerNotesTable)
          .delete()
          .eq('id', noteId),
    );
  }

  // ── Error Handling Helper ─────────────────────────────────

  /// Wraps any Supabase call with network + error detection.
  /// Throws [SupabaseServiceException] with a user-friendly message.
  Future<T> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on SocketException {
      throw SupabaseServiceException(
        'No internet connection. Please check your network and try again.',
      );
    } on PostgrestException catch (e) {
      debugPrint('[Supabase] DB error: ${e.message}');
      throw SupabaseServiceException('Database error: ${e.message}');
    } on AuthException catch (e) {
      debugPrint('[Supabase] Auth error: ${e.message}');
      throw SupabaseServiceException('Authentication error: ${e.message}');
    } on SupabaseServiceException {
      rethrow;
    } catch (e) {
      debugPrint('[Supabase] Unexpected error: $e');
      throw SupabaseServiceException('Something went wrong. Please try again.');
    }
  }
}

// ── Officer Note Model ────────────────────────────────────────
class OfficerNote {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OfficerNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfficerNote.fromJson(Map<String, dynamic> json) => OfficerNote(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// ── Custom Exception ──────────────────────────────────────────
class SupabaseServiceException implements Exception {
  final String message;
  const SupabaseServiceException(this.message);

  @override
  String toString() => 'SupabaseServiceException: $message';
}
