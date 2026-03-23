import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/core/router/app_router.dart';
import 'package:vrs_transport_manager/core/theme/app_theme.dart';
import 'package:vrs_transport_manager/di/injection_container.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:vrs_transport_manager/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize dependencies
  await initDependencies();

  runApp(const VrsTransportApp());
}

class VrsTransportApp extends StatelessWidget {
  const VrsTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final appRouter = AppRouter(authBloc);

          return MaterialApp.router(
            title: 'VRS Transport Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
