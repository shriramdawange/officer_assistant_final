// ============================================================
// services/groq_service.dart
// Handles Whisper (STT) + LLaMA (LLM) via Groq API
// ============================================================

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';

class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();

  late final Dio _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.groqBaseUrl,
        headers: {'Authorization': 'Bearer ${AppConstants.groqApiKey}'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
  }

  // ── Step 1: Transcribe Marathi Audio via Whisper ──────────
  /// Sends the recorded audio file to Groq Whisper and returns
  /// the Marathi transcript.
  Future<String> transcribeAudio(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      if (!file.existsSync()) {
        throw GroqException('Audio file not found: $audioFilePath');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'recording.m4a',
        ),
        'model': AppConstants.groqWhisperModel,
        'language': 'mr', // Marathi ISO 639-1 code
        'response_format': 'json',
        'temperature': '0',
      });

      final response = await _dio.post(
        '/audio/transcriptions',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        final text = response.data['text'] as String? ?? '';
        if (text.trim().isEmpty) {
          throw GroqException('Transcription returned empty text.');
        }
        return text.trim();
      } else {
        throw GroqException(
          'Whisper API error: ${response.statusCode} — ${response.data}',
        );
      }
    } on DioException catch (e) {
      throw GroqException(_parseDioError(e));
    }
  }

  // ── Step 2: Generate Formal Letter via LLaMA ─────────────
  /// Takes the Marathi transcript and returns a formatted
  /// English Government letter.
  Future<String> generateLetter(String transcript) async {
    try {
      final payload = {
        'model': AppConstants.groqLlmModel,
        'messages': [
          {'role': 'system', 'content': AppConstants.letterSystemPrompt},
          {
            'role': 'user',
            'content':
                'Please convert the following spoken Marathi instructions into a formal Government letter:\n\n"$transcript"',
          },
        ],
        'temperature': 0.3,
        'max_tokens': 2048,
        'top_p': 0.9,
      };

      final response = await _dio.post(
        '/chat/completions',
        data: payload,
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List<dynamic>;
        if (choices.isEmpty) {
          throw GroqException('LLM returned no choices.');
        }
        final content = choices[0]['message']['content'] as String? ?? '';
        if (content.trim().isEmpty) {
          throw GroqException('LLM returned empty letter content.');
        }
        return content.trim();
      } else {
        throw GroqException(
          'LLM API error: ${response.statusCode} — ${response.data}',
        );
      }
    } on DioException catch (e) {
      throw GroqException(_parseDioError(e));
    }
  }

  // ── Step 3: Refine / Edit Letter ──────────────────────────
  /// Sends the existing letter + user instruction to LLaMA
  /// for targeted refinement.
  Future<String> refineLetter({
    required String currentLetter,
    required String instruction,
  }) async {
    try {
      final payload = {
        'model': AppConstants.groqLlmModel,
        'messages': [
          {'role': 'system', 'content': AppConstants.letterSystemPrompt},
          {
            'role': 'user',
            'content': 'Here is the current letter:\n\n$currentLetter',
          },
          {'role': 'assistant', 'content': currentLetter},
          {
            'role': 'user',
            'content':
                'Please refine the letter with the following instruction: $instruction',
          },
        ],
        'temperature': 0.2,
        'max_tokens': 2048,
      };

      final response = await _dio.post(
        '/chat/completions',
        data: payload,
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List<dynamic>;
        return (choices[0]['message']['content'] as String? ?? '').trim();
      } else {
        throw GroqException('Refine API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw GroqException(_parseDioError(e));
    }
  }

  // ── OCR Text → Letter ─────────────────────────────────────
  /// Converts raw OCR-scanned text into a formatted letter.
  Future<String> formatScannedText(String rawText) async {
    try {
      final payload = {
        'model': AppConstants.groqLlmModel,
        'messages': [
          {'role': 'system', 'content': AppConstants.letterSystemPrompt},
          {
            'role': 'user',
            'content':
                'The following text was scanned from a physical document. Please reformat it as a proper Government letter, correcting any OCR errors:\n\n"$rawText"',
          },
        ],
        'temperature': 0.2,
        'max_tokens': 2048,
      };

      final response = await _dio.post(
        '/chat/completions',
        data: payload,
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List<dynamic>;
        return (choices[0]['message']['content'] as String? ?? '').trim();
      } else {
        throw GroqException('Format API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw GroqException(_parseDioError(e));
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  String _parseDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error']['message'] as String? ??
            e.message ??
            'Unknown error';
      }
      return 'HTTP ${e.response!.statusCode}: ${e.message}';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out. Check your internet connection.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server took too long to respond. Please try again.';
    }
    return e.message ?? 'Network error occurred.';
  }
}

// ── Custom Exception ──────────────────────────────────────────
class GroqException implements Exception {
  final String message;
  const GroqException(this.message);

  @override
  String toString() => 'GroqException: $message';
}
