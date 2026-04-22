import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/core/widgets/main_shell.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:vrs_transport_manager/features/auth/presentation/pages/login_page.dart';
import 'package:vrs_transport_manager/features/reports/presentation/bloc/report_bloc.dart';
import 'package:vrs_transport_manager/features/reports/presentation/pages/report_page.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/usecases/transport_usecases.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_bloc.dart';
import 'package:vrs_transport_manager/features/transport/presentation/pages/dashboard_page.dart';
import 'package:vrs_transport_manager/features/transport/presentation/pages/record_detail_page.dart';
import 'package:vrs_transport_manager/features/transport/presentation/pages/record_form_page.dart';
import 'package:vrs_transport_manager/features/machinery/domain/entities/machinery_record.dart';
import 'package:vrs_transport_manager/features/machinery/domain/usecases/machinery_usecases.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/bloc/machinery_bloc.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/pages/machinery_list_page.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/pages/machinery_form_page.dart';
import 'package:vrs_transport_manager/features/machinery/presentation/pages/machinery_detail_page.dart';
import 'package:vrs_transport_manager/features/invoice/domain/entities/invoice_record.dart';
import 'package:vrs_transport_manager/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/pages/invoice_form_page.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/pages/invoice_detail_page.dart';
import 'package:vrs_transport_manager/features/invoice/presentation/pages/invoice_list_page.dart';
import 'package:vrs_transport_manager/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:vrs_transport_manager/features/payment/presentation/pages/payment_list_page.dart';
import 'package:vrs_transport_manager/features/settings/presentation/bloc/company_profile_bloc.dart';
import 'package:vrs_transport_manager/features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthNotifier(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isSplash = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';

      // While auth is loading, stay on splash
      if (authState is AuthInitial || authState is AuthLoading) {
        return isSplash ? null : '/splash';
      }

      final isAuthenticated = authState is AuthAuthenticated;

      // Auth resolved — leave splash
      if (isSplash) {
        return isAuthenticated ? '/' : '/login';
      }

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated && isLoginRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // ──── Shell with sidebar ────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<TransportBloc>(),
                child: const DashboardPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<ReportBloc>()),
                  BlocProvider(create: (_) => sl<PaymentBloc>()),
                ],
                child: const ReportPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/create',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<TransportBloc>(),
                child: const RecordFormPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/edit/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeTransition(
                state,
                BlocProvider(
                  create: (_) => sl<TransportBloc>(),
                  child: FutureBuilder<TransportRecord?>(
                    future: _loadRecord(id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('Error')),
                          body: Center(
                            child: Text(
                                'Failed to load record: ${snapshot.error}'),
                          ),
                        );
                      }
                      return RecordFormPage(existingRecord: snapshot.data);
                    },
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/detail/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeTransition(
                state,
                BlocProvider(
                  create: (_) => sl<TransportBloc>(),
                  child: RecordDetailPage(recordId: id),
                ),
              );
            },
          ),

          // ──── Machinery Routes ────
          GoRoute(
            path: '/machinery',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<MachineryBloc>(),
                child: const MachineryListPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/machinery/create',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<MachineryBloc>(),
                child: const MachineryFormPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/machinery/edit/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeTransition(
                state,
                BlocProvider(
                  create: (_) => sl<MachineryBloc>(),
                  child: FutureBuilder<MachineryRecord?>(
                    future: _loadMachineryRecord(id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('Error')),
                          body: Center(
                            child: Text(
                                'Failed to load record: ${snapshot.error}'),
                          ),
                        );
                      }
                      return MachineryFormPage(existingRecord: snapshot.data);
                    },
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/machinery/detail/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeTransition(
                state,
                BlocProvider(
                  create: (_) => sl<MachineryBloc>(),
                  child: MachineryDetailPage(recordId: id),
                ),
              );
            },
          ),

          // ──── Invoice Routes ────
          GoRoute(
            path: '/invoices',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<InvoiceBloc>(),
                child: const InvoiceListPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/invoices/create',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<InvoiceBloc>(),
                child: const InvoiceFormPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/invoices/edit/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeTransition(
                state,
                BlocProvider(
                  create: (_) => sl<InvoiceBloc>(),
                  child: FutureBuilder<InvoiceRecord?>(
                    future: _loadInvoice(id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('Error')),
                          body: Center(
                            child: Text(
                                'Failed to load invoice: ${snapshot.error}'),
                          ),
                        );
                      }
                      return InvoiceFormPage(existingRecord: snapshot.data);
                    },
                  ),
                ),
              );
            },
          ),

          GoRoute(
            path: '/invoices/detail/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _fadeTransition(
                state,
                BlocProvider(
                  create: (_) => sl<InvoiceBloc>(),
                  child: InvoiceDetailPage(recordId: id),
                ),
              );
            },
          ),

          // ──── Payment Routes ────
          GoRoute(
            path: '/payments',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<PaymentBloc>(),
                child: const PaymentListPage(),
              ),
            ),
          ),

          // ──── Settings Route ────
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _fadeTransition(
              state,
              BlocProvider(
                create: (_) => sl<CompanyProfileBloc>(),
                child: const SettingsPage(),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  static CustomTransitionPage<void> _fadeTransition(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 100),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Future<TransportRecord?> _loadRecord(String id) async {
    final result = await sl<GetRecordByIdUseCase>()(id);
    return result.fold((_) => null, (record) => record);
  }

  Future<InvoiceRecord?> _loadInvoice(String id) async {
    final result = await sl<GetInvoiceByIdUseCase>()(id);
    return result.fold((_) => null, (record) => record);
  }

  Future<MachineryRecord?> _loadMachineryRecord(String id) async {
    final result = await sl<GetMachineryRecordByIdUseCase>()(id);
    return result.fold((_) => null, (record) => record);
  }
}

/// Notifier that converts BLoC state changes to [Listenable] for GoRouter
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc authBloc) {
    authBloc.stream.listen((_) => notifyListeners());
  }
}
