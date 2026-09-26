import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/locale_provider.dart';
import '../../state/seller_provider.dart';
import '../../widgets/common_states.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _shopNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _upiCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = context.read<SellerProvider>().profile;
    _shopNameCtrl = TextEditingController(text: p?.shopName);
    _ownerNameCtrl = TextEditingController(text: p?.ownerName);
    _areaCtrl = TextEditingController(text: p?.area);
    _upiCtrl = TextEditingController(text: p?.upiId);
  }

  @override
  void dispose() {
    for (final c in [_shopNameCtrl, _ownerNameCtrl, _areaCtrl, _upiCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);
    final sellerProv = context.watch<SellerProvider>();
    final auth = context.watch<AuthProvider>();
    final p = sellerProv.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profile),
        actions: [
          TextButton(onPressed: () => context.read<LocaleProvider>().toggle(), child: Text(locale.lang == 'hi' ? 'EN' : 'हि', style: const TextStyle(color: Colors.white))),
        ],
      ),
      body: p == null
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(radius: 40, backgroundColor: AppTheme.primary, child: Icon(Icons.storefront, color: Colors.white, size: 36)),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text(p.isApproved ? s.approved : s.notApproved),
                          backgroundColor: (p.isApproved ? AppTheme.primary : AppTheme.accent).withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: p.isApproved ? AppTheme.primary : AppTheme.accent, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_editing) ...[
                    _InfoRow(label: s.shopName, value: p.shopName),
                    _InfoRow(label: s.ownerName, value: p.ownerName),
                    _InfoRow(label: s.area, value: p.area),
                    _InfoRow(label: s.upiId, value: p.upiId ?? '-'),
                    _InfoRow(label: s.phone, value: p.phone),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _editing = true),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(s.editProfile),
                    ),
                  ] else ...[
                    TextFormField(controller: _shopNameCtrl, decoration: InputDecoration(labelText: s.shopName)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _ownerNameCtrl, decoration: InputDecoration(labelText: s.ownerName)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _areaCtrl, decoration: InputDecoration(labelText: s.area)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _upiCtrl, decoration: InputDecoration(labelText: s.upiId)),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => setState(() => _editing = false),
                            child: Text(s.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    setState(() {
                                      _saving = true;
                                      _error = null;
                                    });
                                    final ok = await context.read<SellerProvider>().updateProfile(
                                          shopName: _shopNameCtrl.text.trim(),
                                          ownerName: _ownerNameCtrl.text.trim(),
                                          area: _areaCtrl.text.trim(),
                                          upiId: _upiCtrl.text.trim(),
                                        );
                                    if (!mounted) return;
                                    setState(() {
                                      _saving = false;
                                      if (ok) {
                                        _editing = false;
                                      } else {
                                        _error = context.read<SellerProvider>().error;
                                      }
                                    });
                                  },
                            child: _saving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(s.save),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)),
                    onPressed: auth.loading
                        ? null
                        : () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: s.logout,
                              message: s.logout,
                              confirmLabel: s.confirm,
                              cancelLabel: s.cancel,
                              danger: true,
                            );
                            if (ok) await context.read<AuthProvider>().logout();
                          },
                    icon: const Icon(Icons.logout),
                    label: Text(s.logout),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.black54))),
            Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
