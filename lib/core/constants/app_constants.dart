import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // ── Backend ───────────────────────────────────────────────────────────────
  // Change this to your Render URL in production
  // Use localhost for Web (browser), and the emulator host for Android.
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8081';
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // ── Secure storage keys ────────────────────────────────────────────────────
  static const String keyToken = 'auth_token';
  static const String keyTokenExpiry = 'auth_token_expiry';
  static const String keyUserId = 'user_id';
  static const String keyEmployeeId = 'employee_id';
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';
  static const String keyUserStatus = 'user_status';

  // ── API endpoints ─────────────────────────────────────────────────────────
  static const String endpointLogin = '/api/auth/login';
  static const String endpointSignup = '/api/auth/signup';

  // ── Routes ────────────────────────────────────────────────────────────────
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeAdminHome = '/admin/home';
  static const String routeWorkerHome = '/worker/home';
}
