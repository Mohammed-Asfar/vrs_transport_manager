import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:vrs_transport_manager/features/auth/presentation/pages/login_page.dart';
import 'package:vrs_transport_manager/features/transport/domain/entities/transport_record.dart';
import 'package:vrs_transport_manager/features/transport/domain/usecases/transport_usecases.dart';
import 'package:vrs_transport_manager/features/transport/presentation/bloc/transport_bloc.dart';
import 'package:vrs_transport_manager/features/transport/presentation/pages/dashboard_page.dart';
import 'package:vrs_transport_manager/features/transport/presentation/pages/record_detail_page.dart';
import 'package:vrs_transport_manager/features/transport/presentation/pages/record_form_page.dart';

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
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<TransportBloc>(),
          child: const DashboardPage(),
        ),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<TransportBloc>(),
          child: const RecordFormPage(),
        ),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
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
                      child: Text('Failed to load record: ${snapshot.error}'),
                    ),
                  );
                }
                return RecordFormPage(existingRecord: snapshot.data);
              },
            ),
          );
        },
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => sl<TransportBloc>(),
            child: RecordDetailPage(recordId: id),
          );
        },
      ),
    ],
  );

  Future<TransportRecord?> _loadRecord(String id) async {
    final result = await sl<GetRecordByIdUseCase>()(id);
    return result.fold((_) => null, (record) => record);
  }
}

/// Notifier that converts BLoC state changes to [Listenable] for GoRouter
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc authBloc) {
    authBloc.stream.listen((_) => notifyListeners());
  }
}
