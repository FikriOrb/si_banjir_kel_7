import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_page.dart';

class FloodWarningApp extends StatelessWidget {
  const FloodWarningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SiBanjir',
      theme: AppTheme.light(),
      home: const SplashPage(),
    );
  }
}
