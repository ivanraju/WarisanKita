import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static final _transparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();
  SharedPreferences.setMockInitialValues({});

  group('Artisan Profile Photos Sync & Display Tests', () {
    test('ArtisanModel.fromMap includes STUDIO_PHOTO in images and excludes from craftingPhotoUrl', () {
      final map = {
        'id': 'artisan_1',
        'studio_name': 'Pak Samad Woodcraft',
        'craft_category': 'Woodwork',
        'artisan_documents': [
          {
            'doc_type': 'STUDIO_PHOTO',
            'file_url': 'https://example.com/studio1.jpg',
            'file_name': 'studio1.jpg',
          },
          {
            'doc_type': 'STUDIO_PHOTO',
            'file_url': 'https://example.com/studio2.jpg',
            'file_name': 'studio2.jpg',
          },
          {
            'doc_type': 'STUDIO_PHOTO',
            'file_url': 'https://example.com/studio3.jpg',
            'file_name': 'studio3.jpg',
          },
          {
            'doc_type': 'CRAFTING_PHOTO',
            'file_url': 'https://example.com/verification_craft.jpg',
            'file_name': 'verification_craft.jpg',
          },
        ],
        'tags': [
          'Woodwork',
          'doc_studio_photo:https://example.com/studio1.jpg',
          'doc_studio_photo:https://example.com/studio2.jpg',
          'doc_studio_photo:https://example.com/studio3.jpg',
        ],
      };

      final artisan = ArtisanModel.fromMap(map);

      expect(artisan.images.length, 3);
      expect(artisan.images, contains('https://example.com/studio1.jpg'));
      expect(artisan.images, contains('https://example.com/studio2.jpg'));
      expect(artisan.images, contains('https://example.com/studio3.jpg'));
      expect(artisan.craftingPhotoUrl, 'https://example.com/verification_craft.jpg');
    });

    test('UserModel.photos correctly aggregates 3 studio workshop photos', () {
      const user = UserModel(
        id: 'usr_test_1',
        email: 'artisan@test.com',
        role: 'Artisan',
        roles: ['Artisan'],
        artisanDocuments: [
          {
            'doc_type': 'STUDIO_PHOTO',
            'file_url': 'https://example.com/photo1.jpg',
            'file_name': 'photo1.jpg',
          },
          {
            'doc_type': 'STUDIO_PHOTO',
            'file_url': 'https://example.com/photo2.jpg',
            'file_name': 'photo2.jpg',
          },
          {
            'doc_type': 'STUDIO_PHOTO',
            'file_url': 'https://example.com/photo3.jpg',
            'file_name': 'photo3.jpg',
          },
        ],
        tags: [
          'doc_studio_photo:https://example.com/photo1.jpg',
          'doc_studio_photo:https://example.com/photo2.jpg',
          'doc_studio_photo:https://example.com/photo3.jpg',
        ],
      );

      expect(user.photos.length, 3);
      expect(user.photos, [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
        'https://example.com/photo3.jpg',
      ]);
    });

    testWidgets('ProfileBuilderTab loads and displays all 3 photos attached during application', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final artisanRepo = ArtisanRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final moderationVM = ModerationViewModel(repository: userRepo);
        final directoryVM = DirectoryViewModel(repository: artisanRepo);

        const userWith3Photos = UserModel(
          id: 'artisan_with_photos',
          email: 'photos@artisan.my',
          role: 'Artisan',
          roles: ['Artisan'],
          status: 'ACTIVE',
          artisanStatus: 'APPROVED',
          studioName: 'Heritage Woodworks',
          craftCategory: 'Woodwork',
          experience: '5 Years',
          artisanDocuments: [
            {
              'doc_type': 'STUDIO_PHOTO',
              'file_url': 'https://example.com/w1.jpg',
              'file_name': 'w1.jpg',
            },
            {
              'doc_type': 'STUDIO_PHOTO',
              'file_url': 'https://example.com/w2.jpg',
              'file_name': 'w2.jpg',
            },
            {
              'doc_type': 'STUDIO_PHOTO',
              'file_url': 'https://example.com/w3.jpg',
              'file_name': 'w3.jpg',
            },
            {
              'doc_type': 'SSM_BUSINESS_CERT',
              'file_url': 'https://example.com/ssm.pdf',
              'file_name': 'ssm.pdf',
            },
          ],
          tags: [
            'doc_studio_photo:https://example.com/w1.jpg',
            'doc_studio_photo:https://example.com/w2.jpg',
            'doc_studio_photo:https://example.com/w3.jpg',
          ],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wk_last_auth_user', jsonEncode(userWith3Photos.toMap()));
        await prefs.setString('wk_auth_email', userWith3Photos.email);
        await prefs.setString('wk_active_role', userWith3Photos.role);

        authVM.setCurrentUserForTesting(userWith3Photos);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
              ChangeNotifierProvider<ModerationViewModel>.value(value: moderationVM),
              ChangeNotifierProvider<DirectoryViewModel>.value(value: directoryVM),
              Provider<SupabaseService>.value(value: service),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ProfileBuilderTab(),
              ),
            ),
          ),
        );
        await tester.pump();
        while (tester.takeException() != null) {}

        // Verify the Portfolio Gallery Manager displays "3 Uploaded (Unlimited)"
        expect(find.text('3 Uploaded (Unlimited)'), findsOneWidget);

        // Verify "Portfolio Gallery Manager" section title exists
        expect(find.text('Portfolio Gallery Manager'), findsOneWidget);
      });
    });

    testWidgets('Village workshop crafting proof photo is not overwritten by studio photos in ProfileBuilderTab', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1200, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final artisanRepo = ArtisanRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final moderationVM = ModerationViewModel(repository: userRepo);
        final directoryVM = DirectoryViewModel(repository: artisanRepo);

        const villageUser = UserModel(
          id: 'village_artisan_uid',
          email: 'desa@artisan.my',
          role: 'Artisan',
          roles: ['Artisan'],
          status: 'ACTIVE',
          artisanStatus: 'APPROVED',
          premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
          studioName: 'Desa Weaving',
          craftCategory: 'Songket & Weaving',
          experience: '8 Years',
          artisanDocuments: [
            {
              'doc_type': 'CRAFTING_PHOTO',
              'file_url': 'https://example.com/proof_photo.jpg',
              'file_name': 'proof_photo.jpg',
            },
            {
              'doc_type': 'STUDIO_PHOTO',
              'file_url': 'https://example.com/studio_p1.jpg',
              'file_name': 'studio_p1.jpg',
            },
            {
              'doc_type': 'STUDIO_PHOTO',
              'file_url': 'https://example.com/studio_p2.jpg',
              'file_name': 'studio_p2.jpg',
            },
            {
              'doc_type': 'STUDIO_PHOTO',
              'file_url': 'https://example.com/studio_p3.jpg',
              'file_name': 'studio_p3.jpg',
            },
          ],
          tags: [
            'doc_crafting_photo_url:https://example.com/proof_photo.jpg',
            'doc_studio_photo:https://example.com/studio_p1.jpg',
            'doc_studio_photo:https://example.com/studio_p2.jpg',
            'doc_studio_photo:https://example.com/studio_p3.jpg',
          ],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wk_last_auth_user', jsonEncode(villageUser.toMap()));
        await prefs.setString('wk_auth_email', villageUser.email);
        await prefs.setString('wk_active_role', villageUser.role);

        authVM.setCurrentUserForTesting(villageUser);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
              ChangeNotifierProvider<ModerationViewModel>.value(value: moderationVM),
              ChangeNotifierProvider<DirectoryViewModel>.value(value: directoryVM),
              Provider<SupabaseService>.value(value: service),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ProfileBuilderTab(),
              ),
            ),
          ),
        );
        await tester.pump();
        while (tester.takeException() != null) {}

        // Gallery has the 3 studio photos
        expect(find.text('3 Uploaded (Unlimited)'), findsOneWidget);

        // Crafting proof tile is verified and uploaded
        expect(find.text('Traditional Crafting Proof Photo'), findsOneWidget);
        expect(find.text('Uploaded & Verified Proof'), findsOneWidget);
        expect(find.text('VIEW'), findsWidgets);
        expect(find.text('UPLOADED'), findsNothing);
      });
    });

    testWidgets('Proof of authenticity credentials show VIEW button and open preview without reuploading', (tester) async {
        await HttpOverrides.runZoned(() async {
          tester.view.physicalSize = const Size(1200, 3200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          SharedPreferences.setMockInitialValues({});
          final service = SupabaseService();
          final userRepo = UserRepository(service: service);
          final artisanRepo = ArtisanRepository(service: service);
          final authVM = AuthViewModel(repository: userRepo);
          final moderationVM = ModerationViewModel(repository: userRepo);
          final directoryVM = DirectoryViewModel(repository: artisanRepo);

          const commercialArtisan = UserModel(
            id: 'u_auth_doc_test',
            email: 'auth_doc_artisan@warisankita.my',
            username: 'auth_doc_artisan',
            displayName: 'Master Weaver Che Wan',
            role: 'Artisan',
            roles: ['Artisan'],
            status: 'ACTIVE',
            artisanStatus: 'APPROVED',
            premiseType: 'Commercial Studio',
            studioName: 'Che Wan Commercial Studio',
            craftCategory: 'Songket & Weaving',
            artisanDocuments: [
              {
                'doc_type': 'SSM_BUSINESS_CERT',
                'file_url': 'https://example.com/docs/ssm_cert.png',
              },
              {
                'doc_type': 'KRAFTANGAN_MASTER_CERT',
                'file_url': 'https://example.com/docs/master_cert.png',
              },
            ],
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('wk_last_auth_user', jsonEncode(commercialArtisan.toMap()));
          await prefs.setString('wk_auth_email', commercialArtisan.email);
          await prefs.setString('wk_active_role', commercialArtisan.role);
          authVM.setCurrentUserForTesting(commercialArtisan);

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
                ChangeNotifierProvider<ModerationViewModel>.value(value: moderationVM),
                ChangeNotifierProvider<DirectoryViewModel>.value(value: directoryVM),
                Provider<SupabaseService>.value(value: service),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: ProfileBuilderTab(),
                ),
              ),
            ),
          );
          await tester.pump();
          while (tester.takeException() != null) {}

          // Both commercial credentials are uploaded
          expect(find.text('Business Registration (SSM) Certificate'), findsOneWidget);
          expect(find.text('Kraftangan Malaysia Master Certification'), findsOneWidget);

          // Buttons display 'VIEW' and NOT 'UPLOAD' or 'UPLOADED'
          expect(find.text('VIEW'), findsNWidgets(2));
          expect(find.text('UPLOADED'), findsNothing);

          // Tap the VIEW button on SSM Certificate to trigger in-app preview
          await tester.tap(find.text('VIEW').first);
          await tester.pumpAndSettle();

          // Modal preview dialog is open showing title and Close button
          expect(find.text('Business Registration (SSM) Certificate'), findsNWidgets(2)); // Tile + Dialog Title
          expect(find.byIcon(Icons.close_rounded), findsOneWidget);

          // Close the SSM dialog
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.close_rounded), findsNothing);

          // Tap the second VIEW button (Kraftangan Malaysia Master Certification)
          await tester.tap(find.text('VIEW').last);
          await tester.pumpAndSettle();

          // Modal preview dialog is open showing Kraftangan Master Cert title
          expect(find.text('Kraftangan Malaysia Master Certification'), findsNWidgets(2)); // Tile + Dialog Title
          expect(find.byIcon(Icons.close_rounded), findsOneWidget);

          // Close the Kraftangan dialog
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.close_rounded), findsNothing);
        });
      });

    testWidgets('Village Workshop with Kraftangan certification in tags displays VIEW button and opens preview', (tester) async {
      await HttpOverrides.runZoned(() async {
        tester.view.physicalSize = const Size(1200, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final service = SupabaseService();
        final userRepo = UserRepository(service: service);
        final artisanRepo = ArtisanRepository(service: service);
        final authVM = AuthViewModel(repository: userRepo);
        final moderationVM = ModerationViewModel(repository: userRepo);
        final directoryVM = DirectoryViewModel(repository: artisanRepo);

        const villageArtisanWithCertInTags = UserModel(
          id: 'u_village_cert_tag_test',
          email: 'village_tag@warisankita.my',
          username: 'village_tag',
          displayName: 'Mak Cik Salmah',
          role: 'Artisan',
          roles: ['Artisan'],
          status: 'ACTIVE',
          artisanStatus: 'APPROVED',
          premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
          studioName: 'Bengkel Anyaman Salmah',
          craftCategory: 'Mengkuang Weaving',
          tags: [
            'doc_crafting_photo_url:https://example.com/craft_proof.jpg',
            'doc_kraftangan_cert_url:https://example.com/kraftangan_master.jpg',
          ],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wk_last_auth_user', jsonEncode(villageArtisanWithCertInTags.toMap()));
        await prefs.setString('wk_auth_email', villageArtisanWithCertInTags.email);
        await prefs.setString('wk_active_role', villageArtisanWithCertInTags.role);
        authVM.setCurrentUserForTesting(villageArtisanWithCertInTags);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
              ChangeNotifierProvider<ModerationViewModel>.value(value: moderationVM),
              ChangeNotifierProvider<DirectoryViewModel>.value(value: directoryVM),
              Provider<SupabaseService>.value(value: service),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ProfileBuilderTab(),
              ),
            ),
          ),
        );
        await tester.pump();
        while (tester.takeException() != null) {}

        // Both crafting photo and Kraftangan master cert are resolved and uploaded
        expect(find.text('Traditional Crafting Proof Photo'), findsOneWidget);
        expect(find.text('Kraftangan Malaysia Master Certification'), findsOneWidget);

        // Both buttons show 'VIEW' and zero 'UPLOAD' or 'UPLOADED'
        expect(find.text('VIEW'), findsNWidgets(2));
        expect(find.text('UPLOAD'), findsNothing);
        expect(find.text('UPLOADED'), findsNothing);

        // Tap VIEW on Kraftangan Master Cert
        await tester.tap(find.text('VIEW').last);
        await tester.pumpAndSettle();

        expect(find.text('Kraftangan Malaysia Master Certification'), findsNWidgets(2));
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close_rounded), findsNothing);
      });
    });
  });
}
