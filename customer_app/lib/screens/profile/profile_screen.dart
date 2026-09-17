import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/locale_provider.dart';
import '../address/address_list_screen.dart';
import '../orders/orders_screen.dart';

/// Spec module #19/#25 — Profile: shows the logged-in customer's own info
/// (name/phone/role — nothing invented, straight from AuthProvider, which
/// itself came from the real /auth/me response) plus links to Addresses,
/// My Orders, Help, and Logout. No profile-editing API exists on the
/// backend, so this screen deliberately does not offer one.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('logout')),
        content: Text(AppStrings.t('confirm_logout')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(AppStrings.t('no'))),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(AppStrings.t('yes'))),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
      // SplashScreen (Consumer<AuthProvider>) swaps to LoginScreen automatically.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.name?.isNotEmpty == true ? auth.name! : '—',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        if (auth.phone?.isNotEmpty == true) Text(auth.phone!, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                  title: Text(AppStrings.t('my_addresses')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressListScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
                  title: Text(AppStrings.t('my_orders')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language, color: AppTheme.primary),
                  title: Text(locale.lang == 'hi' ? 'भाषा: हिंदी' : 'Language: English'),
                  trailing: TextButton(
                    onPressed: () => locale.toggle(),
                    child: Text(locale.lang == 'hi' ? 'English' : 'हिंदी'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppTheme.primary),
                  title: Text(AppStrings.t('help')),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(AppStrings.t('help')),
                      content: Text(AppStrings.t('help_text')),
                      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppStrings.t('yes')))],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: AppTheme.danger),
            label: Text(AppStrings.t('logout'), style: const TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
