import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../data/models/supplier.dart';
import '../../../providers/suppliers_provider.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersNotifierProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - responsive layout
          if (isMobile) ...[
            Text('Suppliers', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Manage your suppliers and inventory sources',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Add Supplier',
                icon: Iconsax.add,
                onPressed: () => _showSupplierForm(context, ref),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suppliers', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your suppliers and inventory sources',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'Add Supplier',
                  icon: Iconsax.add,
                  onPressed: () => _showSupplierForm(context, ref),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Total Outstanding Card
          ref.watch(totalOutstandingToSuppliersProvider).when(
            data: (total) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.money_recive, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Outstanding to Suppliers',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currencyFormat.format(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Search
          AppSearchField(
            hint: 'Search suppliers...',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 16),

          // Supplier List
          Expanded(
            child: suppliersAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading suppliers...'),
              error: (e, s) => ErrorState(
                title: 'Failed to load suppliers',
                onRetry: () => ref.read(suppliersNotifierProvider.notifier).refresh(),
              ),
              data: (suppliers) {
                var filtered = _searchQuery.isEmpty
                    ? suppliers
                    : suppliers.where((s) =>
                        s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        s.phone.contains(_searchQuery) ||
                        (s.contactPerson?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                      ).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(suppliersNotifierProvider.notifier).refresh();
                    },
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: EmptyState(
                            icon: Iconsax.box,
                            title: 'No suppliers found',
                            subtitle: 'Add suppliers to manage your inventory sources',
                            actionLabel: 'Add Supplier',
                            onAction: () => _showSupplierForm(context, ref),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(suppliersNotifierProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final supplier = filtered[index];
                      return AppCard(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        onTap: () => _showSupplierForm(context, ref, supplier: supplier),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                              child: Text(
                                supplier.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplier.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    supplier.phone,
                                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 12),
                                  ),
                                  if (supplier.contactPerson != null)
                                    Text(
                                      'Contact: ${supplier.contactPerson}',
                                      style: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.textSecondary, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            if (supplier.outstandingAmount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currencyFormat.format(supplier.outstandingAmount),
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(Iconsax.more, size: 20),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showSupplierForm(context, ref, supplier: supplier);
                                } else if (value == 'delete') {
                                  _confirmDelete(context, ref, supplier);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSupplierForm(BuildContext context, WidgetRef ref, {Supplier? supplier}) {
    showDialog(
      context: context,
      builder: (context) => _SupplierFormDialog(supplier: supplier),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(suppliersNotifierProvider.notifier).deleteSupplier(supplier.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SupplierFormDialog extends ConsumerStatefulWidget {
  final Supplier? supplier;

  const _SupplierFormDialog({this.supplier});

  @override
  ConsumerState<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends ConsumerState<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _addressController;
  late final TextEditingController _gstinController;
  late final TextEditingController _outstandingController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
    _contactPersonController = TextEditingController(text: widget.supplier?.contactPerson ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _gstinController = TextEditingController(text: widget.supplier?.gstin ?? '');
    _outstandingController = TextEditingController(
      text: widget.supplier?.outstandingAmount.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _outstandingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Supplier' : 'Add Supplier'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Company Name *',
                  controller: _nameController,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Contact Person',
                  controller: _contactPersonController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone *',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'GSTIN',
                  controller: _gstinController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Address',
                  controller: _addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Outstanding Amount',
                  controller: _outstandingController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supplier = Supplier(
        id: widget.supplier?.id,
        name: _nameController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty 
            ? null 
            : _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
        outstandingAmount: double.tryParse(_outstandingController.text) ?? 0,
        isActive: widget.supplier?.isActive ?? true,
      );

      if (widget.supplier != null) {
        await ref.read(suppliersNotifierProvider.notifier).updateSupplier(supplier);
      } else {
        await ref.read(suppliersNotifierProvider.notifier).addSupplier(supplier);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
