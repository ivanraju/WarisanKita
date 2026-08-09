import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TranslationLanguageDialog extends StatefulWidget {
  final String currentLanguage;
  final Function(String newLangCode, String newLangName) onLanguageChanged;

  const TranslationLanguageDialog({
    super.key,
    this.currentLanguage = 'EN',
    required this.onLanguageChanged,
  });

  @override
  State<TranslationLanguageDialog> createState() => _TranslationLanguageDialogState();
}

class _TranslationLanguageDialogState extends State<TranslationLanguageDialog> {
  late String _selectedCode;

  final List<Map<String, String>> _languages = const [
    {
      'code': 'EN',
      'name': 'English (United States)',
      'flag': '🇬🇧',
      'subtitle': 'Original English Content',
    },
    {
      'code': 'BM',
      'name': 'Bahasa Melayu (Malaysia)',
      'flag': '🇲🇾',
      'subtitle': 'Kandungan Bahasa Melayu',
    },
    {
      'code': 'ZH',
      'name': 'Mandarin (中文 - 简体)',
      'flag': '🇨🇳',
      'subtitle': '简体中文实时翻译',
    },
    {
      'code': 'JA',
      'name': 'Japanese (日本語)',
      'flag': '🇯🇵',
      'subtitle': '日本語リアルタイム翻訳',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.currentLanguage;
  }

  void _applyTranslation() {
    final selectedLang = _languages.firstWhere((l) => l['code'] == _selectedCode);
    widget.onLanguageChanged(selectedLang['code']!, selectedLang['name']!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🌐 Live Page Translated to ${selectedLang['name']}!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.g_translate_rounded, color: Color(0xFF0284C7), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Live Page Translation',
                      style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select language to translate all craft bios, quest instructions, and heritage lore in real-time.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            ..._languages.map((lang) {
              final bool isSelected = _selectedCode == lang['code'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF004D40).withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF004D40) : Colors.black.withOpacity(0.08),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: ListTile(
                  onTap: () => setState(() => _selectedCode = lang['code']!),
                  leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    lang['name']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF004D40) : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    lang['subtitle']!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF004D40))
                      : const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey),
                ),
              );
            }),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _applyTranslation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.translate_rounded, size: 18),
                label: const Text('APPLY LIVE PAGE TRANSLATION'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
