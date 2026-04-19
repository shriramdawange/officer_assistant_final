// ============================================================
// services/pdf_service.dart
// Generates and prints/shares Government Letter PDFs
// ============================================================

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/letter_model.dart';
import '../models/user_profile.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  // ── Brand Colors ──────────────────────────────────────────
  static const PdfColor _navyBlue = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor _gold = PdfColor.fromInt(0xFFFFD700);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1A1A2E);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _divider = PdfColor.fromInt(0xFFE0E0E0);

  // ── Generate PDF Bytes ────────────────────────────────────
  Future<Uint8List> generateLetterPdf({
    required LetterModel letter,
    required UserProfile profile,
  }) async {
    final pdf = pw.Document(
      title: letter.subject,
      author: profile.fullName,
      creator: 'Rajpatra AI — Gen Solution',
    );

    // Load fonts
    final regularFont = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final italicFont = await PdfGoogleFonts.interItalic();
    final headingFont = await PdfGoogleFonts.playfairDisplayBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 60, vertical: 50),
        build: (context) => [
          // ── Government Header ──────────────────────────
          _buildHeader(boldFont, headingFont),
          pw.SizedBox(height: 16),

          // ── Divider ────────────────────────────────────
          pw.Divider(color: _navyBlue, thickness: 2),
          pw.SizedBox(height: 4),
          pw.Divider(color: _gold, thickness: 1),
          pw.SizedBox(height: 20),

          // ── Letter Meta Block ──────────────────────────
          _buildMetaBlock(letter, profile, regularFont, boldFont),
          pw.SizedBox(height: 24),

          // ── Letter Body ────────────────────────────────
          _buildLetterBody(
            letter.letterContent,
            regularFont,
            boldFont,
            italicFont,
          ),
          pw.SizedBox(height: 40),
        ],
        footer: (context) => _buildFooter(context, regularFont, italicFont),
      ),
    );

    return pdf.save();
  }

  // ── Print / Share ─────────────────────────────────────────
  Future<void> printLetter({
    required LetterModel letter,
    required UserProfile profile,
  }) async {
    final bytes = await generateLetterPdf(letter: letter, profile: profile);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${letter.subject}.pdf',
    );
  }

  Future<void> shareLetter({
    required LetterModel letter,
    required UserProfile profile,
  }) async {
    final bytes = await generateLetterPdf(letter: letter, profile: profile);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${letter.subject.replaceAll(' ', '_')}.pdf',
    );
  }

  // ── Widget Builders ───────────────────────────────────────

  pw.Widget _buildHeader(pw.Font boldFont, pw.Font headingFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'GOVERNMENT OF MAHARASHTRA',
          style: pw.TextStyle(
            font: headingFont,
            fontSize: 16,
            color: _navyBlue,
            letterSpacing: 2,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'महाराष्ट्र शासन',
          style: pw.TextStyle(font: boldFont, fontSize: 13, color: _navyBlue),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _navyBlue,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'OFFICIAL CORRESPONDENCE',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 9,
              color: PdfColors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMetaBlock(
    LetterModel letter,
    UserProfile profile,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final dateStr = DateFormat('dd MMMM yyyy').format(letter.createdAt);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _metaRow('From:', profile.fullName, regularFont, boldFont),
              _metaRow(
                'Designation:',
                profile.designation,
                regularFont,
                boldFont,
              ),
              _metaRow(
                'Department:',
                profile.department,
                regularFont,
                boldFont,
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _metaRow('Date:', dateStr, regularFont, boldFont),
            _metaRow(
              'Status:',
              letter.status.toUpperCase(),
              regularFont,
              boldFont,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _metaRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label ',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: _textMuted,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildLetterBody(
    String content,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
  ) {
    final lines = content.split('\n');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        // Subject line
        if (trimmed.startsWith('Subject:') || trimmed.startsWith('SUBJECT:')) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              trimmed,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 11,
                color: _navyBlue,
              ),
            ),
          );
        }

        // Reference line
        if (trimmed.startsWith('Reference') ||
            trimmed.startsWith('Ref.') ||
            trimmed.startsWith('REF/')) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              trimmed,
              style: pw.TextStyle(
                font: italicFont,
                fontSize: 10,
                color: _textMuted,
              ),
            ),
          );
        }

        // Salutation / closing
        if (trimmed == 'Sir/Madam,' ||
            trimmed.startsWith('Yours faithfully') ||
            trimmed.startsWith('Yours sincerely')) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text(
              trimmed,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 11,
                color: _textDark,
              ),
            ),
          );
        }

        // Empty line
        if (trimmed.isEmpty) {
          return pw.SizedBox(height: 8);
        }

        // Normal body text
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            trimmed,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 11,
              color: _textDark,
              lineSpacing: 4,
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildFooter(
    pw.Context context,
    pw.Font regularFont,
    pw.Font italicFont,
  ) {
    return pw.Column(
      children: [
        pw.Divider(color: _divider, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Rajpatra AI — Gen Solution',
              style: pw.TextStyle(
                font: italicFont,
                fontSize: 8,
                color: _textMuted,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 8,
                color: _textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
