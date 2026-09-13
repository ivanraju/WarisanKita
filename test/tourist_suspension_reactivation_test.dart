import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/ui/artisan/artisan_main_scaffold.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'support/auth_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthBackend backend;
  late SupabaseService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = AuthBackend();
    service = SupabaseService(client: backend.client);
  });

  tearDown(() async => backend.client.dispose());

  test('reactivating a suspended tourist preserves Tourist role and does not create an artisan profile', () async {
    final touristUser = const UserModel(
      id: 'tourist-user-123',
      email: 'tourist@example.com',
      username: 'tourist_malaysia',
      displayName: 'Ahmad Explorer',
      role: 'Tourist',
      roles: ['Tourist'],
      status: 'ACTIVE',
      artisanStatus: null,
    );

    final repo = UserRepository(service: service);
    final modVM = ModerationViewModel(repository: repo);
    await modVM.refreshAllData();

    modVM.addUserForTesting(touristUser);

    // 1. Admin suspends the tourist
    await modVM.suspendUser('tourist-user-123', reason: 'Conduct review');
    final suspendedUser = modVM.registeredUsers.firstWhere((u) => u.id == 'tourist-user-123');
    expect(suspendedUser.isSuspended, isTrue);
    expect(suspendedUser.status, 'SUSPENDED');
    expect(suspendedUser.role, 'Tourist');
    expect(suspendedUser.artisanStatus, isNull);
    expect(suspendedUser.isApprovedArtisan, isFalse);

    // 2. Admin reactivates (unsuspends) the tourist
    await modVM.reactivateUser('tourist-user-123');
    final reactivatedUser = modVM.registeredUsers.firstWhere((u) => u.id == 'tourist-user-123');
    expect(reactivatedUser.isSuspended, isFalse);
    expect(reactivatedUser.status, 'ACTIVE');
    expect(reactivatedUser.role, 'Tourist');
    expect(reactivatedUser.artisanStatus, isNull);
    expect(reactivatedUser.isApprovedArtisan, isFalse);
    expect(reactivatedUser.isArtisan, isFalse);
    expect(reactivatedUser.studioName, isNull);
  });

  testWidgets('ArtisanMainScaffold redirects a Tourist user back to /tourist', (tester) async {
    final touristUser = const UserModel(
      id: 'tourist-user-456',
      email: 'explorer@example.com',
      username: 'explorer',
      displayName: 'Explorer User',
      role: 'Tourist',
      roles: ['Tourist'],
      status: 'ACTIVE',
      artisanStatus: null,
    );

    final repo = UserRepository(service: service);
    final authVM = AuthViewModel(repository: repo);
    authVM.setCurrentUserForTesting(touristUser);

    bool redirectedToTourist = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
        ],
        child: MaterialApp(
          routes: {
            '/tourist': (_) {
              redirectedToTourist = true;
              return const Scaffold(body: Text('Tourist Home'));
            },
          },
          home: const ArtisanMainScaffold(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(redirectedToTourist, isTrue);
    expect(find.text('Tourist Home'), findsOneWidget);
    expect(find.byType(ArtisanMainScaffold), findsNothing);
  });
}
