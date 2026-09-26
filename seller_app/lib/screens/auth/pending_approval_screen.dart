import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/locale_provider.dart';
import '../../state/seller_provider.dart';

/// Shown whenever the logged-in seller's profile has is_approved == false.
/// Requirement: "Clear approval/pending/rejected account status" — a
/// rejected seller (backend: is_approved=false AND is_active=false) simply
/// cannot log in at all (401/403 from /auth/login), so this screen only
/// needs to cover the "still pending" case; a truly rejected seller sees a
/// login error instead, handled in login_screen indirectly via auth.error.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);
    final sellerProv = context.watch<SellerProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 64, color: AppTheme.accent),
                const SizedBox(height: 16),
                Text(s.pendingApprovalTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(s.pendingApprovalBody, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                if (sellerProv.profile != null) ...[
                  const SizedBox(height: 16),
                  Text(sellerProv.profile!.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: sellerProv.loading ? null : () => context.read<SellerProvider>().load(),
                  icon: sellerProv.loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: Text(s.refresh),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: Text(s.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
