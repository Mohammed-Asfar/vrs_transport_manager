import 'package:flutter/material.dart';
import 'package:vrs_transport_manager/features/home/presentation/pages/home_page.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomePage(), theme: AppTheme.lightTheme);
  }
}
