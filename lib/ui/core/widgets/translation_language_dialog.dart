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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE0F2FE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.g_translate_rounded,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF0284C7),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Live Page Translation',
                            softWrap: true,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 20,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select language to translate all craft bios, quest instructions, and heritage lore in real-time.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),

              ..._languages.map((lang) {
                final bool isSelected = _selectedCode == lang['code'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40).withValues(alpha: 0.08))
                        : (isDark ? const Color(0xFF041412) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))
                          : (isDark ? const Color(0xFF1E3A34) : Colors.black.withValues(alpha: 0.08)),
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
                        color: isSelected
                            ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                    subtitle: Text(
                      lang['subtitle']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _applyTranslation,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                    foregroundColor: isDark ? const Color(0xFFFFD54F) : Colors.white,
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
      ),
    );
  }
}