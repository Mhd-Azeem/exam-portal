import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/auth_provider.dart';
import 'auth/screens/login_screen.dart';
import 'student/student_shell.dart';
import 'admin/admin_shell.dart';
import 'shared/theme/app_theme.dart';

class ExamPortalApp extends ConsumerWidget {
  const ExamPortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Team Maestro',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: switch (authState.status) {
        AuthStatus.unknown => const _SplashScreen(),
        AuthStatus.unauthenticated => const LoginScreen(),
        AuthStatus.authenticated => authState.role == 'admin'
            ? const AdminShell()
            : const StudentShell(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, color: Colors.white, size: 56),
              SizedBox(height: 16),
              Text(
                'Team Maestro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white60)),
            ],
          ),
        ),
      );
}
