import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:vrs_transport_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vrs_transport_manager/features/auth/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepository _authRepository;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // On Windows, Firebase C++ SDK may not have restored the session yet.
    // Wait briefly then check, and also listen for a delayed auth restoration.
    var user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
      return;
    }

    // Wait for up to 3 seconds for Firebase to restore the session
    try {
      user = await _authRepository.authStateChanges
          .where((u) => u != null)
          .first
          .timeout(const Duration(seconds: 3));
      if (user != null) {
        emit(AuthAuthenticated(user));
        return;
      }
    } catch (_) {
      // Timeout — no session restored
    }

    emit(const AuthUnauthenticated());
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _logoutUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

}
