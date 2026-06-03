import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_shell_page.dart';

class FloodWarningApp extends StatelessWidget {
  const FloodWarningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Peringatan Banjir Medan',
      theme: AppTheme.light(),
      home: Supabase.instance.client.auth.currentSession == null 
          ? const LoginPage() 
          : const HomeShellPage(),
    );
  }
}
