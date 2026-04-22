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

// Client
import 'package:vrs_transport_manager/features/client/data/datasources/client_remote_datasource.dart';
import 'package:vrs_transport_manager/features/client/data/repositories/client_repository_impl.dart';
import 'package:vrs_transport_manager/features/client/domain/repositories/client_repository.dart';
import 'package:vrs_transport_manager/features/client/domain/usecases/client_usecases.dart';
import 'package:vrs_transport_manager/features/client/presentation/bloc/client_bloc.dart';

// Invoice
import 'package:vrs_transport_manager/features/invoice/data/datasources/invoice_remote_datasource.dart';
import 'package:vrs_transport_manager/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:vrs_transport_manager/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:vrs_transport_manager/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_bloc.dart';

// Payment
import 'package:vrs_transport_manager/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:vrs_transport_manager/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:vrs_transport_manager/features/payment/domain/repositories/payment_repository.dart';
import 'package:vrs_transport_manager/features/payment/domain/usecases/payment_usecases.dart';
import 'package:vrs_transport_manager/features/payment/presentation/bloc/payment_bloc.dart';

// Settings
import 'package:vrs_transport_manager/features/settings/data/datasources/company_profile_remote_datasource.dart';
import 'package:vrs_transport_manager/features/settings/data/repositories/company_profile_repository_impl.dart';
import 'package:vrs_transport_manager/features/settings/domain/repositories/company_profile_repository.dart';
import 'package:vrs_transport_manager/features/settings/domain/usecases/company_profile_usecases.dart';
import 'package:vrs_transport_manager/features/settings/presentation/bloc/company_profile_bloc.dart';

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

  // ──── Invoice Feature ────
  // Datasource
  sl.registerLazySingleton<InvoiceRemoteDatasource>(
    () => InvoiceRemoteDatasource(sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(sl<InvoiceRemoteDatasource>()),
  );

  // Use Cases
  sl.registerLazySingleton(
      () => GetInvoicesUseCase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(
      () => GetInvoiceByIdUseCase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(
      () => CreateInvoiceUseCase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(
      () => UpdateInvoiceUseCase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(
      () => DeleteInvoiceUseCase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(
      () => SearchInvoicesUseCase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(
      () => PreviewInvoiceNumberUseCase(sl<InvoiceRepository>()));
  sl.registerLazySingleton(
      () => CommitInvoiceNumberUseCase(sl<InvoiceRepository>()));

  // BLoC
  sl.registerFactory(
    () => InvoiceBloc(
      getInvoices: sl<GetInvoicesUseCase>(),
      createInvoice: sl<CreateInvoiceUseCase>(),
      updateInvoice: sl<UpdateInvoiceUseCase>(),
      deleteInvoice: sl<DeleteInvoiceUseCase>(),
      searchInvoices: sl<SearchInvoicesUseCase>(),
      commitInvoiceNumber: sl<CommitInvoiceNumberUseCase>(),
      repository: sl<InvoiceRepository>(),
    ),
  );

  // ──── Client Feature ────
  // Datasource
  sl.registerLazySingleton<ClientRemoteDatasource>(
    () => ClientRemoteDatasource(sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<ClientRepository>(
    () => ClientRepositoryImpl(sl<ClientRemoteDatasource>()),
  );

  // Use Cases
  sl.registerLazySingleton(
      () => GetClientsUseCase(sl<ClientRepository>()));
  sl.registerLazySingleton(
      () => CreateClientUseCase(sl<ClientRepository>()));

  // BLoC
  sl.registerFactory(
    () => ClientBloc(
      getClients: sl<GetClientsUseCase>(),
      createClient: sl<CreateClientUseCase>(),
    ),
  );

  // ──── Settings Feature ────
  // Datasource
  sl.registerLazySingleton<CompanyProfileRemoteDatasource>(
    () => CompanyProfileRemoteDatasource(sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<CompanyProfileRepository>(
    () => CompanyProfileRepositoryImpl(sl<CompanyProfileRemoteDatasource>()),
  );

  // Use Cases
  sl.registerLazySingleton(
      () => GetCompanyProfileUseCase(sl<CompanyProfileRepository>()));
  sl.registerLazySingleton(
      () => SaveCompanyProfileUseCase(sl<CompanyProfileRepository>()));

  // BLoC
  sl.registerFactory(
    () => CompanyProfileBloc(
      getProfile: sl<GetCompanyProfileUseCase>(),
      saveProfile: sl<SaveCompanyProfileUseCase>(),
    ),
  );

  // ──── Payment Feature ────
  // Datasource
  sl.registerLazySingleton<PaymentRemoteDatasource>(
    () => PaymentRemoteDatasource(sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl<PaymentRemoteDatasource>()),
  );

  // Use Cases
  sl.registerLazySingleton(
      () => GetPaymentsUseCase(sl<PaymentRepository>()));
  sl.registerLazySingleton(
      () => GetPaymentsForDateRangeUseCase(sl<PaymentRepository>()));
  sl.registerLazySingleton(
      () => CreatePaymentUseCase(sl<PaymentRepository>()));
  sl.registerLazySingleton(
      () => DeletePaymentUseCase(sl<PaymentRepository>()));

  // BLoC
  sl.registerFactory(
    () => PaymentBloc(
      getPayments: sl<GetPaymentsUseCase>(),
      getPaymentsForDateRange: sl<GetPaymentsForDateRangeUseCase>(),
      createPayment: sl<CreatePaymentUseCase>(),
      deletePayment: sl<DeletePaymentUseCase>(),
      repository: sl<PaymentRepository>(),
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
