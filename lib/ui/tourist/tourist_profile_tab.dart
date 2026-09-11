import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/ui/tourist/apply_artisan_screen.dart';
import 'package:warisan_kita/ui/core/edit_profile_screen.dart';
import 'package:warisan_kita/ui/core/settings_screen.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

class TouristProfileTab extends StatefulWidget {
  const TouristProfileTab({super.key});

  @override
  State<TouristProfileTab> createState() => _TouristProfileTabState();
}

class _TouristProfileTabState extends State<TouristProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GamificationViewModel>().loadPassport();
        context.read<AuthViewModel>().refreshCurrentUser();
      }
    });
  }

  void _showStampDetailModal(HeritageStamp stamp) {
    final color = _stampColor(stamp);
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? const Color(0xFF17332E) : Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStampArtwork(stamp, color, size: 92),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: stamp.isUnlocked
                          ? (isDark
                                ? const Color(0xFF493A1E)
                                : const Color(0xFFFEF3C7))
                          : (isDark
                                ? const Color(0xFF29433D)
                                : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stamp.isUnlocked && stamp.stampCode.isNotEmpty
                          ? stamp.stampCode
                          : 'LOCKED STAMP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: stamp.isUnlocked
                            ? (isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFB45309))
                            : (isDark ? Colors.white70 : Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stamp.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      color: isDark
                          ? const Color(0xFFF5EBCF)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  if (stamp.category.isNotEmpty)
                    Text(
                      stamp.category,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Divider(color: isDark ? Colors.white24 : null),
                  const SizedBox(height: 14),
                  if (stamp.questTitle.isNotEmpty)
                    _buildStampDetailRow(
                      Icons.explore_rounded,
                      'Quest: ${stamp.questTitle}',
                    ),
                  if (stamp.earnedAt != null) ...[
                    const SizedBox(height: 8),
                    _buildStampDetailRow(
                      Icons.event_available_rounded,
                      'Earned: ${_formatStampDate(stamp.earnedAt!)}',
                    ),
                  ],
                  if (!stamp.isUnlocked) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Complete this approved cultural quest to earn its stamp.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF004D40),
                        foregroundColor: isDark
                            ? const Color(0xFF08211D)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'CLOSE STAMP SEAL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStampDetailRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF004D40),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD9F2E8) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  void _showCertificateModal(
    String username,
    String completedQuests,
    String visitedStudios,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF78350F).withValues(alpha: 0.3)
                        : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 48,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'NATIONAL HERITAGE GUARDIAN',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    color: const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'OFFICIAL DIGITAL CERTIFICATE OF APPRECIATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFD97706),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? const Color(0xFF1E3A34) : null),
                const SizedBox(height: 12),
                Text(
                  'This certifies that $username has actively supported Malaysian craft preservation by completing $completedQuests cultural quests across $visitedStudios verified master studios.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.4,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langVM = context.watch<LanguageViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final gameStat = context.watch<GamificationViewModel>();
    final user = authVM.currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final username = user.effectiveUsername;
    final initials = user.initials;
    final passportId = _passportId(user.id);
    final completedQuests = gameStat.hasPassportQuestStatistics
        ? '${gameStat.completedPassportQuests}'
        : '—';
    final visitedStudios = gameStat.hasVisitedPassportStudioData
        ? '${gameStat.visitedPassportQuests}'
        : '—';
    final passportStamps = gameStat.hasPassportStampData
        ? '${gameStat.earnedPassportStamps.length}'
        : '—';
    final nextTier = gameStat.nextTier;
    final xpSummary = !gameStat.hasPassportXpData
        ? 'XP unavailable • Pull to refresh'
        : nextTier == null
        ? '${_formatNumber(gameStat.totalEarnedXp)} XP • Maximum tier reached'
        : '${_formatNumber(gameStat.totalEarnedXp)} / '
              '${_formatNumber(nextTier.minimumXp)} XP '
              '(${_formatNumber(nextTier.minimumXp - gameStat.totalEarnedXp)} '
              'XP to Tier ${nextTier.level})';

    return ColoredBox(
      color: isDark ? const Color(0xFF081B18) : const Color(0xFFF8F9FA),
      child: RefreshIndicator(
        key: const Key('tourist-passport-page'),
        onRefresh: gameStat.loadPassport,
        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
        backgroundColor: isDark ? const Color(0xFF173C35) : Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: isDark
                  ? const Color(0xFF081B18)
                  : const Color(0xFFF8F9FA),
              elevation: 0,
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  langVM.translate('Heritage Passport & Mastery'),
                  style: GoogleFonts.dmSerifDisplay(
                    color: isDark
                        ? const Color(0xFFFFE082)
                        : const Color(0xFF004D40),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                  ),
                  tooltip: 'Edit Explorer Profile',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                  ),
                  tooltip: 'Settings',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🛂 POLARSTEPS INSPIRED ROYAL PASSPORT BOOKLET CARD
                    GestureDetector(
                      onTap: () => _showCertificateModal(
                        username,
                        completedQuests,
                        visitedStudios,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0A192F), Color(0xFF004D40)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF004D40,
                              ).withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(
                              0xFFFFD54F,
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFFFFD54F),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'PASPORT WARISAN KITA',
                                          softWrap: true,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFFFFD54F),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFFD54F,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    passportId,
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
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFFD54F),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFFD54F,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 34,
                                      backgroundColor: const Color(0xFFFFD54F),
                                      backgroundImage:
                                          user?.avatarImageProvider,
                                      child: user?.avatarImageProvider != null
                                          ? null
                                          : Text(
                                              initials,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              username,
                                              style: GoogleFonts.dmSerifDisplay(
                                                color: Colors.white,
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const EditProfileScreen(),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white24,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.edit_rounded,
                                                    size: 12,
                                                    color: Color(0xFFFFD54F),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Edit',
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        gameStat.hasPassportXpData
                                            ? 'Tier ${gameStat.currentTier.level}: '
                                                  '${gameStat.currentTier.title}'
                                            : 'Tier unavailable',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFFFD54F),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: gameStat.hasPassportXpData
                                                  ? gameStat.rankProgress
                                                  : 0,
                                              backgroundColor: Colors.white24,
                                              color: const Color(0xFFFFD54F),
                                              minHeight: 8,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            xpSummary,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
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
                                _buildPassportMetric(
                                  completedQuests,
                                  'Quests Done',
                                  Icons.check_circle_rounded,
                                ),
                                _buildPassportMetric(
                                  visitedStudios,
                                  'Studios Visited',
                                  Icons.storefront_rounded,
                                ),
                                _buildPassportMetric(
                                  passportStamps,
                                  'Heritage Passport Stamps',
                                  Icons.workspace_premium_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🌱 HERITAGE PRESERVATION IMPACT CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF15362F)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3D806B)
                              : const Color(0xFF86EFAC),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF166534,
                            ).withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF166534,
                              ).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.nature_people_rounded,
                              size: 28,
                              color: Color(0xFF166534),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preservation Impact',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 16,
                                    color: isDark
                                        ? const Color(0xFFD9F2E8)
                                        : const Color(0xFF14532D),
                                  ),
                                ),
                                Text(
                                  gameStat.hasPassportQuestStatistics
                                      ? 'Your visits directly supported '
                                            '${gameStat.visitedPassportQuests} '
                                            'Master Artisan '
                                            '${gameStat.visitedPassportQuests == 1 ? 'Family' : 'Families'}.'
                                      : 'Preservation impact is temporarily unavailable. Pull to refresh.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF9ED8C3)
                                        : const Color(0xFF166534),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (authVM.currentUser?.isArtisanStudioSuspended ==
                        true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.block_rounded,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Master Artisan Studio: Suspended',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                  Text(
                                    'Your studio license is under administrative suspension. You may continue exploring as a Cultural Tourist.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (authVM.currentUser?.isApprovedArtisan ==
                        true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B2C1B)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD97706,
                                ).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFFB45309),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dual Role: Master Artisan Studio',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFFFFE082)
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                  Text(
                                    'Switch to manage your craft studio, live sessions, and masterworks.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFFF5C76B)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                authVM.selectActiveRole('Master Artisan');
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/artisan');
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Switch',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (authVM.currentUser?.isRejectedArtisan == true ||
                        authVM.currentUser?.status.toUpperCase() == 'REJECTED' ||
                        authVM.currentUser?.artisanStatus?.toUpperCase() == 'REJECTED' ||
                        authVM.currentUser?.isPendingArtisan == true ||
                        authVM.currentUser?.isPendingApproval == true ||
                        (authVM.currentUser?.studioName != null &&
                            authVM.currentUser!.studioName!.trim().isNotEmpty &&
                            authVM.currentUser?.isApprovedArtisan != true)) ...[
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final isAppRejected = authVM.currentUser?.isRejectedArtisan == true;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isAppRejected ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isAppRejected ? const Color(0xFFFCA5A5) : const Color(0xFFFCD34D)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isAppRejected
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                        : const Color(0xFFD97706).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isAppRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                                    color: isAppRejected ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Artisan Studio Application',
                                              softWrap: true,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isAppRejected ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isAppRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isAppRejected ? const Color(0xFFF87171) : const Color(0xFFF59E0B),
                                              ),
                                            ),
                                            child: Text(
                                              isAppRejected ? 'NEEDS UPDATE' : 'PENDING REVIEW',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                color: isAppRejected ? const Color(0xFFDC2626) : const Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isAppRejected
                                            ? 'Your application was not approved. Tap below to review feedback and update documents.'
                                            : 'Your Master Artisan registration is undergoing Kraftangan Malaysia verification. Studio access unlocks upon approval.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isAppRejected ? const Color(0xFF7F1D1D) : const Color(0xFF78350F),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ArtisanApplicationPendingScreen(
                                              studioName:
                                                  authVM.currentUser?.studioName ??
                                                  'Your Craft Studio',
                                              craftCategory:
                                                  authVM
                                                      .currentUser
                                                      ?.craftCategory ??
                                                  'Malaysian Heritage Craft',
                                              ssmNumber:
                                                  authVM.currentUser?.ssmNumber ??
                                                  'Pending Document Verification',
                                            ),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isAppRejected ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isAppRejected ? 'Review & Update' : 'View Application',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF004D40,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF004D40,
                                ).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.palette_outlined,
                                color: Color(0xFF004D40),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Are you a Master Artisan?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFF004D40),
                                    ),
                                  ),
                                  Text(
                                    'Register your traditional studio to host quests and earn Kraftangan recognition.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ApplyArtisanScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF004D40),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 📜 HERITAGE PASSPORT STAMPS COLLECTION HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Heritage Passport Stamps',
                                maxLines: 2,
                                softWrap: true,
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 22,
                                  color: isDark
                                      ? const Color(0xFFFFE082)
                                      : const Color(0xFF004D40),
                                ),
                              ),
                              Text(
                                'Tap any stamp to inspect certificate lore',
                                maxLines: 2,
                                softWrap: true,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _stampCounterText(gameStat),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (gameStat.passportWarning != null) ...[
                      const SizedBox(height: 12),
                      _buildPassportNotice(
                        gameStat.passportWarning!,
                        gameStat.loadPassport,
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 🎨 PERFECTLY CENTERED PASSPORT STAMPS GRID
            if (gameStat.isLoadingPassport && gameStat.stamps.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  key: Key('passport-loading'),
                  padding: EdgeInsets.symmetric(vertical: 44),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF004D40)),
                  ),
                ),
              )
            else if (gameStat.passportError != null && gameStat.stamps.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPassportStateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Passport unavailable',
                    message: gameStat.passportError!,
                    actionLabel: 'Try Again',
                    onAction: gameStat.loadPassport,
                  ),
                ),
              )
            else if (gameStat.stamps.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPassportStateCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Your first stamp awaits',
                    message: gameStat.hasAvailablePassportStampData
                        ? 'No approved Heritage Passport badges are available yet.'
                        : 'No earned stamps were found. Pull to refresh your Passport.',
                    actionLabel: 'Refresh',
                    onAction: gameStat.loadPassport,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final stamp = gameStat.stamps[index];
                    final unlocked = stamp.isUnlocked;
                    final color = _stampColor(stamp);

                    return GestureDetector(
                      onTap: () => _showStampDetailModal(stamp),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? (isDark
                                    ? const Color(0xFF17332E)
                                    : Colors.white)
                              : (isDark
                                    ? const Color(0xFF102622)
                                    : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: unlocked
                                ? color.withValues(alpha: 0.35)
                                : (isDark
                                      ? const Color(0xFF36554D)
                                      : Colors.black12),
                            width: unlocked ? 1.5 : 1.0,
                          ),
                          boxShadow: unlocked
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildStampArtwork(stamp, color, size: 64),

                            const SizedBox(height: 12),

                            Flexible(
                              child: Text(
                                stamp.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: unlocked
                                      ? (isDark
                                            ? const Color(0xFFF5EBCF)
                                            : const Color(0xFF0F172A))
                                      : (isDark
                                            ? const Color(0xFFB9C8C3)
                                            : Colors.grey[500]),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: unlocked
                                    ? color.withValues(alpha: 0.1)
                                    : (isDark
                                          ? const Color(0xFF29433D)
                                          : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unlocked && stamp.earnedAt != null
                                    ? _formatStampDate(stamp.earnedAt!)
                                    : 'LOCKED STAMP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: unlocked
                                      ? color
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.grey[500]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: gameStat.stamps.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _passportId(String? userId) {
    final normalized = (userId ?? '').replaceAll('-', '').toUpperCase();
    final suffix = normalized.isEmpty
        ? 'PENDING'
        : normalized.substring(
            0,
            normalized.length < 8 ? normalized.length : 8,
          );
    return '#MY-HERITAGE-$suffix';
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  String _formatStampDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String _stampCounterText(GamificationViewModel state) {
    if (!state.hasPassportStampData) return '— STAMPS';
    final earned = state.earnedPassportStamps.length;
    if (state.hasAvailablePassportStampData &&
        state.availablePassportStamps > 0) {
      return '$earned / ${state.availablePassportStamps} STAMPS';
    }
    return '$earned STAMPS EARNED';
  }

  Color _stampColor(HeritageStamp stamp) {
    final category = stamp.category.toLowerCase();
    if (category.contains('batik') || category.contains('textile')) {
      return const Color(0xFF0284C7);
    }
    if (category.contains('wood')) return const Color(0xFF059669);
    if (category.contains('pottery') || category.contains('ceramic')) {
      return const Color(0xFFD97706);
    }
    if (category.contains('metal')) return const Color(0xFF64748B);
    if (category.contains('weav') || category.contains('songket')) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF00796B);
  }

  IconData _stampFallbackIcon(HeritageStamp stamp) {
    final category = stamp.category.toLowerCase();
    if (category.contains('batik') || category.contains('textile')) {
      return Icons.palette_rounded;
    }
    if (category.contains('wood')) return Icons.carpenter_rounded;
    if (category.contains('pottery') || category.contains('ceramic')) {
      return Icons.local_fire_department_rounded;
    }
    if (category.contains('metal')) return Icons.shield_rounded;
    if (category.contains('weav') || category.contains('songket')) {
      return Icons.auto_awesome_mosaic_rounded;
    }
    return Icons.workspace_premium_rounded;
  }

  Widget _buildStampArtwork(
    HeritageStamp stamp,
    Color color, {
    required double size,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validUrl =
        stamp.iconUrl.startsWith('https://') ||
        stamp.iconUrl.startsWith('http://');
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: stamp.isUnlocked
                ? color.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF29433D) : Colors.grey[200]),
            shape: BoxShape.circle,
            border: Border.all(
              color: stamp.isUnlocked
                  ? color
                  : (isDark ? const Color(0xFF789087) : Colors.grey[400]!),
              width: 2,
            ),
          ),
          padding: EdgeInsets.all(size * 0.08),
          child: ClipOval(
            child: stamp.isUnlocked && validUrl
                ? Image.network(
                    stamp.iconUrl,
                    key: Key('stamp-image-${stamp.id}'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _stampImageFallback(stamp, color),
                  )
                : _stampImageFallback(stamp, color),
          ),
        ),
        if (stamp.isUnlocked)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD54F),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(
                Icons.stars_rounded,
                size: 14,
                color: Color(0xFF004D40),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stampImageFallback(HeritageStamp stamp, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: Key('stamp-image-fallback-${stamp.id}'),
      color: stamp.isUnlocked
          ? color.withValues(alpha: 0.08)
          : (isDark ? const Color(0xFF29433D) : Colors.grey[200]),
      alignment: Alignment.center,
      child: Icon(
        stamp.isUnlocked
            ? _stampFallbackIcon(stamp)
            : Icons.lock_outline_rounded,
        color: stamp.isUnlocked
            ? color
            : (isDark ? const Color(0xFF9BB0A8) : Colors.grey[400]),
      ),
    );
  }

  Widget _buildPassportNotice(String message, Future<void> Function() retry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildPassportStateCard({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8E5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFD97706), size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: const Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _buildPassportMetric(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFFD54F), size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  softWrap: true,
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
