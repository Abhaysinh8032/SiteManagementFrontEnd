import 'package:dio/dio.dart';
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

  factory AuthResult.success(AuthResponse data) =>
      AuthResult._(data: data);

  factory AuthResult.pending() =>
      AuthResult._(isPending: true,
          errorMessage: 'Your account is awaiting supervisor approval.');

  factory AuthResult.failure(String message) =>
      AuthResult._(errorMessage: message);

  bool get isSuccess => data != null;
}

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository({
    required SecureStorageService storage,
  })  : _dio     = ApiClient.instance.dio,
        _storage = storage;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<AuthResult> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointLogin,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(
          response.data as Map<String, dynamic>);

      await _persistSession(authResponse);
      return AuthResult.success(authResponse);
    } on DioException catch (e) {
      return AuthResult.failure(_parseDioError(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<AuthResult> signup(SignupRequest request) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointSignup,
        data: request.toJson(),
      );

      final body = response.data as Map<String, dynamic>;

      // Worker pending case: success=true but no token in data yet
      // Check if data contains a token — if not, user is PENDING
      final dataMap = body['data'] as Map<String, dynamic>?;
      if (dataMap == null || !dataMap.containsKey('token')) {
        return AuthResult.pending();
      }

      final authResponse = AuthResponse.fromSignupJson(body);
      await _persistSession(authResponse);
      return AuthResult.success(authResponse);
    } on DioException catch (e) {
      return AuthResult.failure(_parseDioError(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred. Please try again.');
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
    await _storage.saveSession(
      token:       auth.token,
      expiresInMs: auth.expiresInMs,
      userId:      auth.user.id,
      employeeId:  auth.user.employeeId,
      userName:    auth.user.name,
      role:        auth.user.role,
      status:      auth.user.status,
    );
  }

  String _parseDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final body       = e.response!.data;

      // Try to extract backend message from response body
      String? backendMessage;
      if (body is Map) {
        backendMessage = body['message'] as String?;
      }

      if (backendMessage != null && backendMessage.isNotEmpty) {
        return backendMessage;
      }

      switch (statusCode) {
        case 400: return 'Invalid request. Please check your inputs.';
        case 401: return 'Invalid Employee ID or password.';
        case 403: return backendMessage ?? 'Access denied. Check your account status.';
        case 404: return 'Service not found. Please contact support.';
        case 409: return 'Employee ID already registered.';
        case 500: return 'Server error. Please try again later.';
        default:  return 'Request failed (code $statusCode).';
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your internet connection.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your internet connection.';
    }

    return 'Network error. Please try again.';
  }
}
