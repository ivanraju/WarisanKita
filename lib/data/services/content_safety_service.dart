class ContentSafetyResult {
  final bool isBlocked;
  final bool isAutoFlagged;
  final List<String> detectedWords;
  final String? blockReason;
  final String? flagReason;

  const ContentSafetyResult({
    this.isBlocked = false,
    this.isAutoFlagged = false,
    this.detectedWords = const [],
    this.blockReason,
    this.flagReason,
  });

  bool get isClean => !isBlocked && !isAutoFlagged;
}

class ContentSafetyService {
  // Severe prohibited keywords (Zero tolerance - strictly blocks creation)
  static final Set<String> _severeBlockedKeywords = {
    // English profanity / hate slurs / adult
    'fuck',
    'fucking',
    'fucker',
    'bitch',
    'asshole',
    'bastard',
    'slut',
    'whore',
    'nigger',
    'nigga',
    'dick',
    'pussy',
    'cunt',
    'porn',
    'porno',
    'nude',
    'naked',
    'casino',
    'gambling',
    'slotgacor',
    'judi',

    // Malay / Indonesian profanity & slurs
    'babi',
    'sial',
    'pukimak',
    'pantek',
    'lancau',
    'puki',
    'butoh',
    'palat',
    'kontol',
    'memek',
    'bodoh',
    'bangsat',
    'anjing',
    'hanjing',
    'celaka',
    'kimak',
    'cibai',
    'sohai',
  };

  // Sensitive terms that trigger Auto-Flagging for Admin review
  static final Set<String> _autoFlagKeywords = {
    'scam',
    'scammer',
    'penipu',
    'fake',
    'tiruan',
    'counterfeit',
    'cheat',
    'cheater',
    'boycott',
    'boikot',
    'racist',
    'rasis',
    'haram',
    'illegal',
    'stolen',
  };

  /// Evaluates text using exact token matching to prevent false positive substring errors
  static ContentSafetyResult evaluate({required String title, String body = ''}) {
    final rawText = '$title $body'.toLowerCase();
    
    // 1. Tokenize text into separate words
    final tokens = rawText
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toSet();

    // 2. Also extract de-leeted tokens (e.g. f*ck -> fuck, b@bi -> babi)
    final wordsInRaw = rawText.split(RegExp(r'\s+'));
    for (final rawWord in wordsInRaw) {
      final deLeeted = rawWord
          .replaceAll('@', 'a')
          .replaceAll('\$', 's')
          .replaceAll('0', 'o')
          .replaceAll('1', 'i')
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (deLeeted.isNotEmpty) {
        tokens.add(deLeeted);
      }
    }

    final List<String> blockedMatches = [];
    final List<String> flagMatches = [];

    // Check severe blocked keywords (Exact token match)
    for (final word in _severeBlockedKeywords) {
      if (tokens.contains(word)) {
        if (!blockedMatches.contains(word)) {
          blockedMatches.add(word);
        }
      }
    }

    if (blockedMatches.isNotEmpty) {
      return ContentSafetyResult(
        isBlocked: true,
        detectedWords: blockedMatches,
        blockReason: 'Your post contains prohibited or offensive language (${blockedMatches.join(", ")}). Please follow community guidelines.',
      );
    }

    // Check auto-flag keywords (Exact token match)
    for (final word in _autoFlagKeywords) {
      if (tokens.contains(word)) {
        if (!flagMatches.contains(word)) {
          flagMatches.add(word);
        }
      }
    }

    if (flagMatches.isNotEmpty) {
      return ContentSafetyResult(
        isAutoFlagged: true,
        detectedWords: flagMatches,
        flagReason: 'Automated Safety Flag: Sensitive terms detected (${flagMatches.join(", ")})',
      );
    }

    return const ContentSafetyResult();
  }
}
