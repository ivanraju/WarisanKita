import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class PasswordStrengthResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigits;
  final bool hasSpecialChar;
  final int score;
  final String label;
  final Color color;
  final double percent;

  const PasswordStrengthResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigits,
    required this.hasSpecialChar,
    required this.score,
    required this.label,
    required this.color,
    required this.percent,
  });

  bool get isValid => hasMinLength;
  bool get isStrong => hasMinLength && hasUppercase && hasLowercase && hasDigits && hasSpecialChar;
}

class PasswordStrengthHelper {
  static PasswordStrengthResult evaluate(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\\[\]~`/]').hasMatch(password);

    int score = 0;
    if (password.isNotEmpty) {
      if (hasMinLength) score++;
      if (hasUppercase && hasLowercase) score++;
      if (hasDigits) score++;
      if (hasSpecialChar) score++;
    }

    String label;
    Color color;
    double percent;

    switch (score) {
      case 4:
        label = 'Strong';
        color = const Color(0xFF10B981); // Emerald
        percent = 1.0;
        break;
      case 3:
        label = 'Good';
        color = const Color(0xFFF59E0B); // Amber
        percent = 0.75;
        break;
      case 2:
        label = 'Fair';
        color = const Color(0xFFF97316); // Orange
        percent = 0.50;
        break;
      case 1:
      default:
        label = password.isEmpty ? 'Enter password' : 'Weak';
        color = password.isEmpty ? Colors.grey : const Color(0xFFEF4444); // Red
        percent = password.isEmpty ? 0.0 : 0.25;
        break;
    }

    return PasswordStrengthResult(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasDigits: hasDigits,
      hasSpecialChar: hasSpecialChar,
      score: score,
      label: label,
      color: color,
      percent: percent,
    );
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final bool showChecklist;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showChecklist = true,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final result = PasswordStrengthHelper.evaluate(password);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    LanguageViewModel? langVM;
    try {
      langVM = context.watch<LanguageViewModel>();
    } catch (_) {}
    String tr(String text) => langVM?.translate(text) ?? text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('Password Strength'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: result.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tr(result.label),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: result.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 4-Segment Visual Bar
        Row(
          children: List.generate(4, (index) {
            final isFilled = (index + 1) <= result.score;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isFilled ? result.color : (isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (showChecklist) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildCriterionChip(context, tr('8+ characters'), result.hasMinLength),
              _buildCriterionChip(context, tr('Upper & lowercase'), result.hasUppercase && result.hasLowercase),
              _buildCriterionChip(context, tr('Number (0-9)'), result.hasDigits),
              _buildCriterionChip(context, tr('Symbol (!@#\$)'), result.hasSpecialChar),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCriterionChip(BuildContext context, String text, bool isMet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMet
        ? (isDark ? const Color(0xFF063529) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF041412) : const Color(0xFFF1F5F9));
    final borderColor = isMet
        ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
        : (isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0));
    final textColor = isMet
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
        : (isDark ? Colors.white60 : const Color(0xFF64748B));
    final iconColor = isMet
        ? const Color(0xFF059669)
        : (isDark ? Colors.white38 : const Color(0xFF94A3B8));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 12,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isMet ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
