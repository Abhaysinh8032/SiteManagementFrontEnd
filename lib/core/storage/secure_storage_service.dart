import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
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
    // Safeguard: If the backend sends expiration in seconds (e.g., 3600 for 1 hr),
    // it needs to be converted to milliseconds. Anything less than 1 year in seconds (31536000)
    // is safely treated as seconds.
    final int safeExpiresInMs = expiresInMs < 31536000
        ? expiresInMs * 1000
        : expiresInMs;

    final expiry = DateTime.now().millisecondsSinceEpoch + safeExpiresInMs;
    await _storage.write(key: AppConstants.keyToken, value: token);
    await _storage.write(key: AppConstants.keyTokenExpiry, value: expiry.toString());
    await _storage.write(key: AppConstants.keyUserId, value: userId);
    await _storage.write(key: AppConstants.keyEmployeeId, value: employeeId);
    await _storage.write(key: AppConstants.keyUserName, value: userName);
    await _storage.write(key: AppConstants.keyUserRole, value: role);
    await _storage.write(key: AppConstants.keyUserStatus, value: status);
  }

  // ── Auto-login: returns token only if it hasn't expired ───────────────────

  Future<String?> getValidToken() async {
    try {
      final token = await _storage.read(key: AppConstants.keyToken);
      final expiry = await _storage.read(key: AppConstants.keyTokenExpiry);

      debugPrint('[SecureStorage] Checking token validity...');
      debugPrint(
        '[SecureStorage]   Token stored: ${token != null ? 'YES' : 'NO'}',
      );
      debugPrint(
        '[SecureStorage]   Expiry stored: ${expiry != null ? 'YES' : 'NO'}',
      );

      if (token == null || expiry == null) {
        debugPrint('[SecureStorage] ✗ Token or expiry missing');
        return null;
      }

      final expiryTime = int.tryParse(expiry) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiresInMs = expiryTime - nowMs;

      debugPrint(
        '[SecureStorage]   Expires in: ${expiresInMs}ms (${(expiresInMs / 60000).toStringAsFixed(1)} minutes)',
      );

      if (nowMs >= expiryTime - 60000) {
        debugPrint('[SecureStorage] ✗ Token expired - clearing session');
        await clearSession();
        return null;
      }

      debugPrint('[SecureStorage] ✓ Token is valid');
      return token;
    } catch (e) {
      debugPrint('[SecureStorage] ✗ ERROR reading token: $e');
      return null;
    }
  }

  // ── Read cached user info (for dashboard pre-fill) ────────────────────────

  Future<Map<String, String?>> getCachedUser() async {
    return {
      'userId': await _storage.read(key: AppConstants.keyUserId),
      'employeeId': await _storage.read(key: AppConstants.keyEmployeeId),
      'name': await _storage.read(key: AppConstants.keyUserName),
      'role': await _storage.read(key: AppConstants.keyUserRole),
      'status': await _storage.read(key: AppConstants.keyUserStatus),
    };
  }

  Future<String?> getRole() => _storage.read(key: AppConstants.keyUserRole);

  Future<void> clearSession() => _storage.deleteAll();
}
