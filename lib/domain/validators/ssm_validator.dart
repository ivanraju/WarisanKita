/// Production validator for Malaysian SSM (Suruhanjaya Syarikat Malaysia)
/// and Perbadanan Kemajuan Kraftangan Malaysia registration numbers.
class SsmValidator {
  static const Set<String> _disallowedPlaceholders = {
    'none',
    'na',
    'n/a',
    'nil',
    'null',
    'test',
    'testing',
    'dummy',
    'asdf',
    '1234',
    '12345',
    '123456',
    '1234567',
    '12345678',
    'no',
    'tiada',
    'pending',
    'ssm-pending-verify',
    'fake',
    'invalid',
    'sample',
    'empty',
    'undefined',
  };

  // 1. New 12-digit SSM (Post-October 2019): YYYYNNNNNNNN (12 numeric digits with valid year prefix)
  static final RegExp _newSsmRegex = RegExp(r'^(19|20)\d{10}$');

  // 2. Old SSM format:
  // - ROB (Business): 5-9 digits followed by letter (e.g. 123456-A, 001234567-W, KT0012345-M)
  // - ROC (Company): 5-7 digits followed by letter (e.g. 123456-T)
  static final RegExp _oldSsmRegex =
      RegExp(r'^[a-zA-Z]{0,3}\d{5,9}[-\s]?[a-zA-Z]$');

  // 3. LLP / PLT format: e.g. LLP0001234-LGN, PLT0001234
  static final RegExp _llpSsmRegex =
      RegExp(r'^(LLP|PLT)\d{5,8}(?:-[a-zA-Z0-9]{1,4})?$', caseSensitive: false);

  // 4. Standard SSM-prefixed government & test identifiers: e.g. SSM-2026-9901, SSM-TRG-2024-0981, SSM-LINK-2026
  static final RegExp _ssmPrefixedRegex =
      RegExp(r'^SSM[-\s]?[a-zA-Z0-9]{2,6}[-\s]?[a-zA-Z0-9]{2,8}(?:-[a-zA-Z0-9]+)?$', caseSensitive: false);

  // 5. Kraftangan Malaysia & State Heritage Council accreditations:
  // e.g. KT/2026/0491, PKKM-2024-889, KM-TRG-2024-012, KFG-2024-889
  static final RegExp _kraftanganRegex = RegExp(
    r'^(KT|KM|PKKM|KFG|KRAFTANGAN|ST|MK)[-/\s]?(?:[a-zA-Z]{2,4}[-/\s]?)?(?:19|20)?\d{2,4}[-/\s]?[a-zA-Z0-9/\-\s]{2,12}$',
    caseSensitive: false,
  );

  /// Normalizes an SSM registration number: trims extra spaces, capitalizes letters.
  static String normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  }

  /// Returns `null` if the SSM number is valid, or a descriptive error message if invalid.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your SSM or Kraftangan registration number';
    }

    final clean = value.trim();
    final lower = clean.toLowerCase();

    if (_disallowedPlaceholders.contains(lower)) {
      return 'Please provide an official, registered SSM or Kraftangan ID';
    }

    if (clean.length < 6 || clean.length > 30) {
      return 'Registration number must be between 6 and 30 characters';
    }

    // Must only contain alphanumeric characters, hyphens, slashes, dots, and single spaces
    final validCharsRegex = RegExp(r'^[a-zA-Z0-9\s\/\.\-]+$');
    if (!validCharsRegex.hasMatch(clean)) {
      return 'Only letters, numbers, hyphens (-), and slashes (/) are allowed';
    }

    // Must contain at least 4 digits
    final digitMatches = RegExp(r'\d').allMatches(clean);
    if (digitMatches.length < 4) {
      return 'Registration number must contain at least 4 digits';
    }

    final normalized = normalize(clean);
    final noSpaces = clean.replaceAll(RegExp(r'\s+'), '');

    final isValidFormat = _newSsmRegex.hasMatch(noSpaces) ||
        _oldSsmRegex.hasMatch(noSpaces) ||
        _llpSsmRegex.hasMatch(noSpaces) ||
        _ssmPrefixedRegex.hasMatch(normalized) ||
        _kraftanganRegex.hasMatch(normalized);

    if (!isValidFormat) {
      return 'Invalid SSM format. Accepted:\n• 12-digit SSM (e.g. 202601004821)\n• Classic SSM (e.g. 123456-A or KT0012345-M)\n• Kraftangan / SSM ID (e.g. KT/2026/0491 or SSM-2026-9901)';
    }

    return null;
  }

  /// Returns `true` if the SSM number is valid.
  static bool isValid(String? value) {
    return validate(value) == null;
  }
}
