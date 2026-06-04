import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String employeeId;
  final String password;
  const AuthLoginRequested({required this.employeeId, required this.password});
  @override
  List<Object?> get props => [employeeId, password];
}

class AuthSignupRequested extends AuthEvent {
  final String employeeId;
  final String name;
  final String password;
  final String role;
  final String? phoneNumber;
  const AuthSignupRequested({
    required this.employeeId,
    required this.name,
    required this.password,
    required this.role,
    this.phoneNumber,
  });
  @override
  List<Object?> get props => [employeeId, name, password, role];
}

class AuthCheckSessionRequested extends AuthEvent {
  const AuthCheckSessionRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial state — app just opened, checking local session
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking for existing valid token in secure storage
class AuthCheckingSession extends AuthState {
  const AuthCheckingSession();
}

/// API call in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Successfully authenticated
class AuthAuthenticated extends AuthState {
  final AuthResponse authResponse;
  const AuthAuthenticated(this.authResponse);
  @override
  List<Object?> get props => [authResponse];
}

/// Signed up but awaiting admin approval (WORKER PENDING)
class AuthPendingApproval extends AuthState {
  const AuthPendingApproval();
}

/// Not authenticated — show login screen
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthCheckSessionRequested>(_onCheckSession);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignupRequested>(_onSignup);
    on<AuthLogoutRequested>(_onLogout);
  }

  // ── Check session on app start ────────────────────────────────────────────

  Future<void> _onCheckSession(
      AuthCheckSessionRequested event, Emitter<AuthState> emit) async {
    debugPrint('[AuthBloc] 📥 AuthCheckSessionRequested');
    emit(const AuthCheckingSession());
    final role = await _repository.checkExistingSession();
    if (role != null) {
      debugPrint('[AuthBloc] ✓ Valid session found for role: $role');
      emit(const AuthUnauthenticated());
    } else {
      debugPrint('[AuthBloc] ✗ No valid session found');
      emit(const AuthUnauthenticated());
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> _onLogin(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    debugPrint('[AuthBloc] 📥 AuthLoginRequested for: ${event.employeeId}');
    emit(const AuthLoading());

    final result = await _repository.login(
      LoginRequest(
        employeeId: event.employeeId.trim(),
        password:   event.password,
      ),
    );

    if (result.isSuccess) {
      debugPrint('[AuthBloc] ✓ Login successful, emitting AuthAuthenticated');
      emit(AuthAuthenticated(result.data!));
    } else {
      debugPrint('[AuthBloc] ✗ Login failed: ${result.errorMessage}');
      emit(AuthError(result.errorMessage!));
    }
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<void> _onSignup(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    debugPrint('[AuthBloc] 📥 AuthSignupRequested for: ${event.employeeId}');
    emit(const AuthLoading());

    final result = await _repository.signup(
      SignupRequest(
        employeeId:  event.employeeId.trim(),
        name:        event.name.trim(),
        password:    event.password,
        role:        event.role,
        phoneNumber: event.phoneNumber?.trim(),
      ),
    );

    if (result.isSuccess) {
      debugPrint('[AuthBloc] ✓ Signup successful, emitting AuthAuthenticated');
      emit(AuthAuthenticated(result.data!));
    } else if (result.isPending) {
      debugPrint('[AuthBloc] ⏳ Signup pending approval');
      emit(const AuthPendingApproval());
    } else {
      debugPrint('[AuthBloc] ✗ Signup failed: ${result.errorMessage}');
      emit(AuthError(result.errorMessage!));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _onLogout(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }
}
