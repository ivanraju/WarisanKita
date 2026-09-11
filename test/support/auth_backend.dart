import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-process HTTP backend: exercises the real Supabase SDK without live accounts.
class AuthBackend {
  final accounts = <String, Map<String, dynamic>>{};
  final requests = <http.Request>[];
  final failures = <String, String>{};
  late final client = SupabaseClient(
    'https://auth.test',
    'test-key',
    httpClient: MockClient(_respond),
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );
  String? activeEmail;
  int passwordUpdates = 0;
  String? usernameFilter;
  bool confirmOnSignup = false;

  Map<String, dynamic> add(
    String email, {
    String username = 'tester',
    String role = 'Tourist',
    bool confirmed = true,
    String password = 'Password123!',
  }) {
    return accounts[email] = {
      'id': 'user-${accounts.length + 1}',
      'email': email,
      'username': username,
      'role': role,
      'roles': [role],
      'status': 'ACTIVE',
      'confirmed': confirmed,
      'password': password,
    };
  }

  Map<String, dynamic> _user(Map<String, dynamic> row) => {
    'id': row['id'],
    'email': row['email'],
    'aud': 'authenticated',
    'created_at': '2026-01-01T00:00:00Z',
    'email_confirmed_at': row['confirmed'] == true
        ? '2026-01-01T00:00:00Z'
        : null,
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  };

  Map<String, dynamic> _session(Map<String, dynamic> row) {
    activeEmail = row['email'] as String;
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': row['id'],
              'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            }),
          ),
        )
        .replaceAll('=', '');
    return {
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.signature',
      'token_type': 'bearer',
      'refresh_token': 'refresh',
      'expires_in': 3600,
      'user': _user(row),
    };
  }

  http.Response _json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    request: requests.last,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _respond(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    final failure = failures['${request.method} $path'] ?? failures[path];
    if (failure != null) {
      return _json({'msg': failure, 'message': failure}, 400);
    }
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    if (path.endsWith('/signup')) {
      final email = body['email'] as String;
      if (accounts.containsKey(email))
        return _json({'msg': 'User already registered'}, 400);
      final data = body['data'] as Map<String, dynamic>;
      final row = add(
        email,
        username: data['username'] as String,
        role: data['role'] as String,
        confirmed: confirmOnSignup,
        password: body['password'] as String,
      );
      return _json(confirmOnSignup ? _session(row) : _user(row));
    }
    if (path.endsWith('/token')) {
      final row = accounts[body['email']];
      if (row == null || row['password'] != body['password']) {
        return _json({'msg': 'Invalid login credentials'}, 400);
      }
      if (row['confirmed'] != true)
        return _json({'msg': 'Email not confirmed'}, 400);
      return _json(_session(row));
    }
    if (path.endsWith('/verify')) {
      final row = accounts[body['email']];
      if (row == null || body['token'] != '654321') {
        return _json({'msg': 'Token has expired or is invalid'}, 400);
      }
      row['confirmed'] = true;
      return _json(_session(row));
    }
    if (path == '/auth/v1/user') {
      final row = accounts[activeEmail];
      if (row == null) return _json({'msg': 'Session missing'}, 401);
      if (request.method == 'PUT' && body['password'] != null) {
        if (row['password'] == body['password'])
          return _json({'msg': 'New password should be different'}, 400);
        passwordUpdates++;
        row['password'] = body['password'];
      }
      return _json(_user(row));
    }
    if (path.endsWith('/logout') ||
        path.endsWith('/recover') ||
        path.endsWith('/resend')) {
      return _json({});
    }
    if (path.endsWith('/rpc/delete_user_account')) {
      accounts.removeWhere((_, row) => row['id'] == body['p_user_id']);
      return _json({'success': true});
    }
    if (path.endsWith('/rpc/deactivate_artisan_studio')) {
      final uid = body['p_user_id'];
      for (final row in accounts.values) {
        if (row['id'] == uid) {
          row['role'] = 'Tourist';
          row['roles'] = ['Tourist'];
          row['studio_name'] = null;
          row['craft_category'] = null;
          row['ssm_number'] = null;
          row['artisan_status'] = 'CLOSED';
        }
      }
      return _json({'success': true});
    }
    if (path.endsWith('/rpc/admin_update_user_status')) {
      final email = body['p_email'];
      final role = body['p_role'];
      final status = body['p_status'];
      if (email != null) {
        final row = accounts[email.toString().toLowerCase()];
        if (row != null) {
          if (role != null) {
            row['role'] = role;
            row['roles'] = [role];
          }
          if (status != null) {
            final s = status.toString().toUpperCase();
            if (s == 'ACTIVE' || s == 'APPROVED') {
              if (role == 'Artisan') {
                row['artisan_status'] = 'APPROVED';
              }
              row['status'] = 'ACTIVE';
            } else if (s == 'REJECTED') {
              row['artisan_status'] = 'REJECTED';
              if (role == 'Tourist' ||
                  (role == null &&
                      (row['role']?.toString().contains('Tourist') ?? false))) {
                row['status'] = 'ACTIVE';
              } else {
                row['status'] = 'REJECTED';
              }
            } else {
              row['status'] = status;
              row['artisan_status'] = status;
            }
          }
          if (role == 'Tourist' && status == null) {
            row['studio_name'] = null;
            row['craft_category'] = null;
            row['ssm_number'] = null;
            row['artisan_status'] = 'CLOSED';
          }
        }
      }
      return _json({});
    }
    if (path == '/rest/v1/users') {
      if (request.method == 'PATCH') {
        final query = request.url.queryParameters;
        final idFilter = query['id']?.replaceFirst('eq.', '');
        final emailFilter = query['email']?.replaceFirst('ilike.', '').replaceFirst('eq.', '');
        if (idFilter != null) {
          for (final row in accounts.values) {
            if (row['id'] == idFilter) {
              row.addAll(body);
            }
          }
        } else if (emailFilter != null) {
          for (final row in accounts.values) {
            if (row['email'].toString().toLowerCase() == emailFilter.toLowerCase()) {
              row.addAll(body);
            }
          }
        }
        return _json([]);
      }
      final query = request.url.queryParameters;
      // Match the deployed schema: explicit selection of this optional column
      // must fail instead of being silently accepted by our test backend.
      if ((query['select'] ?? '').contains('is_suspended')) {
        return _json({
          'code': '42703',
          'message': 'column users.is_suspended does not exist',
        }, 400);
      }
      usernameFilter = query['username'] ?? usernameFilter;
      var rows = accounts.values
          .where((row) {
            for (final field in ['id', 'email', 'username']) {
              final filter = query[field];
              if (filter != null) {
                final expected = filter
                    .substring(filter.indexOf('.') + 1)
                    .replaceAll(r'\_', '_')
                    .replaceAll(r'\%', '%');
                if (row[field].toString().toLowerCase() !=
                    expected.toLowerCase())
                  return false;
              }
            }
            return true;
          })
          .map(
            (row) => Map<String, dynamic>.from(row)
              ..remove('password')
              ..remove('confirmed'),
          )
          .toList();
      return _json(rows);
    }
    if (path == '/rest/v1/artisan_profiles') {
      if (request.method == 'POST') {
        if (request.headers['accept']?.contains('vnd.pgrst.object') == true) {
          return _json({'id': 'ap-test-1', ...body});
        }
        return _json([{'id': 'ap-test-1', ...body}]);
      }
      return _json([]);
    }
    if (path == '/rest/v1/artisan_documents' ||
        path == '/rest/v1/quests') return _json([]);
    throw StateError('Unexpected request: ${request.method} ${request.url}');
  }
}
