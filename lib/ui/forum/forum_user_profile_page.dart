import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/domain/models/badge.dart';

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
      try {
        final xpRow = await client
            .from('user_experience')
            .select('total_xp')
            .eq('user_id', widget.userId)
            .maybeSingle();
        profile['progress'] = HeritageProgression.fromXp(
          (xpRow?['total_xp'] as num?)?.toInt() ?? 0,
        );
      } catch (error) {
        debugPrint('Forum profile XP lookup failed (${error.runtimeType})');
      }
      try {
        final stamps = await client
            .from('passport_stamps')
            .select('*, quests(*)')
            .eq('user_id', widget.userId)
            .order('unlocked_at', ascending: false);
        profile['stamps'] = List<Map<String, dynamic>>.from(stamps)
            .map(HeritageStamp.fromMap)
            .where((stamp) => stamp.isUnlocked)
            .toList(growable: false);
      } catch (_) {
        profile['stamps'] = <HeritageStamp>[];
      }
      return profile;
    } catch (error) {
      debugPrint('Forum profile lookup failed (${error.runtimeType})');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  ...stamps.map(
                    (stamp) => ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: Text(stamp.title),
                      subtitle: Text(stamp.description),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
