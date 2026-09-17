import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/locale_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_phoneCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      // AuthProvider.status flip triggers SplashScreen to swap to HomeShell.
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => locale.toggle(),
                  icon: const Icon(Icons.language),
                  label: Text(locale.lang == 'hi' ? 'English' : 'हिंदी'),
                ),
              ),
              const Icon(Icons.storefront, color: AppTheme.primary, size: 64),
              const SizedBox(height: 8),
              Center(
                child: Text(AppStrings.t('appName'), style: Theme.of(context).textTheme.headlineMedium),
              ),
              const SizedBox(height: 32),
              if (auth.sessionExpiredFlag)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Text(AppStrings.t('session_expired'), textAlign: TextAlign.center),
                ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: AppStrings.t('phone'), prefixIcon: const Icon(Icons.phone)),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(t)) {
                          return AppStrings.lang == 'hi' ? '10 अंकों का सही मोबाइल नंबर डालें' : 'Enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: AppStrings.t('password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? '' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: auth.loading ? null : _submit,
                      child: auth.loading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(AppStrings.t('login')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text(AppStrings.t('register')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
