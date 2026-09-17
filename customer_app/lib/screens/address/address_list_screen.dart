import 'package:flutter/material.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';
import '../common/state_widgets.dart';
import 'address_form_screen.dart';

/// If [selectMode] is true (opened from Checkout), tapping an address pops
/// it back to the caller instead of just viewing/editing.
class AddressListScreen extends StatefulWidget {
  final bool selectMode;
  const AddressListScreen({super.key, this.selectMode = false});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final _service = AddressService();
  List<Address> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _addresses = await _service.getAddresses();
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addNew() async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddressFormScreen()));
    if (result == true) _load();
  }

  Future<void> _edit(Address a) async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AddressFormScreen(existing: a)));
    if (result == true) _load();
  }

  Future<void> _delete(Address a) async {
    try {
      await _service.deleteAddress(a.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('addresses'))),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _addresses.isEmpty
                  ? EmptyView(message: AppStrings.lang == 'hi' ? 'अभी कोई पता नहीं जोड़ा गया' : 'No addresses added yet', icon: Icons.location_off_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = _addresses[i];
                        return Card(
                          child: ListTile(
                            onTap: widget.selectMode ? () => Navigator.of(context).pop(a) : () => _edit(a),
                            leading: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                            title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${a.oneLine}\n${a.mobile}'),
                            isThreeLine: true,
                            trailing: widget.selectMode
                                ? null
                                : IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger), onPressed: () => _delete(a)),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNew,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.t('add_address')),
      ),
    );
  }
}
