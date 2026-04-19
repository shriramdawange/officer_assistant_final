// ============================================================
// core/constants.dart
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
  // Set these via environment variables or a local secrets file (not committed)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
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
