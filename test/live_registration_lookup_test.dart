import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';

// Opt-in read-only smoke test. Never creates accounts or sends email.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('deployed backend detects existing username and email', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    SharedPreferences.setMockInitialValues({});
    final source = File('lib/main.dart').readAsStringSync();
    final url = RegExp("url: '([^']+)'").firstMatch(source)!.group(1)!;
    final key = RegExp("publishableKey: '([^']+)'").firstMatch(source)!.group(1)!;
    final client = SupabaseClient(url, key,
      authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    final rows = await client.from('users').select('email, username')
        .not('username', 'is', null).neq('status', 'DELETED').limit(1);
    expect(rows.isNotEmpty, isTrue, reason: 'A registered account is needed for this read-only check.');
    final email = rows.first['email'] as String;
    final username = rows.first['username'] as String;
    final service = SupabaseService(client: client);
    expect(await service.isUsernameAvailable(username), isFalse);
    expect((await service.checkExistingAccount(email)).exists, isTrue);
    expect(await service.isUsernameAvailable(username.toUpperCase()), isFalse);
    expect((await service.checkExistingAccount(email.toUpperCase())).exists, isTrue);
  }, skip: !const bool.fromEnvironment('RUN_LIVE_LOOKUP'));
}
