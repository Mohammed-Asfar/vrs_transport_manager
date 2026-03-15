import 'package:dartz/dartz.dart';
import 'package:vrs_transport_manager/core/errors/failures.dart';
import 'package:vrs_transport_manager/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<AppUser?> get authStateChanges;

  /// Get currently signed-in user
  AppUser? get currentUser;

  /// Sign in with email and password
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();
}
