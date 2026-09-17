import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../state/auth_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_shell.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.unknown) {
          return Scaffold(
            backgroundColor: AppTheme.primary,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront, color: Colors.white, size: 72),
                  const SizedBox(height: 16),
                  Text(AppStrings.t('appName'),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          );
        }
        if (auth.status == AuthStatus.loggedIn) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}
