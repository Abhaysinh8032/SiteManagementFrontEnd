import 'package:dio/dio.dart';
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
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugLog(o.toString()),
    ));
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
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for public endpoints
    final isPublic = options.path == AppConstants.endpointLogin ||
        options.path == AppConstants.endpointSignup;

    if (!isPublic) {
      final token = await _storage.getValidToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token rejected by server — clear local session
      await _storage.clearSession();
    }
    handler.next(err);
  }
}
