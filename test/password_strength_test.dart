import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/ui/auth/widgets/password_strength_meter.dart';

void main() {
  group('Password Strength Evaluator Tests', () {
    test('Empty password returns weak and score 0', () {
      final res = PasswordStrengthHelper.evaluate('');
      expect(res.score, 0);
      expect(res.hasMinLength, false);
      expect(res.hasUppercase, false);
      expect(res.hasLowercase, false);
      expect(res.hasDigits, false);
      expect(res.hasSpecialChar, false);
    });

    test('Short password (< 8 chars) is weak', () {
      final res = PasswordStrengthHelper.evaluate('Short1!');
      expect(res.hasMinLength, false);
      expect(res.score < 4, true);
    });

    test('8+ chars lowercase only is Fair', () {
      final res = PasswordStrengthHelper.evaluate('passwords');
      expect(res.hasMinLength, true);
      expect(res.hasLowercase, true);
      expect(res.hasUppercase, false);
      expect(res.hasDigits, false);
      expect(res.hasSpecialChar, false);
      expect(res.score, 1);
      expect(res.label, 'Weak');
    });

    test('8+ chars with Upper, Lower, and Digits is Good', () {
      final res = PasswordStrengthHelper.evaluate('Password123');
      expect(res.hasMinLength, true);
      expect(res.hasUppercase, true);
      expect(res.hasLowercase, true);
      expect(res.hasDigits, true);
      expect(res.hasSpecialChar, false);
      expect(res.score, 3);
      expect(res.label, 'Good');
    });

    test('8+ chars with Upper, Lower, Digits, and Special Symbol is Strong', () {
      final res = PasswordStrengthHelper.evaluate('Heritage@2026!');
      expect(res.hasMinLength, true);
      expect(res.hasUppercase, true);
      expect(res.hasLowercase, true);
      expect(res.hasDigits, true);
      expect(res.hasSpecialChar, true);
      expect(res.score, 4);
      expect(res.label, 'Strong');
      expect(res.isStrong, true);
      expect(res.isValid, true);
    });
  });
}
