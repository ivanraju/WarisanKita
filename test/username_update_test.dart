import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Username Update & Authentication Tests', () {
    test('Changing username prevents old username from logging in and allows new username', () async {
      final service = SupabaseService();
      
      // 1. Initial login with seed username 'Aiman Haziq'
      final initialUser = await service.signIn('Aiman Haziq', 'password123');
      expect(initialUser.email, 'tourist@warisankita.my');

      // 2. Update username to 'aiman_cool'
      await service.updateUserProfile(
        email: 'tourist@warisankita.my',
        username: 'aiman_cool',
      );

      // 3. Try to log in with new username 'aiman_cool' -> MUST SUCCEED
      final newUser = await service.signIn('aiman_cool', 'password123');
      expect(newUser.email, 'tourist@warisankita.my');
      expect(newUser.username, 'aiman_cool');

      // 4. Try to log in with new handle '@aiman_cool' with mixed casing -> MUST SUCCEED
      final newUserWithAt = await service.signIn('@Aiman_Cool', 'password123');
      expect(newUserWithAt.email, 'tourist@warisankita.my');

      // 5. Try to log in with email -> MUST SUCCEED
      final userByEmail = await service.signIn('tourist@warisankita.my', 'password123');
      expect(userByEmail.email, 'tourist@warisankita.my');

      // 6. Try to log in with OLD username 'Aiman Haziq' -> MUST THROW EXCEPTION
      expect(
        () => service.signIn('Aiman Haziq', 'password123'),
        throwsA(isA<Exception>()),
      );

      // 7. Try to log in with old prefix or variations -> MUST THROW EXCEPTION
      expect(
        () => service.signIn('aiman', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('Username uniqueness validation rejects duplicate handles', () async {
      final service = SupabaseService();

      // Check against seed username
      final isAvailable = await service.isUsernameAvailable('Pak Mat');
      expect(isAvailable, false);

      final isAvailableWithAt = await service.isUsernameAvailable('@pak_mat');
      expect(isAvailableWithAt, false);

      // Check fresh unused username
      final isBrandNewAvailable = await service.isUsernameAvailable('@completely_new_handle_2026');
      expect(isBrandNewAvailable, true);

      // Updating to an existing handle throws error
      expect(
        () => service.updateUserProfile(
          email: 'tourist@warisankita.my',
          username: 'Pak Mat',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
