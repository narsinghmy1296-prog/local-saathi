import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/splash_screen.dart';
import 'state/auth_provider.dart';
import 'state/locale_provider.dart';
import 'state/orders_provider.dart';
import 'state/products_provider.dart';
import 'state/seller_provider.dart';

void main() {
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SellerProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: MaterialApp(
        title: 'Local Saathi Seller',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Watches AuthProvider.status and swaps between Splash / Login / HomeShell.
/// Also clears seller-specific provider state on logout so a fresh login
/// (possibly a different seller, e.g. during testing) never sees stale data.
class _RootRouter extends StatefulWidget {
  const _RootRouter();
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  AuthStatus? _lastStatus;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_lastStatus == AuthStatus.loggedIn && auth.status == AuthStatus.loggedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SellerProvider>().clear();
      });
    }
    _lastStatus = auth.status;

    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.loggedOut:
        return const LoginScreen();
      case AuthStatus.loggedIn:
        return const HomeShell();
    }
  }
}
