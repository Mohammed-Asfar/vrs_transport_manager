import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// Auth
import 'package:vrs_transport_manager/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vrs_transport_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vrs_transport_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:vrs_transport_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:vrs_transport_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_bloc.dart';

// Transport
import 'package:vrs_transport_manager/features/transport/data/datasources/transport_remote_datasource.dart';
import 'package:vrs_transport_manager/features/transport/data/repositories/transport_repository_impl.dart';
import 'package:vrs_transport_manager/features/transport/domain/repositories/transport_repository.dart';
import 'package:vrs_transport_manager/features/transport/domain/usecases/transport_usecases.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ──── Firebase ────
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // ──── Auth Feature ────
  // Datasource
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasource(sl<FirebaseAuth>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDatasource>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ──── Transport Feature ────
  // Datasource
  sl.registerLazySingleton<TransportRemoteDatasource>(
    () => TransportRemoteDatasource(sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<TransportRepository>(
    () => TransportRepositoryImpl(sl<TransportRemoteDatasource>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetRecordsUseCase(sl<TransportRepository>()));
  sl.registerLazySingleton(() => GetRecordByIdUseCase(sl<TransportRepository>()));
  sl.registerLazySingleton(() => CreateRecordUseCase(sl<TransportRepository>()));
  sl.registerLazySingleton(() => UpdateRecordUseCase(sl<TransportRepository>()));
  sl.registerLazySingleton(() => DeleteRecordUseCase(sl<TransportRepository>()));
  sl.registerLazySingleton(() => SearchRecordsUseCase(sl<TransportRepository>()));

  // BLoC
  sl.registerFactory(
    () => TransportBloc(
      getRecords: sl<GetRecordsUseCase>(),
      createRecord: sl<CreateRecordUseCase>(),
      updateRecord: sl<UpdateRecordUseCase>(),
      deleteRecord: sl<DeleteRecordUseCase>(),
      searchRecords: sl<SearchRecordsUseCase>(),
      repository: sl<TransportRepository>(),
    ),
  );
}
