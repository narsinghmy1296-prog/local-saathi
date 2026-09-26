import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_endpoints.dart';
import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../services/product_service.dart';
import '../../services/upload_service.dart';
import '../../state/locale_provider.dart';

/// Add/Edit product. Pass [existing] to edit; null means "add new".
///
/// Known limitation (documented, not silently papered over): the backend's
/// ProductOut schema does not return `keywords` on GET, so when editing an
/// existing product the Keywords field starts blank — whatever the seller
/// types there on Save *adds* to search-ability going forward, it does not
/// show what was set before. A `GET /products/{id}/keywords` endpoint would
/// fix this properly; flagged in SELLER_APP_README.md rather than guessed at.
class ProductFormScreen extends StatefulWidget {
  final Product? existing;
  const ProductFormScreen({super.key, this.existing});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _catalogService = CatalogService();
  final _productService = ProductService();
  final _uploadService = UploadService();

  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _descCtrl = TextEditingController(text: widget.existing?.description);
  late final _priceCtrl = TextEditingController(text: widget.existing?.price.toString());
  late final _unitCtrl = TextEditingController(text: widget.existing?.unit);
  late final _qtyCtrl = TextEditingController(text: widget.existing?.availableQty.toString());
  late final _minQtyCtrl = TextEditingController(text: (widget.existing?.minOrderQty ?? 1).toString());
  final _keywordsCtrl = TextEditingController();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isOtherCategory = false;
  bool _loadingCategories = true;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _error;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _uploadedImageUrl; // set once upload succeeds

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _isOtherCategory = widget.existing?.isOther ?? false;
    _selectedCategoryId = widget.existing?.categoryId;
    _uploadedImageUrl = widget.existing?.imageUrl;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _catalogService.getCategories();
      if (mounted) setState(() {
        _categories = cats;
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _priceCtrl, _unitCtrl, _qtyCtrl, _minQtyCtrl, _keywordsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = file.name;
      _uploadedImageUrl = null;
    });
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<String?> _ensureImageUploaded(AppStrings s) async {
    if (_pickedImageBytes == null) return _uploadedImageUrl; // nothing new picked
    setState(() => _uploadingImage = true);
    try {
      final url = await _uploadService.uploadProductImage(
        bytes: _pickedImageBytes!,
        filename: _pickedImageName ?? 'photo.jpg',
        contentType: _contentTypeFor(_pickedImageName ?? 'photo.jpg'),
      );
      _uploadedImageUrl = url;
      return url;
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      return null;
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
      return null;
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final imageUrl = await _ensureImageUploaded(s);
    if (_error != null) {
      setState(() => _saving = false);
      return;
    }

    final keywords = _keywordsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    try {
      if (_isEdit) {
        await _productService.updateProduct(
          widget.existing!.id,
          categoryId: _isOtherCategory ? null : _selectedCategoryId,
          clearCategory: _isOtherCategory,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text.trim()),
          unit: _unitCtrl.text.trim(),
          minOrderQty: double.tryParse(_minQtyCtrl.text.trim()),
          imageUrl: imageUrl,
        );
        // available_qty/stock_status go through the dedicated stock endpoint.
        final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
        await _productService.updateStock(widget.existing!.id, availableQty: qty, stockStatus: qty > 0 ? 'in_stock' : 'out_of_stock');
      } else {
        await _productService.createProduct(
          categoryId: _isOtherCategory ? null : _selectedCategoryId,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
          unit: _unitCtrl.text.trim(),
          availableQty: double.tryParse(_qtyCtrl.text.trim()) ?? 0,
          minOrderQty: double.tryParse(_minQtyCtrl.text.trim()) ?? 1,
          imageUrl: imageUrl,
          keywords: keywords,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);

    final existingImageUrl = _uploadedImageUrl != null && _uploadedImageUrl!.startsWith('/')
        ? '${ApiConfig.baseUrl}$_uploadedImageUrl'
        : _uploadedImageUrl;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? s.editProduct : s.addProduct)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _uploadingImage ? null : _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.black12,
                      backgroundImage: _pickedImageBytes != null
                          ? MemoryImage(_pickedImageBytes!)
                          : (existingImageUrl != null ? NetworkImage(existingImageUrl) as ImageProvider : null),
                      child: (_pickedImageBytes == null && existingImageUrl == null)
                          ? const Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.black45)
                          : null,
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _uploadingImage ? null : _pickImage,
                    child: Text(_pickedImageBytes != null || existingImageUrl != null ? s.changePhoto : s.addPhoto),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: s.productName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.requiredField : null,
                ),
                const SizedBox(height: 12),
                if (_loadingCategories)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
                else ...[
                  DropdownButtonFormField<int?>(
                    value: _isOtherCategory ? null : _selectedCategoryId,
                    decoration: InputDecoration(labelText: s.category),
                    items: [
                      for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.displayName(locale.lang))),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedCategoryId = v;
                      _isOtherCategory = false;
                    }),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isOtherCategory,
                    title: Text(s.otherCategory),
                    onChanged: (v) => setState(() {
                      _isOtherCategory = v ?? false;
                      if (_isOtherCategory) _selectedCategoryId = null;
                    }),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: s.description),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: s.price),
                        validator: (v) => (double.tryParse(v ?? '') == null) ? s.requiredField : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: InputDecoration(labelText: s.unit),
                        validator: (v) => (v == null || v.trim().isEmpty) ? s.requiredField : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: s.availableQty),
                        validator: (v) => (double.tryParse(v ?? '') == null) ? s.requiredField : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minQtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: s.minOrderQty),
                      ),
                    ),
                  ],
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keywordsCtrl,
                    decoration: InputDecoration(labelText: s.keywords, hintText: 'गुड़, jaggery, desi gud'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || _uploadingImage) ? null : () => _save(s),
                  child: (_saving || _uploadingImage)
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(s.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
