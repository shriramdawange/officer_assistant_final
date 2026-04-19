// ============================================================
// models/letter_model.dart
// ============================================================

import 'package:intl/intl.dart';

class LetterModel {
  final String id;
  final String userId;
  final String transcript; // Original Marathi transcript
  final String letterContent; // Generated English letter
  final String subject; // Extracted subject line
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'draft' | 'final' | 'exported'

  const LetterModel({
    required this.id,
    required this.userId,
    required this.transcript,
    required this.letterContent,
    required this.subject,
    required this.createdAt,
    this.updatedAt,
    this.status = 'draft',
  });

  // ── Factory from Supabase JSON ────────────────────────────
  factory LetterModel.fromJson(Map<String, dynamic> json) {
    return LetterModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transcript: json['transcript'] as String? ?? '',
      letterContent: json['letter_content'] as String,
      subject: json['subject'] as String? ?? 'Untitled Letter',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
    );
  }

  // ── To Supabase JSON ──────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'transcript': transcript,
      'letter_content': letterContent,
      'subject': subject,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'status': status,
    };
  }

  // ── CopyWith ──────────────────────────────────────────────
  LetterModel copyWith({
    String? id,
    String? userId,
    String? transcript,
    String? letterContent,
    String? subject,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return LetterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transcript: transcript ?? this.transcript,
      letterContent: letterContent ?? this.letterContent,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  String get formattedDate =>
      DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

  String get shortDate => DateFormat('dd MMM yyyy').format(createdAt);

  String get preview {
    final lines = letterContent.split('\n');
    final bodyStart = lines.indexWhere(
      (l) => l.trim().startsWith('1.') || l.trim().startsWith('Sir'),
    );
    if (bodyStart != -1 && bodyStart < lines.length) {
      return lines[bodyStart].trim().length > 120
          ? '${lines[bodyStart].trim().substring(0, 120)}...'
          : lines[bodyStart].trim();
    }
    return letterContent.length > 120
        ? '${letterContent.substring(0, 120)}...'
        : letterContent;
  }

  @override
  String toString() =>
      'LetterModel(id: $id, subject: $subject, status: $status)';
}
