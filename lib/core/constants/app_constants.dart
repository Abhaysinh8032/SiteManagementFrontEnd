import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // ── Backend ───────────────────────────────────────────────────────────────
  // Change this to your Render URL in production
  // Use localhost for Web (browser), and the emulator host for Android.
  static String get baseUrl => kIsWeb
      ? 'https://sitemanagementbackend.onrender.com'
      : 'http://10.0.2.2:8081';
  static const int connectTimeoutMs = 60000;
  static const int receiveTimeoutMs = 60000;

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

  // Site endpoints
  static const String endpointSites = '/api/sites';
  static const String endpointSiteMembers = '/api/sites/{id}/members';

  // Task endpoints
  static const String endpointTasks = '/api/tasks';
  static const String endpointSiteTasks = '/api/tasks/site/{siteId}';
  static const String endpointAllActiveUsers = '/api/admin/users/active';

  // Routes
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeHome = '/home';
  static const String routeAdminHome = '/admin/home';
  static const String routeWorkerHome = '/worker/home';
}
