import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';

/// Singleton Dio client.
/// - Automatically attaches  Authorization: Bearer <token>  to every request.
/// - On 401, clears local session (token expired/revoked on server side).
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;
  late final SecureStorageService _storage;

  void init(SecureStorageService storage) {
    _storage = storage;
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[ApiClient] $o'),
      ),
    );
  }

  Dio get dio => _dio;

  void debugLog(String msg) {
    // Replace with logger package in production
    // ignore: avoid_print
    print('[ApiClient] $msg');
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    final isPublic =
        options.path == AppConstants.endpointLogin ||
        options.path == AppConstants.endpointSignup;

    debugPrint('[AuthInterceptor] Request to: ${options.path}');

    if (!isPublic) {
      final token = await _storage.getValidToken();
      debugPrint(
        '[AuthInterceptor] Token retrieved: ${token != null ? 'YES (${token.length} chars)' : 'NO - TOKEN IS NULL'}',
      );

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('[AuthInterceptor] Authorization header added');
      } else {
        debugPrint(
          '[AuthInterceptor] ⚠️ NO TOKEN AVAILABLE - request will fail with 401',
        );
      }
    } else {
      debugPrint('[AuthInterceptor] Public endpoint - skipping auth header');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint(
      '[AuthInterceptor] Error: ${err.response?.statusCode} - ${err.message}',
    );

    if (err.response?.statusCode == 401) {
      debugPrint('[AuthInterceptor] ⚠️ 401 UNAUTHORIZED - clearing session');
      await _storage.clearSession();
    }
    handler.next(err);
  }
}
