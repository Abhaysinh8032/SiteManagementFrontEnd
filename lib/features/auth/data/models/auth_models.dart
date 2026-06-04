// ─────────────────────────────────────────────────────────────────────────────
// Request models
// ─────────────────────────────────────────────────────────────────────────────

class LoginRequest {
  final String employeeId;
  final String password;
  final String? fcmToken;
  const LoginRequest({required this.employeeId, required this.password, this.fcmToken});
  Map<String, dynamic> toJson() => {
    'employeeId': employeeId, 'password': password,
    if (fcmToken != null) 'fcmToken': fcmToken,
  };
}

class SignupRequest {
  final String employeeId;
  final String name;
  final String password;
  final String role; // "ADMIN" | "WORKER"
  final String? phoneNumber;
  final String? fcmToken;

  const SignupRequest({
    required this.employeeId,
    required this.name,
    required this.password,
    required this.role,
    this.phoneNumber,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'name': name,
        'password': password,
        'role': role,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Response models
// ─────────────────────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String employeeId;
  final String name;
  final String role;   // "ADMIN" | "WORKER"
  final String status; // "ACTIVE" | "PENDING" | etc.

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:         json['id'] as String,
        employeeId: json['employeeId'] as String,
        name:       json['name'] as String,
        role:       json['role'] as String,
        status:     json['status'] as String,
      );

  bool get isAdmin  => role == 'ADMIN';
  bool get isActive => status == 'ACTIVE';
}

class AuthResponse {
  final String token;
  final String tokenType;
  final int expiresInMs;
  final UserModel user;

  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.expiresInMs,
    required this.user,
  });

  /// Parses the direct login response:
  /// { "token": "...", "tokenType": "Bearer", "expiresInMs": 86400000, "user": {...} }
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token:       json['token'] as String,
        tokenType:   json['tokenType'] as String,
        expiresInMs: json['expiresInMs'] as int,
        user:        UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );

  /// Parses the signup wrapper response:
  /// { "success": true, "message": "...", "data": { "token": ..., "user": ... } }
  factory AuthResponse.fromSignupJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }
}
