import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_models.dart';

/// All results come back as [AuthResult] — a simple sealed-class style
/// that avoids throwing exceptions through the UI layer.
class AuthResult {
  final AuthResponse? data;
  final String? errorMessage;
  final bool isPending; // worker registered but needs admin approval

  const AuthResult._({this.data, this.errorMessage, this.isPending = false});

  factory AuthResult.success(AuthResponse data) => AuthResult._(data: data);

  factory AuthResult.pending() => const AuthResult._(
    isPending: true,
    errorMessage: 'Your account is awaiting supervisor approval.',
  );

  factory AuthResult.failure(String message) =>
      AuthResult._(errorMessage: message);

  bool get isSuccess => data != null;
}

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository({required SecureStorageService storage})
    : _dio = ApiClient.instance.dio,
      _storage = storage;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<AuthResult> login(LoginRequest request) async {
    try {
      debugPrint(
        '[AuthRepository] 📥 Login requested for: ${request.employeeId}',
      );
      final response = await _dio.post(
        AppConstants.endpointLogin,
        data: request.toJson(),
      );

      debugPrint('[AuthRepository] ✓ Login successful');
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _persistSession(authResponse);
      return AuthResult.success(authResponse);
    } on DioException catch (e) {
      final errorMsg = _parseDioError(e);
      debugPrint('[AuthRepository] ✗ Login failed: $errorMsg');
      return AuthResult.failure(errorMsg);
    } catch (e) {
      debugPrint('[AuthRepository] ✗ Unexpected error during login: $e');
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<AuthResult> signup(SignupRequest request) async {
    try {
      debugPrint(
        '[AuthRepository] 📥 Signup requested for: ${request.employeeId}',
      );
      final response = await _dio.post(
        AppConstants.endpointSignup,
        data: request.toJson(),
      );

      final body = response.data as Map<String, dynamic>;

      // Worker pending case: success=true but no token in data yet
      // Check if data contains a token — if not, user is PENDING
      final dataMap = body['data'] as Map<String, dynamic>?;
      if (dataMap == null || !dataMap.containsKey('token')) {
        debugPrint(
          '[AuthRepository] ⏳ Signup successful but account pending approval',
        );
        return AuthResult.pending();
      }

      debugPrint('[AuthRepository] ✓ Signup successful');
      final authResponse = AuthResponse.fromSignupJson(body);
      await _persistSession(authResponse);
      return AuthResult.success(authResponse);
    } on DioException catch (e) {
      final errorMsg = _parseDioError(e);
      debugPrint('[AuthRepository] ✗ Signup failed: $errorMsg');
      return AuthResult.failure(errorMsg);
    } catch (e) {
      debugPrint('[AuthRepository] ✗ Unexpected error during signup: $e');
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ── Auto-login check ──────────────────────────────────────────────────────

  /// Called on app start. Returns stored role if session is still valid.
  /// Returns null if user needs to log in again.
  Future<String?> checkExistingSession() async {
    final token = await _storage.getValidToken();
    if (token == null) return null;
    return _storage.getRole();
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.clearSession();
    // TODO: Cycle 2 — call POST /api/auth/logout to invalidate server-side
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _persistSession(AuthResponse auth) async {
    debugPrint('[AuthRepository] 💾 Saving session...');
    debugPrint(
      '[AuthRepository]   Token: ${auth.token.substring(0, 20)}... (${auth.token.length} chars)',
    );
    debugPrint('[AuthRepository]   Expires in: ${auth.expiresInMs}ms');
    debugPrint(
      '[AuthRepository]   User: ${auth.user.name} (${auth.user.role})',
    );

    await _storage.saveSession(
      token: auth.token,
      expiresInMs: auth.expiresInMs,
      userId: auth.user.id,
      employeeId: auth.user.employeeId,
      userName: auth.user.name,
      role: auth.user.role,
      status: auth.user.status,
    );

    debugPrint('[AuthRepository] ✓ Session saved successfully');
  }

  String _parseDioError(DioException e) {
    if (e.response != null) {
      final body = e.response!.data;
      if (body is Map) {
        final msg = body['message'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
      }
      switch (e.response!.statusCode) {
        case 401:
          return 'Invalid Employee ID or password.';
        case 403:
          return 'Access denied. Check your account status.';
        case 409:
          return 'Employee ID already registered.';
        default:
          return 'Request failed (${e.response!.statusCode}).';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your internet connection.';
    }
    return 'Network error. Please try again.';
  }
}
