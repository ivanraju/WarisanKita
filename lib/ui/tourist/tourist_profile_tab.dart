import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/core/settings_screen.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class TouristProfileTab extends StatefulWidget {
  const TouristProfileTab({super.key});

  @override
  State<TouristProfileTab> createState() => _TouristProfileTabState();
}

class _TouristProfileTabState extends State<TouristProfileTab> {
  final List<Map<String, dynamic>> _passportStamps = const [
    {
      'id': 's1',
      'title': 'Clay Labu Sayong',
      'category': 'Pottery & Ceramics',
      'location': 'Kampung Morten, Melaka',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFD97706),
      'unlocked': true,
      'date': '04 AUG 2026',
      'exp': '+500 EXP',
      'stampCode': 'STAMP #MLK-084',
      'lore': 'Hand-spun natural clay kilned at 900°C under Master Pak Mat. Historical origin: Kuala Kangsar labu sayong water vessel.',
    },
    {
      'id': 's2',
      'title': 'Natural Indigo Batik',
      'category': 'Batik & Canting',
      'location': 'Kuala Terengganu',
      'icon': Icons.palette_rounded,
      'color': Color(0xFF0284C7),
      'unlocked': true,
      'date': '28 JUL 2026',
      'exp': '+450 EXP',
      'stampCode': 'STAMP #TRG-102',
      'lore': 'Natural indigo dye extraction and hand-drawn canting wax on silk. Historical origin: Terengganu coastal royal court weavers.',
    },
    {
      'id': 's3',
      'title': 'Royal Gold Songket',
      'category': 'Textile Weaving',
      'location': 'Kota Bharu, Kelantan',
      'icon': Icons.auto_awesome_mosaic_rounded,
      'color': Color(0xFF8B5CF6),
      'unlocked': true,
      'date': '15 JUL 2026',
      'exp': '+600 EXP',
      'stampCode': 'STAMP #KLT-055',
      'lore': 'Traditional hand-loomed gold and silver thread weaving with floral motifs.',
    },
    {
      'id': 's4',
      'title': 'Malay Wood Carving',
      'category': 'Timber Craft',
      'location': 'Kuala Kangsar, Perak',
      'icon': Icons.carpenter_rounded,
      'color': Color(0xFF059669),
      'unlocked': true,
      'date': '02 JUL 2026',
      'exp': '+400 EXP',
      'stampCode': 'STAMP #PRK-019',
      'lore': 'Ornate floral relief carving in chengal hardwood architectural panels.',
    },
    {
      'id': 's5',
      'title': 'Royal Pewter Casting',
      'category': 'Metalwork',
      'location': 'Kuala Lumpur',
      'icon': Icons.shield_rounded,
      'color': Color(0xFF64748B),
      'unlocked': false,
      'date': 'LOCKED QUEST',
      'exp': '+500 EXP',
      'stampCode': 'STAMP #WPL-000',
      'lore': 'Visit Royal Selangor pewter workshop to unlock this stamp.',
    },
    {
      'id': 's6',
      'title': 'Traditional Wau Kite',
      'category': 'Paper & Bamboo',
      'location': 'Tumpat, Kelantan',
      'icon': Icons.air_rounded,
      'color': Color(0xFFEC4899),
      'unlocked': false,
      'date': 'LOCKED QUEST',
      'exp': '+450 EXP',
      'stampCode': 'STAMP #KLT-099',
      'lore': 'Hand-crafted Wau Bulan bamboo frame and intricate floral paper cutting.',
    },
  ];

  void _showStampDetailModal(Map<String, dynamic> stamp) {
    showDialog(
      context: context,
      builder: (context) {
        final bool unlocked = stamp['unlocked'];

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: unlocked ? (stamp['color'] as Color).withValues(alpha: 0.15) : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unlocked ? (stamp['color'] as Color) : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    stamp['icon'],
                    size: 48,
                    color: unlocked ? (stamp['color'] as Color) : Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: unlocked ? const Color(0xFFFEF3C7) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stamp['stampCode'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: unlocked ? const Color(0xFFB45309) : Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  stamp['title'],
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF0F172A)),
                ),

                Text(
                  stamp['location'],
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                Text(
                  stamp['lore'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
                ),

                const SizedBox(height: 20),

                if (unlocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Earned ${stamp['exp']} • ${stamp['date']}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF004D40)),
                      ),
                    ],
                  )
                else
                  Text(
                    '📌 Visit studio location to unlock stamp!',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CLOSE PASSPORT SEAL'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCertificateModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 56, color: Color(0xFFFFD54F)),
              const SizedBox(height: 12),
              Text(
                'OFFICIAL HERITAGE GUARDIAN CERTIFICATE',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
              ),
              const SizedBox(height: 6),
              Text(
                'Issued to Aiman Haziq',
                style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),
              Text(
                'This certificate confirms that Aiman Haziq has completed 14 Cultural Quests and directly supported 4 Master Artisan Families in Melaka, Terengganu, and Kelantan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                  child: const Text('CLOSE CERTIFICATE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          title: Text(
            langVM.translate('Heritage Passport & Mastery'),
            style: GoogleFonts.dmSerifDisplay(
              color: const Color(0xFF004D40),
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF004D40)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🛂 ROYAL MALAYSIAN HERITAGE PASSPORT BOOKLET CARD
                GestureDetector(
                  onTap: _showCertificateModal,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0A192F),
                          Color(0xFF004D40),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF004D40).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'PASPORT WARISAN KITA',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFFFD54F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '#MY-HERITAGE-8492',
                                style: GoogleFonts.sourceCodePro(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 33,
                                  backgroundColor: const Color(0xFFFFD54F),
                                  child: Text(
                                    'AH',
                                    style: GoogleFonts.dmSerifDisplay(
                                      color: const Color(0xFF004D40),
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aiman Haziq',
                                    style: GoogleFonts.dmSerifDisplay(
                                      color: Colors.white,
                                      fontSize: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tier 4: Master Heritage Guardian',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFFFD54F),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: 2450 / 3000,
                                          backgroundColor: Colors.white24,
                                          color: const Color(0xFFFFD54F),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '2,450 / 3,000 EXP (550 EXP to Tier 5)',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPassportMetric('14', 'Quests Done', Icons.check_circle_rounded),
                            _buildPassportMetric('8', 'Studios Visited', Icons.storefront_rounded),
                            _buildPassportMetric('4', 'Digital Plaques', Icons.verified_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 🌱 HERITAGE PRESERVATION IMPACT CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.nature_people_rounded, size: 40, color: Color(0xFF166534)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preservation Impact',
                              style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFF14532D)),
                            ),
                            Text(
                              'Your visits directly supported 4 Master Artisan Families and preserved 1,200 hours of heritage craft lore in 2026.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF166534), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 📜 HERITAGE PASSPORT STAMPS COLLECTION HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heritage Stamps Collection',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22,
                            color: const Color(0xFF004D40),
                          ),
                        ),
                        Text(
                          'Tap any stamp to inspect certificate lore',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '4 / 6 Stamps',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // 🎨 VIBRANT PASSPORT STAMPS GRID
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final stamp = _passportStamps[index];
                final bool unlocked = stamp['unlocked'];
                final Color color = stamp['color'];

                return GestureDetector(
                  onTap: () => _showStampDetailModal(stamp),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: unlocked ? Colors.white : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: unlocked ? color.withValues(alpha: 0.4) : Colors.black12,
                        width: unlocked ? 1.5 : 1.0,
                      ),
                      boxShadow: unlocked
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: unlocked ? color.withValues(alpha: 0.12) : Colors.grey[300],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: unlocked ? color : Colors.grey[400]!,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            Icon(
                              stamp['icon'],
                              color: unlocked ? color : Colors.grey[500],
                              size: 28,
                            ),
                            if (unlocked)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFFD54F)),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          stamp['title'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: unlocked ? const Color(0xFF0F172A) : Colors.grey[500],
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          unlocked ? stamp['date'] : 'LOCKED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: unlocked ? color : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _passportStamps.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildPassportMetric(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD54F), size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.dmSerifDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
