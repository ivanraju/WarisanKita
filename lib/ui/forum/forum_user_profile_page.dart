import 'package:flutter/material.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'forum_public_passport.dart';

// Public account capabilities, not the viewer's active profile or a post snapshot.
bool forumProfileIsArtisan(Map<String, dynamic> profile) =>
    '${profile['role']} ${profile['roles']}'.toLowerCase().contains('artisan');
bool forumProfileIsTourist(Map<String, dynamic> profile) =>
    '${profile['role']} ${profile['roles']}'.toLowerCase().contains('tourist');
String forumProfileRoleLabel(Map<String, dynamic> profile) =>
    forumProfileIsArtisan(profile)
    ? (forumProfileIsTourist(profile) ? 'Artisan & Tourist' : 'Artisan')
    : (forumProfileIsTourist(profile) ? 'Tourist' : 'Community profile');

class ForumUserProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialProfile;
  final String? historicalRole;

  const ForumUserProfilePage({
    super.key,
    required this.userId,
    this.initialProfile,
    this.historicalRole,
  });

  @override
  State<ForumUserProfilePage> createState() => _ForumUserProfilePageState();
}

class _ForumUserProfilePageState extends State<ForumUserProfilePage> {
  late final Future<Map<String, dynamic>?> _profileFuture = _loadProfile();

  Future<Map<String, dynamic>?> _loadProfile() async {
    try {
      final client = Supabase.instance.client;
      final row = await client
          .from('users')
          .select('id, username, display_name, full_name, avatar_url, role')
          .eq('id', widget.userId)
          .maybeSingle();
      final profile = row == null
          ? Map<String, dynamic>.from(widget.initialProfile ?? const {})
          : Map<String, dynamic>.from(row);
      if (profile.isEmpty) return null;
      if ((profile['bio'] ?? '').toString().trim().isEmpty) {
        try {
          final artisan = await client
              .from('artisan_profiles')
              .select('bio')
              .eq('user_id', widget.userId)
              .maybeSingle();
          if (artisan != null) profile['bio'] = artisan['bio'];
        } catch (_) {}
      }
      try {
        final studio = await client
            .from('artisan_profiles')
            .select('studio_name, craft_category')
            .eq('user_id', widget.userId)
            .maybeSingle();
        if (studio != null) profile.addAll(studio);
      } catch (error) {
        debugPrint('Forum studio details unavailable (${error.runtimeType})');
      }
      if (widget.historicalRole == 'artisan') return profile;
      final passport = await ForumPublicPassport.load(client, widget.userId);
      profile['progress'] = passport.progress;
      profile['stamps'] = passport.stamps;
      return profile;
    } catch (error) {
      debugPrint('Forum profile lookup failed (${error.runtimeType})');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HeritageBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Forum Profile', style: GoogleFonts.dmSerifDisplay()),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load profile. Please try again.'),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('User profile unavailable'));
          }
          final displayName =
              (profile['display_name'] ??
                      profile['full_name'] ??
                      profile['username'] ??
                      'Anonymous')
                  .toString();
          final username = (profile['username'] ?? '').toString();
          final isArtisan = widget.historicalRole == 'artisan';
          final isTourist = widget.historicalRole != 'artisan';
          final avatar = (profile['avatar_url'] ?? '').toString().trim();
          final progress = profile['progress'] as HeritageProgress?;
          final stamps = List<HeritageStamp>.from(
            profile['stamps'] ?? const [],
          );
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B2935), Color(0xFF004D40)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                        child: avatar.isEmpty
                            ? const Icon(Icons.person, size: 42)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isArtisan ? 'Artisan' : 'Tourist',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isArtisan) ...[
                const SizedBox(height: 16),
                Text(
                  'Artisan profile',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22),
                ),
                if ((profile['studio_name'] ?? '').toString().trim().isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(profile['studio_name'].toString()),
                    subtitle: const Text('Studio'),
                  ),
                if ((profile['craft_category'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(profile['craft_category'].toString()),
                    subtitle: const Text('Craft'),
                  ),
              ],
              if (isTourist && progress != null)
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: const Icon(
                      Icons.workspace_premium_outlined,
                      color: Color(0xFFB8860B),
                    ),
                    title: Text('Tier ${progress.currentTier.level}'),
                    subtitle: Text(progress.currentTier.title),
                    trailing: Text('${progress.totalXp} XP'),
                  ),
                ),
              if ((profile['bio'] ?? '').toString().trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'About',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile['bio'].toString(),
                  style: const TextStyle(height: 1.6),
                ),
              ],
              if (isTourist) ...[
                const SizedBox(height: 20),
                Text(
                  'Heritage Passport Stamps',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22),
                ),
                const SizedBox(height: 8),
                if (stamps.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 30,
                          color: Color(0xFFB8860B),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No Heritage Passport Stamps to display.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: stamps
                          .map(
                            (stamp) => SizedBox(
                              width: constraints.maxWidth < 300
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2,
                              child: _buildPublicStampCard(stamp),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildPublicStampCard(HeritageStamp stamp) {
    final category = stamp.category.toLowerCase();
    final gold = category.contains('batik') || category.contains('textile')
        ? const Color(0xFF0284C7)
        : category.contains('wood')
        ? const Color(0xFF059669)
        : category.contains('pottery') || category.contains('ceramic')
        ? const Color(0xFFD97706)
        : category.contains('metal')
        ? const Color(0xFF64748B)
        : category.contains('weav') || category.contains('songket')
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF00796B);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = stamp.earnedAt?.toLocal();
    final validImage =
        stamp.iconUrl.startsWith('https://') ||
        stamp.iconUrl.startsWith('http://');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17332E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(5.76),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold, width: 2),
                ),
                child: ClipOval(
                  child: validImage
                      ? Image.network(
                          stamp.iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Icon(
                            Icons.workspace_premium_outlined,
                            color: gold,
                            size: 36,
                          ),
                        )
                      : Icon(
                          Icons.workspace_premium_outlined,
                          color: gold,
                          size: 36,
                        ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    size: 14,
                    color: Color(0xFF004D40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stamp.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF5EBCF) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stamp.description,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFB8D8CF) : const Color(0xFF45635C),
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
