import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../state/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(_phoneCtrl.text.trim(), _nameCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.lang == 'hi' ? 'खाता बन गया, अब लॉगिन करें' : 'Account created, please log in')));
      Navigator.of(context).pop();
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('register'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.t('all_role_customer'), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: AppStrings.t('name'), prefixIcon: const Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                ),
                const SizedBox(height: 16),
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
                  obscureText: true,
                  decoration: InputDecoration(labelText: AppStrings.t('password'), prefixIcon: const Icon(Icons.lock_outline)),
                  // Backend requires min_length=6 (see UserRegister schema) —
                  // matching it here means the customer sees the problem
                  // before submitting instead of a server rejection.
                  validator: (v) => (v == null || v.length < 6)
                      ? (AppStrings.lang == 'hi' ? 'कम से कम 6 अक्षर' : 'At least 6 characters')
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(AppStrings.t('register')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
