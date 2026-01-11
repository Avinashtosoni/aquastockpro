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
import '../../../data/models/employee.dart';
import '../../../providers/employees_provider.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesNotifierProvider);
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
            Text('Employees', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Manage your staff and permissions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Add Employee',
                icon: Iconsax.add,
                onPressed: () => _showEmployeeForm(context, ref),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Employees', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your staff and permissions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'Add Employee',
                  icon: Iconsax.add,
                  onPressed: () => _showEmployeeForm(context, ref),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Search
          AppSearchField(
            hint: 'Search employees...',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 24),

          // Employee List
          Expanded(
            child: employeesAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading employees...'),
              error: (e, s) => ErrorState(
                title: 'Failed to load employees',
                onRetry: () => ref.read(employeesNotifierProvider.notifier).refresh(),
              ),
              data: (employees) {
                var filtered = _searchQuery.isEmpty
                    ? employees
                    : employees.where((e) =>
                        e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        e.phone.contains(_searchQuery) ||
                        (e.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                      ).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(employeesNotifierProvider.notifier).refresh();
                    },
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: EmptyState(
                            icon: Iconsax.user,
                            title: 'No employees found',
                            subtitle: 'Add employees to manage your staff',
                            actionLabel: 'Add Employee',
                            onAction: () => _showEmployeeForm(context, ref),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(employeesNotifierProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final employee = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          onTap: () => _showEmployeeForm(context, ref, employee: employee),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getRoleColor(employee.role).withValues(alpha: 0.1),
                                child: Icon(
                                  _getRoleIcon(employee.role),
                                  color: _getRoleColor(employee.role),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            employee.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkTextPrimary : null,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _RoleChip(role: employee.role),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      employee.phone,
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (employee.email != null)
                                      Text(
                                        employee.email!,
                                        style: TextStyle(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (employee.salary != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    currencyFormat.format(employee.salary),
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Iconsax.more, size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEmployeeForm(context, ref, employee: employee);
                                  } else if (value == 'delete') {
                                    _confirmDelete(context, ref, employee);
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

  Color _getRoleColor(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.admin:
        return AppColors.error;
      case EmployeeRole.manager:
        return AppColors.warning;
      case EmployeeRole.cashier:
        return AppColors.info;
    }
  }

  IconData _getRoleIcon(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.admin:
        return Iconsax.shield_tick;
      case EmployeeRole.manager:
        return Iconsax.user_tick;
      case EmployeeRole.cashier:
        return Iconsax.user;
    }
  }

  void _showEmployeeForm(BuildContext context, WidgetRef ref, {Employee? employee}) {
    showDialog(
      context: context,
      builder: (context) => _EmployeeFormDialog(employee: employee),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(employeesNotifierProvider.notifier).deleteEmployee(employee.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final EmployeeRole role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case EmployeeRole.admin:
        color = AppColors.error;
        break;
      case EmployeeRole.manager:
        color = AppColors.warning;
        break;
      case EmployeeRole.cashier:
        color = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmployeeFormDialog extends ConsumerStatefulWidget {
  final Employee? employee;

  const _EmployeeFormDialog({this.employee});

  @override
  ConsumerState<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _pinController;
  late final TextEditingController _salaryController;
  late final TextEditingController _addressController;
  late EmployeeRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _emailController = TextEditingController(text: widget.employee?.email ?? '');
    _pinController = TextEditingController(text: widget.employee?.pin ?? '');
    _salaryController = TextEditingController(
      text: widget.employee?.salary?.toString() ?? '',
    );
    _addressController = TextEditingController(text: widget.employee?.address ?? '');
    _selectedRole = widget.employee?.role ?? EmployeeRole.cashier;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Employee' : 'Add Employee'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Name *',
                  controller: _nameController,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
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
                  label: 'PIN (4-6 digits) *',
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 4) return 'PIN must be at least 4 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EmployeeRole>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: EmployeeRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.name[0].toUpperCase() + role.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRole = value);
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Salary (per month)',
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Address',
                  controller: _addressController,
                  maxLines: 2,
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
      final employee = Employee(
        id: widget.employee?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        pin: _pinController.text.trim(),
        role: _selectedRole,
        salary: _salaryController.text.isEmpty ? null : double.tryParse(_salaryController.text),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        joinDate: widget.employee?.joinDate ?? DateTime.now(),
        isActive: widget.employee?.isActive ?? true,
      );

      if (widget.employee != null) {
        await ref.read(employeesNotifierProvider.notifier).updateEmployee(employee);
      } else {
        await ref.read(employeesNotifierProvider.notifier).addEmployee(employee);
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
