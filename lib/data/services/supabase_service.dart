import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';
import 'package:warisan_kita/domain/models/badge.dart';

class SupabaseService {
  // CRITICAL FIX: Use a getter for the client.
  // This ensures we do not access Supabase.instance until it is actually needed.
  // This prevents the "Supabase not initialized" crash during app startup.
  SupabaseClient get _client => Supabase.instance.client;

  // --- Auth Services ---
  
  Future<AuthResponse> signIn(String email, String password) async {
    // In a real app, this would be:
    // return await _client.auth.signInWithPassword(email: email, password: password);
    
    // For the prototype, we let the State layer handle mock successful login
    throw UnimplementedError("Initialize Supabase with real credentials in main.dart to use auth.");
  }

  Future<AuthResponse> signUp(String email, String password, String role) async {
    // return await _client.auth.signUp(email: email, password: password, data: {'role': role});
    throw UnimplementedError();
  }

  Future<void> signOut() async {
    // await _client.auth.signOut();
  }

  // --- Directory Services ---

  Future<List<ArtisanModel>> fetchArtisans() async {
    // Simulate network delay for "expensive" feel
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      ArtisanModel(
        id: '1',
        name: 'Master Zaid',
        craftType: 'Woodwork',
        state: 'Terengganu',
        description: 'A 5th generation master of the Cengal wood carving tradition. His intricate patterns represent the spiritual connection between nature and heritage.',
        imageUrl: 'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?w=800',
        rating: 4.9,
        experience: '35 Years',
        workshopCount: 12,
        tags: ['Heritage', 'Royal Craft'],
      ),
      ArtisanModel(
        id: '2',
        name: 'Tok Wan',
        craftType: 'Songket',
        state: 'Kelantan',
        description: 'Custodian of traditional "Bunga Dalam" weaving motifs. Each piece takes 3 months to complete using hand-spun silk and gold threads.',
        imageUrl: 'https://images.unsplash.com/photo-1590739225287-bd31519780c3?w=800',
        rating: 4.8,
        experience: '45 Years',
        workshopCount: 8,
        tags: ['Master', 'Weaving'],
      ),
      ArtisanModel(
        id: '3',
        name: 'Siti Rahmah',
        craftType: 'Batik',
        state: 'Terengganu',
        description: 'Specialist in hand-drawn chanting batik using natural dyes extracted from rainforest barks and local fruits.',
        imageUrl: 'https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=800',
        rating: 4.7,
        experience: '22 Years',
        workshopCount: 15,
        tags: ['Natural Dyes', 'Batik Tulis'],
      ),
      ArtisanModel(
        id: '4',
        name: 'Ahmad Fauzi',
        craftType: 'Keris',
        state: 'Melaka',
        description: 'Master blacksmith forging the soul of the Malay archipelago. His keris blades are renowned for their strength and symbolic beauty.',
        imageUrl: 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=800',
        rating: 4.9,
        experience: '30 Years',
        workshopCount: 4,
        tags: ['Blacksmith', 'Metalwork'],
      ),
    ];
  }

  // --- Forum Services ---

  Future<List<ForumThread>> fetchThreads() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      ForumThread(
        id: 'f1',
        title: 'Identifying authentic Terengganu Batik',
        authorName: 'Aminah Bakar',
        authorAvatar: 'https://i.pravatar.cc/150?u=1',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        replyCount: 14,
        tags: ['Batik', 'Guide'],
        replies: [
          ThreadReply(
            id: 'r1',
            authorName: 'Master Zaid',
            content: 'Look for slight irregularities in the chanting lines. Hand-drawn batik is never factory-perfect.',
            timestamp: '1h ago',
            isVerifiedArtisan: true,
          ),
          ThreadReply(
            id: 'r2',
            authorName: 'Collector_Ali',
            content: 'Also, check if the color bleeds through to the back side perfectly.',
            timestamp: '45m ago',
          ),
        ],
      ),
      ForumThread(
        id: 'f2',
        title: 'The symbolism of Wau Bulan shapes',
        authorName: 'Aizat Rahim',
        authorAvatar: 'https://i.pravatar.cc/150?u=3',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        replyCount: 8,
        tags: ['Wau', 'History'],
        replies: [],
      ),
    ];
  }

  // --- Gamification Services ---

  Future<List<HeritageStamp>> fetchUserStamps(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      HeritageStamp(
        id: 's1', 
        title: 'Batik Apprentice', 
        iconUrl: 'https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=200', 
        isUnlocked: true,
        description: 'Earned for visiting a master batik chanting workshop.',
      ),
      HeritageStamp(
        id: 's2', 
        title: 'Wood Guardian', 
        iconUrl: 'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?w=200', 
        isUnlocked: true,
        description: 'Earned for identifying three royal Cengal carving motifs.',
      ),
    ];
  }
}
