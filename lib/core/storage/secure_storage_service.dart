import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Handles all secure local persistence:
/// - JWT token + expiry (for auto-login without re-entering credentials)
/// - Basic user info (so dashboard loads instantly without extra API call)
///
/// Auto-login flow:
///   1. On app start, call [getValidToken] — returns token if valid, null if expired/missing
///   2. If token is valid → navigate directly to home (skip login screen)
///   3. If null → show login screen
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  // ── Save session after successful login / signup ──────────────────────────

  Future<void> saveSession({
    required String token,
    required int expiresInMs,
    required String userId,
    required String employeeId,
    required String userName,
    required String role,
    required String status,
  }) async {
    final expiryTimestamp =
        DateTime.now().millisecondsSinceEpoch + expiresInMs;

    await Future.wait([
      _storage.write(key: AppConstants.keyToken, value: token),
      _storage.write(key: AppConstants.keyTokenExpiry, value: expiryTimestamp.toString()),
      _storage.write(key: AppConstants.keyUserId, value: userId),
      _storage.write(key: AppConstants.keyEmployeeId, value: employeeId),
      _storage.write(key: AppConstants.keyUserName, value: userName),
      _storage.write(key: AppConstants.keyUserRole, value: role),
      _storage.write(key: AppConstants.keyUserStatus, value: status),
    ]);
  }

  // ── Auto-login: returns token only if it hasn't expired ───────────────────

  Future<String?> getValidToken() async {
    final token  = await _storage.read(key: AppConstants.keyToken);
    final expiry = await _storage.read(key: AppConstants.keyTokenExpiry);

    if (token == null || expiry == null) return null;

    final expiryTime = int.tryParse(expiry) ?? 0;
    final now        = DateTime.now().millisecondsSinceEpoch;

    // Add 60s buffer — don't use a token that expires in the next minute
    if (now >= expiryTime - 60000) {
      await clearSession(); // expired — clean up
      return null;
    }

    return token;
  }

  // ── Read cached user info (for dashboard pre-fill) ────────────────────────

  Future<Map<String, String?>> getCachedUser() async {
    return {
      'userId':     await _storage.read(key: AppConstants.keyUserId),
      'employeeId': await _storage.read(key: AppConstants.keyEmployeeId),
      'name':       await _storage.read(key: AppConstants.keyUserName),
      'role':       await _storage.read(key: AppConstants.keyUserRole),
      'status':     await _storage.read(key: AppConstants.keyUserStatus),
    };
  }

  Future<String?> getRole() =>
      _storage.read(key: AppConstants.keyUserRole);

  // ── Clear on logout ───────────────────────────────────────────────────────

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
