/// Production validator for user profiles, artisan edit forms,
/// contact details, and account security.
class ProfileValidator {
  static const Set<String> _disallowedUsernames = {
    'admin',
    'administrator',
    'system',
    'root',
    'support',
    'moderator',
    'warisankita',
    'warisan_kita',
    'null',
    'undefined',
    'test',
    'testing',
    'anonymous',
  };

  static const Set<String> _disallowedStudioNames = {
    'none',
    'na',
    'n/a',
    'nil',
    'null',
    'test',
    'testing',
    'dummy',
    'asdf',
    'studio',
    'artisan',
    'sample',
    'empty',
    'undefined',
    'tiada',
  };

  static const List<String> supportedStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Putrajaya',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  static const List<String> supportedCraftCategories = [
    'Pottery & Ceramics',
    'Batik Weaving',
    'Wood Carving',
    'Songket Weaving',
    'Pewter Craft',
    'Handicraft & Heritage',
    'Wau & Kite Making',
    'Metalwork & Kris',
    'Heritage Food',
    'Wayang Kulit & Puppetry',
    'Rattan & Bamboo Craft',
  ];

  /// Validates an account username or handle.
  /// Allowed: 3-20 characters, alphanumeric + underscore, must contain at least 1 letter.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username handle cannot be empty';
    }

    final clean = value.trim().replaceAll('@', '');
    if (clean.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (clean.length > 20) {
      return 'Username cannot exceed 20 characters';
    }

    final validChars = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validChars.hasMatch(clean)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(clean)) {
      return 'Username must contain at least one letter';
    }

    if (_disallowedUsernames.contains(clean.toLowerCase())) {
      return 'This username is reserved and cannot be used';
    }

    return null;
  }

  /// Validates a user's full name.
  /// Allowed: 2-50 characters, letters, spaces, hyphens, dots, apostrophes.
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name cannot be empty';
    }

    final clean = value.trim();
    if (clean.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (clean.length > 50) {
      return 'Full name cannot exceed 50 characters';
    }

    final validChars = RegExp(r"^[a-zA-Z\s\.\'\-]+$");
    if (!validChars.hasMatch(clean)) {
      return 'Full name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates an Artisan Studio name.
  /// Allowed: 3-60 characters, not a placeholder.
  static String? validateStudioName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Studio name cannot be empty';
    }

    final clean = value.trim();
    if (clean.length < 3) {
      return 'Studio name must be at least 3 characters';
    }
    if (clean.length > 60) {
      return 'Studio name cannot exceed 60 characters';
    }

    if (_disallowedStudioNames.contains(clean.toLowerCase())) {
      return 'Please enter a genuine, recognizable studio or workshop name';
    }

    return null;
  }

  /// Validates a phone number (Malaysian or international standard).
  static String? validatePhone(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Phone number is required' : null;
    }

    final clean = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    final digitsOnly = clean.replaceAll(RegExp(r'\D'), '');

    // Check dummy sequences (e.g. 00000000, 11111111, 12345678)
    if (RegExp(r'^(\d)\1{6,}$').hasMatch(digitsOnly) ||
        digitsOnly == '12345678' ||
        digitsOnly == '87654321') {
      return 'Please provide a valid, active contact phone number';
    }

    // Malaysian mobile or landline:
    // +601XXXXXXXX, 601XXXXXXXX, 01XXXXXXXX (9-11 digits)
    // +603XXXXXXXX, 603XXXXXXXX, 03XXXXXXXX, 04, 05, 06, 07, 08, 09 (9-10 digits)
    final isMalaysian = RegExp(r'^(?:\+?60|0)[1-9]\d{7,9}$').hasMatch(clean);

    // International E.164: + followed by 8 to 15 digits
    final isInternational = RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(clean);

    if (!isMalaysian && !isInternational) {
      return 'Invalid phone format (e.g. +60 12-345 6789 or 012-3456789)';
    }

    return null;
  }

  /// Normalizes a phone number to standard format (e.g. +60123456789 for Malaysian numbers).
  static String normalizePhone(String? phone) {
    if (phone == null) return '';
    final clean = phone.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (clean.isEmpty) return '';

    if (clean.startsWith('+60')) {
      return clean;
    } else if (clean.startsWith('60')) {
      return '+$clean';
    } else if (clean.startsWith('0')) {
      return '+60${clean.substring(1)}';
    } else if (clean.startsWith('+')) {
      return clean;
    }
    return clean;
  }

  /// Extracts digits only from a phone number string.
  static String phoneDigitsOnly(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Compares two phone numbers to see if they refer to the same contact line.
  static bool arePhonesEqual(String? a, String? b) {
    if (a == null || b == null) return false;
    final normA = normalizePhone(a);
    final normB = normalizePhone(b);
    if (normA.isNotEmpty && normA == normB) return true;

    final digitsA = phoneDigitsOnly(a);
    final digitsB = phoneDigitsOnly(b);
    if (digitsA.isEmpty || digitsB.isEmpty) return false;

    if (digitsA == digitsB) return true;

    final suffixA = digitsA.startsWith('60')
        ? digitsA.substring(2)
        : (digitsA.startsWith('0') ? digitsA.substring(1) : digitsA);
    final suffixB = digitsB.startsWith('60')
        ? digitsB.substring(2)
        : (digitsB.startsWith('0') ? digitsB.substring(1) : digitsB);
    return suffixA.isNotEmpty && suffixA == suffixB;
  }

  /// Validates a biography or description.
  static String? validateBio(
    String? value, {
    bool isRequired = false,
    int minLength = 10,
    int maxLength = 1000,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter a biography or craft story' : null;
    }

    final clean = value.trim();
    if (clean.length < minLength) {
      return 'Bio must be at least $minLength characters';
    }
    if (clean.length > maxLength) {
      return 'Bio cannot exceed $maxLength characters';
    }

    return null;
  }

  /// Validates years of craft experience.
  static String? validateExperience(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter your craft experience (e.g. 15)' : null;
    }

    final clean = value.trim();
    final parsed = int.tryParse(clean);
    if (parsed != null) {
      if (parsed < 1 || parsed > 99) {
        return 'Years of experience must be between 1 and 99';
      }
      return null;
    }

    if (clean.length > 60) {
      return 'Experience description cannot exceed 60 characters';
    }

    return null;
  }

  /// Validates a craft category.
  static String? validateCraftCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select or specify a craft category';
    }
    if (value.trim().length < 2) {
      return 'Craft category is too short';
    }
    return null;
  }

  /// Validates a Malaysian state.
  static String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a Malaysian state';
    }
    if (!supportedStates.contains(value.trim())) {
      return 'Please select a valid Malaysian state';
    }
    return null;
  }

  /// Validates an email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address cannot be empty';
    }

    final clean = value.trim();
    if (clean.contains('+')) {
      return "Email aliases using '+' are not supported";
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(clean)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a password.
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password cannot be empty';
    }

    final clean = value.trim();
    if (clean.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(clean)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(clean)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validates a confirm password field against the original password.
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (value.trim() != originalPassword?.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a tool, material, or tag input.
  static String? validateTag(String? value, [List<String> existingTags = const []]) {
    if (value == null || value.trim().isEmpty) {
      return 'Tool or material name cannot be empty';
    }

    final clean = value.trim();
    if (clean.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (clean.length > 40) {
      return 'Name cannot exceed 40 characters';
    }

    final isDuplicate = existingTags.any(
      (t) => t.trim().toLowerCase() == clean.toLowerCase(),
    );
    if (isDuplicate) {
      return 'This tool or material is already added';
    }

    return null;
  }

  /// Validates that a string is not empty or whitespace only.
  static String? validateNotEmpty(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }
}
