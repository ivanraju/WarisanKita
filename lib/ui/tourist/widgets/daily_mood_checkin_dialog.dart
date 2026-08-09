import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyMoodCheckinDialog extends StatefulWidget {
  final Function(String selectedMood) onMoodSelected;

  const DailyMoodCheckinDialog({
    super.key,
    required this.onMoodSelected,
  });

  @override
  State<DailyMoodCheckinDialog> createState() => _DailyMoodCheckinDialogState();
}

class _DailyMoodCheckinDialogState extends State<DailyMoodCheckinDialog> {
  String? _selectedMood;

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Daily Heritage Check-in',
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
              'What craft heritage would you like to explore today?',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700]),
            ),

            const SizedBox(height: 20),

            // Options List
            ..._moodOptions.map((opt) {
              final bool isSelected = _selectedMood == opt['category'];

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
                  onTap: () => setState(() => _selectedMood = opt['category']),
                  title: Text(
                    opt['title'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF004D40) : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    opt['subtitle'],
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
                onPressed: _submitCheckin,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFD54F), size: 18),
                label: const Text('CLAIM DAILY +50 XP & FILTER MAP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
