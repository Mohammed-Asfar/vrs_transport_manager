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

// Reports
import 'package:vrs_transport_manager/features/reports/domain/usecases/generate_report_usecase.dart';
import 'package:vrs_transport_manager/features/reports/presentation/bloc/report_bloc.dart';

// Machinery
import 'package:vrs_transport_manager/features/machinery/data/datasources/machinery_remote_datasource.dart';
import 'package:vrs_transport_manager/features/machinery/data/repositories/machinery_repository_impl.dart';
import 'package:vrs_transport_manager/features/machinery/domain/repositories/machinery_repository.dart';
import 'package:vrs_transport_manager/features/machinery/domain/usecases/machinery_usecases.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/bloc/machinery_bloc.dart';

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

  // ──── Machinery Feature ────
  // Datasource
  sl.registerLazySingleton<MachineryRemoteDatasource>(
    () => MachineryRemoteDatasource(sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<MachineryRepository>(
    () => MachineryRepositoryImpl(sl<MachineryRemoteDatasource>()),
  );

  // Use Cases
  sl.registerLazySingleton(
      () => GetMachineryRecordsUseCase(sl<MachineryRepository>()));
  sl.registerLazySingleton(
      () => GetMachineryRecordByIdUseCase(sl<MachineryRepository>()));
  sl.registerLazySingleton(
      () => CreateMachineryRecordUseCase(sl<MachineryRepository>()));
  sl.registerLazySingleton(
      () => UpdateMachineryRecordUseCase(sl<MachineryRepository>()));
  sl.registerLazySingleton(
      () => DeleteMachineryRecordUseCase(sl<MachineryRepository>()));
  sl.registerLazySingleton(
      () => SearchMachineryRecordsUseCase(sl<MachineryRepository>()));

  // BLoC
  sl.registerFactory(
    () => MachineryBloc(
      getRecords: sl<GetMachineryRecordsUseCase>(),
      createRecord: sl<CreateMachineryRecordUseCase>(),
      updateRecord: sl<UpdateMachineryRecordUseCase>(),
      deleteRecord: sl<DeleteMachineryRecordUseCase>(),
      searchRecords: sl<SearchMachineryRecordsUseCase>(),
      repository: sl<MachineryRepository>(),
    ),
  );

  // ──── Reports Feature ────
  // Use Case
  sl.registerLazySingleton(
      () => GenerateReportUseCase(sl<TransportRepository>()));

  // BLoC
  sl.registerFactory(
    () => ReportBloc(generateReport: sl<GenerateReportUseCase>()),
  );
}
