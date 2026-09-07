import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyMoodCheckinDialog extends StatefulWidget {
  final Function(String selectedMood) onMoodSelected;
  final VoidCallback? onHide;

  const DailyMoodCheckinDialog({
    super.key,
    required this.onMoodSelected,
    this.onHide,
  });

  @override
  State<DailyMoodCheckinDialog> createState() => _DailyMoodCheckinDialogState();
}

class _DailyMoodCheckinDialogState extends State<DailyMoodCheckinDialog> {
  String? _selectedMood;
  bool _dontShowToday = false;

  final List<Map<String, dynamic>> _moodOptions = const [
    {
      'title': '🏺 Hands-on Pottery & Clay',
      'subtitle': 'Spin clay wheels and kiln labu sayong vessels',
      'category': 'Pottery & Ceramics',
    },
    {
      'title': '🌿 Natural Indigo Batik',
      'subtitle': 'Draw canting wax motifs and dye silk fabric',
      'category': 'Batik Weaving',
    },
    {
      'title': '🧶 Royal Gold Songket Weaving',
      'subtitle': 'Observe master weavers loom metallic threads',
      'category': 'Songket Weaving',
    },
    {
      'title': '🪵 Historic Timber Woodcarving',
      'subtitle': 'Explore intricate hardwood relief panels',
      'category': 'Wood Carving',
    },
  ];

  void _submitCheckin() {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select what craft interests you today!'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Grant Daily Streak Checkin Bonus (+50 XP)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔥 Daily Check-in Claimed! Earned +50 Streak XP!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    widget.onMoodSelected(_selectedMood!);
    Navigator.of(context).pop();
  }

  void _handleHide() {
    if (widget.onHide != null) {
      widget.onHide!();
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.visibility_off_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Daily Heritage Challenges hidden for this session.'),
          ],
        ),
        backgroundColor: const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.wb_sunny_rounded, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Daily Heritage Check-in',
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
                'What craft heritage would you like to explore today?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),

              const SizedBox(height: 16),

              // Options List
              ..._moodOptions.map((opt) {
                final bool isSelected = _selectedMood == opt['category'];

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
                    onTap: () => setState(() => _selectedMood = opt['category']),
                    title: Text(
                      opt['title'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                    subtitle: Text(
                      opt['subtitle'],
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

              Row(
                children: [
                  Checkbox(
                    value: _dontShowToday,
                    activeColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    checkColor: isDark ? const Color(0xFF041412) : Colors.white,
                    onChanged: (val) => setState(() => _dontShowToday = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Hide & don\'t prompt again today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleHide,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? const Color(0xFF1E3A34) : Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(Icons.visibility_off_outlined, color: isDark ? Colors.white70 : Colors.grey, size: 16),
                    label: Text(
                      'Hide Card',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _submitCheckin,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                      foregroundColor: isDark ? const Color(0xFFFFD54F) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD54F), size: 18),
                    label: const Text(
                      'CLAIM +50 XP',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}