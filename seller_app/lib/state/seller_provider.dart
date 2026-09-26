import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/seller_profile.dart';
import '../services/seller_profile_service.dart';

/// Holds the logged-in seller's own shop profile (id, approval status,
/// shop name, etc.) — loaded right after login and re-checked from the
/// Pending-Approval screen, since `is_approved` can change any time an
/// admin acts on it.
class SellerProvider extends ChangeNotifier {
  final _service = SellerProfileService();

  SellerProfile? profile;
  bool loading = false;
  String? error;

  bool get isApproved => profile?.isApproved ?? false;

  Future<bool> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _service.getMyProfile();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } on NetworkException catch (e) {
      error = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? shopName, String? ownerName, String? area, String? upiId}) async {
    error = null;
    try {
      profile = await _service.updateMyProfile(shopName: shopName, ownerName: ownerName, area: area, upiId: upiId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clear() {
    profile = null;
    notifyListeners();
  }
}
