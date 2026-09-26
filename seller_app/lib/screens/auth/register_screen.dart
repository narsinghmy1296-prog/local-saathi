import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/locale_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_phoneCtrl, _nameCtrl, _passwordCtrl, _shopNameCtrl, _ownerNameCtrl, _areaCtrl, _upiCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);

    return Scaffold(
      appBar: AppBar(title: Text(s.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: s.ownerName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: s.phone),
                  validator: (v) => (v == null || v.trim().length < 10) ? s.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: s.password),
                  validator: (v) => (v == null || v.length < 6) ? s.requiredField : null,
                ),
                const Divider(height: 32),
                TextFormField(
                  controller: _shopNameCtrl,
                  decoration: InputDecoration(labelText: s.shopName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerNameCtrl,
                  decoration: InputDecoration(labelText: s.ownerName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaCtrl,
                  decoration: InputDecoration(labelText: s.area),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _upiCtrl,
                  decoration: InputDecoration(labelText: s.upiId),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() {
                            _submitting = true;
                            _error = null;
                          });
                          final auth = context.read<AuthProvider>();
                          final ok = await auth.register(
                            phone: _phoneCtrl.text.trim(),
                            name: _nameCtrl.text.trim(),
                            password: _passwordCtrl.text,
                            shopName: _shopNameCtrl.text.trim(),
                            ownerName: _ownerNameCtrl.text.trim(),
                            area: _areaCtrl.text.trim(),
                            upiId: _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          setState(() => _submitting = false);
                          if (ok) {
                            // Registered but not approved yet — log them in
                            // right away so they land on the Pending
                            // Approval screen instead of typing everything
                            // twice.
                            await auth.login(_phoneCtrl.text.trim(), _passwordCtrl.text);
                            if (mounted) Navigator.of(context).pop();
                          } else {
                            setState(() => _error = auth.error ?? s.somethingWentWrong);
                          }
                        },
                  child: _submitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(s.register),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
