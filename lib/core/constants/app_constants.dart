// ============================================================
// core/constants/app_constants.dart
// Rajpatra AI — Officer Assistant
// Gen Solution
// ============================================================

class AppConstants {
  AppConstants._();

  // ── App Identity ──────────────────────────────────────────
  static const String appName = 'Rajpatra AI';
  static const String appTagline = "Officer's Digital Assistant";
  static const String companyName = 'Gen Solution';

  // ── Supabase ──────────────────────────────────────────────
  // Injected at build time via --dart-define (CI/CD)
  // For local dev, run:
  //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wkzbbklgnxrzkanfrclm.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndremJia2xnbnhyemthbmZyY2xtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1NTM4MzUsImV4cCI6MjA5MjEyOTgzNX0'
        '.RZlnwNjXJju3L6lEkV-h9z8A1f-guv1d5st4ogdwxho',
  );

  // ── Groq API ──────────────────────────────────────────────
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqWhisperModel = 'whisper-large-v3';
  static const String groqLlmModel = 'llama-3.1-70b-versatile';

  // ── Supabase Table Names ──────────────────────────────────
  static const String lettersTable = 'letters';
  static const String profilesTable = 'profiles';
  static const String officerNotesTable = 'officer_notes'; // new table

  // ── System Prompt ─────────────────────────────────────────
  static const String letterSystemPrompt = '''
You are a senior Government Personal Assistant (PA) for the Government of Maharashtra, India.
Your task is to convert spoken or informal instructions into a perfectly formatted, formal English Government Letter.

STRICT FORMATTING RULES:
1. Start with the official letter header block:
   - From: [Officer Name & Designation]
   - To: [Recipient Name & Designation]
   - Subject: [Clear, concise subject line in CAPITALS]
   - Reference No.: [REF/YYYY/DEPT/XXXX] — use a placeholder
   - Date: [Current Date]

2. Use formal salutation: "Sir/Madam,"
3. Body paragraphs must be numbered (1., 2., 3.)
4. Use passive voice and formal administrative language
5. Close with: "Yours faithfully," followed by signature block
6. Add "Copy to:" section if relevant parties are mentioned

OUTPUT: Return ONLY the formatted letter text. No explanations, no markdown, no preamble.
''';

  // ── UI Strings ────────────────────────────────────────────
  static const String greetingPrefix = 'Namaste,';
  static const String recordingHint = 'Tap the mic and speak in Marathi';
  static const String processingText = 'Drafting your letter...';
  static const String exportPdfText = 'Export to PDF';
  static const String refineLetter = 'Refine Letter';
  static const String scanDocument = 'Scan Document';
  static const String viewHistory = 'View History';
  static const String newLetter = 'New Letter';
}
