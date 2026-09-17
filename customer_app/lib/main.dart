import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalSaathiApp());
}

class LocalSaathiApp extends StatelessWidget {
  const LocalSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Local Saathi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}
