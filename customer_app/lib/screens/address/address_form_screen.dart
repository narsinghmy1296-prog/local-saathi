import 'package:flutter/material.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AddressService();

  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _mobileCtrl = TextEditingController(text: widget.existing?.mobile ?? '');
  late final _villageCtrl = TextEditingController(text: widget.existing?.villageTown ?? '');
  late final _houseCtrl = TextEditingController(text: widget.existing?.house ?? '');
  late final _landmarkCtrl = TextEditingController(text: widget.existing?.landmark ?? '');
  late final _pincodeCtrl = TextEditingController(text: widget.existing?.pincode ?? '');
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isDefault = widget.existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _villageCtrl.dispose();
    _houseCtrl.dispose();
    _landmarkCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final address = Address(
      id: widget.existing?.id ?? 0,
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      villageTown: _villageCtrl.text.trim(),
      house: _houseCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      isDefault: _isDefault,
    );
    try {
      if (widget.existing != null) {
        await _service.updateAddress(widget.existing!.id, address);
      } else {
        await _service.addAddress(address);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('add_address'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: AppStrings.t('name')),
                validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: AppStrings.t('phone')),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(t)) {
                    return AppStrings.lang == 'hi' ? '10 अंकों का सही मोबाइल नंबर डालें' : 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _villageCtrl,
                decoration: InputDecoration(labelText: AppStrings.t('village_town')),
                validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _houseCtrl, decoration: InputDecoration(labelText: AppStrings.t('house'))),
              const SizedBox(height: 14),
              TextFormField(controller: _landmarkCtrl, decoration: InputDecoration(labelText: AppStrings.t('landmark'))),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pincodeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppStrings.t('pincode')),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (!RegExp(r'^\d{6}$').hasMatch(t)) {
                    return AppStrings.lang == 'hi' ? '6 अंकों का सही PIN कोड डालें' : 'Enter a valid 6-digit PIN code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: Text(AppStrings.lang == 'hi' ? 'डिफ़ॉल्ट पता बनाएं' : 'Set as default address'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(AppStrings.t('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
