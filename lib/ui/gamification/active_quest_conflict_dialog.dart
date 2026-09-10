import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/active_quest.dart';

Future<bool> showActiveQuestConflictDialog(
  BuildContext context, {
  required ActiveQuestSummary activeQuest,
  String? integrityWarning,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            'Another Journey Is Active',
            style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40)),
          ),
          content: Text(
            'You are currently exploring “${activeQuest.questTitle}” at '
            '${activeQuest.studioName}. Complete that journey before starting '
            'a new one.${integrityWarning == null ? '' : '\n\n$integrityWarning'}',
            style: GoogleFonts.plusJakartaSans(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
              ),
              child: const Text('Continue Active Quest'),
            ),
          ],
        ),
      ) ??
      false;
}
