import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/barcode_scanner_service.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/categories_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _mrpController;
  late TextEditingController _batchNumberController;
  late TextEditingController _brandController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;

  // State
  String? _selectedCategoryId;
  String _selectedUnit = 'Piece';
  double _selectedGstRate = 0;
  DateTime? _expiryDate;
  bool _trackInventory = true;
  bool _isActive = true;
  bool _isLoading = false;
  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploadingImage = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _skuController = TextEditingController(text: product?.sku ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _costPriceController = TextEditingController(text: product?.costPrice?.toString() ?? '');
    _mrpController = TextEditingController(text: product?.mrp?.toString() ?? '');
    _batchNumberController = TextEditingController(text: product?.batchNumber ?? '');
    _brandController = TextEditingController(text: product?.brand ?? '');
    _stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '0');
    _lowStockController = TextEditingController(text: product?.lowStockThreshold.toString() ?? '10');
    _selectedCategoryId = product?.categoryId;
    _selectedUnit = product?.unit ?? 'Piece';
    _selectedGstRate = product?.gstRate ?? 0;
    _expiryDate = product?.expiryDate;
    _trackInventory = product?.trackInventory ?? true;
    _isActive = product?.isActive ?? true;
    _imageUrl = product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _mrpController.dispose();
    _batchNumberController.dispose();
    _brandController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isWide ? 700 : 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isDark),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Image + Basic Info
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageSection(isDark),
                            const SizedBox(width: 24),
                            Expanded(child: _buildBasicInfoSection(categoriesAsync, isDark)),
                          ],
                        )
                      else ...[
                        _buildImageSection(isDark),
                        const SizedBox(height: 20),
                        _buildBasicInfoSection(categoriesAsync, isDark),
                      ],
                      const SizedBox(height: 20),
                      Divider(color: isDark ? Colors.white12 : AppColors.grey200),
                      const SizedBox(height: 20),

                      // Pricing Section
                      _buildSectionTitle('Pricing', isDark),
                      const SizedBox(height: 12),
                      _buildPricingSection(isDark),
                      const SizedBox(height: 20),
                      Divider(color: isDark ? Colors.white12 : AppColors.grey200),
                      const SizedBox(height: 20),

                      // Batch & Unit Section
                      _buildSectionTitle('Batch & Unit', isDark),
                      const SizedBox(height: 12),
                      _buildBatchUnitSection(isDark),
                      const SizedBox(height: 20),
                      Divider(color: isDark ? Colors.white12 : AppColors.grey200),
                      const SizedBox(height: 20),

                      // Inventory Section
                      _buildSectionTitle('Inventory', isDark),
                      const SizedBox(height: 12),
                      _buildInventorySection(isDark),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(isEditing ? Iconsax.edit : Iconsax.add_circle, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Product' : 'Add New Product',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: isDark ? Colors.white54 : AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    final hasImage = _imageUrl != null || _selectedImageBytes != null;
    
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.grey200,
            style: BorderStyle.solid,
          ),
        ),
        child: _isUploadingImage
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _selectedImageBytes != null
                            ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: 120, height: 120)
                            : Image.network(_imageUrl!, fit: BoxFit.cover, width: 120, height: 120),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() { _selectedImageBytes = null; _imageUrl = null; }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.image, size: 32, color: isDark ? Colors.white30 : AppColors.grey400),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Image',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : AppColors.grey500),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildBasicInfoSection(AsyncValue categoriesAsync, bool isDark) {
    return Column(
      children: [
        // Product Name
        AppTextField(
          label: 'Product Name *',
          hint: 'e.g. GrowFast 2mm',
          controller: _nameController,
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        // Category & Brand Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  categoriesAsync.when(
                    loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (e, s) => Text('Error: $e'),
                    data: (categories) {
                      final cats = categories as List<Category>;
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        hint: const Text('Select'),
                        items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Brand', hint: 'e.g. AquaNutri', controller: _brandController)),
          ],
        ),
        const SizedBox(height: 12),
        // SKU & Barcode Row
        Row(
          children: [
            Expanded(child: AppTextField(label: 'SKU', hint: 'e.g. PRD-001', controller: _skuController)),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Barcode',
                hint: 'Scan or enter barcode',
                controller: _barcodeController,
                suffixIcon: IconButton(
                  icon: Icon(Iconsax.scan_barcode, size: 20, color: AppColors.primary),
                  onPressed: () async {
                    final result = await BarcodeScannerService().scanBarcode(context);
                    if (result != null && mounted) {
                      setState(() => _barcodeController.text = result.code);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSection(bool isDark) {
    return Column(
      children: [
        // Row 1: Selling Price, Cost Price
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Selling Price *',
                hint: '0',
                prefixText: '₹ ',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Purchase Price',
                hint: '0',
                prefixText: '₹ ',
                controller: _costPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: MRP, GST Rate
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'MRP',
                hint: '0',
                prefixText: '₹ ',
                controller: _mrpController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GST Rate (%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<double>(
                    initialValue: _selectedGstRate,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: Product.gstRateOptions.map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%'))).toList(),
                    onChanged: (v) => setState(() => _selectedGstRate = v ?? 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchUnitSection(bool isDark) {
    return Column(
      children: [
        // Row 1: Batch Number, Expiry Date
        Row(
          children: [
            Expanded(child: AppTextField(label: 'Batch Number', hint: 'e.g. BT-2024-001', controller: _batchNumberController)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expiry Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) setState(() => _expiryDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? Colors.white24 : AppColors.grey300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _expiryDate != null ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}' : 'Select date',
                              style: TextStyle(color: _expiryDate != null ? null : (isDark ? Colors.white38 : AppColors.grey500)),
                            ),
                          ),
                          Icon(Iconsax.calendar, size: 18, color: isDark ? Colors.white38 : AppColors.grey500),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Unit, Low Stock Alert
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: Product.unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v ?? 'Piece'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Low Stock Alert', hint: '10', controller: _lowStockController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ],
        ),
      ],
    );
  }

  Widget _buildInventorySection(bool isDark) {
    return Column(
      children: [
        // Track Inventory Switch
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Iconsax.box, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Track Inventory', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text('Enable stock tracking', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(value: _trackInventory, onChanged: (v) => setState(() => _trackInventory = v), activeThumbColor: AppColors.primary),
            ],
          ),
        ),
        if (_trackInventory) ...[
          const SizedBox(height: 12),
          AppTextField(label: 'Current Stock', hint: '0', controller: _stockController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ],
        const SizedBox(height: 12),
        // Active Switch
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Iconsax.tick_circle, color: AppColors.success, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text('Available for sale', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeThumbColor: AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              label: isEditing ? 'Save Product' : 'Save Product',
              icon: Iconsax.tick_circle,
              isLoading: _isLoading,
              onPressed: _saveProduct,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _imageUrl;

      // Upload image if selected
      if (_selectedImageBytes != null) {
        setState(() => _isUploadingImage = true);
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${_selectedImageName ?? 'image.jpg'}';
        final uploadedUrl = await ProductRepository().uploadProductImage(_selectedImageBytes!.toList(), fileName);
        if (uploadedUrl != null) {
          if (_imageUrl != null) await ProductRepository().deleteProductImage(_imageUrl!);
          finalImageUrl = uploadedUrl;
        }
        setState(() => _isUploadingImage = false);
      } else if (_imageUrl == null && widget.product?.imageUrl != null) {
        await ProductRepository().deleteProductImage(widget.product!.imageUrl!);
        finalImageUrl = null;
      }

      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: _costPriceController.text.isEmpty ? null : double.parse(_costPriceController.text),
        mrp: _mrpController.text.isEmpty ? null : double.parse(_mrpController.text),
        gstRate: _selectedGstRate,
        batchNumber: _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
        expiryDate: _expiryDate,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        unit: _selectedUnit,
        stockQuantity: _trackInventory ? int.parse(_stockController.text) : 0,
        lowStockThreshold: int.parse(_lowStockController.text),
        categoryId: _selectedCategoryId!,
        imageUrl: finalImageUrl,
        trackInventory: _trackInventory,
        isActive: _isActive,
        createdAt: widget.product?.createdAt,
      );

      final notifier = ref.read(productsNotifierProvider.notifier);
      if (isEditing) {
        await notifier.updateProduct(product);
      } else {
        await notifier.addProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Product updated!' : 'Product added!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() { _isLoading = false; _isUploadingImage = false; });
    }
  }
}
