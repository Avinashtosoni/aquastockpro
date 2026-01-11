import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../screens/setup_wizard_screen.dart';

class AdminSetupStep extends StatefulWidget {
  final SetupWizardData data;
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final bool isLoading;

  const AdminSetupStep({
    super.key,
    required this.data,
    required this.onComplete,
    required this.onBack,
    this.isLoading = false,
  });

  @override
  State<AdminSetupStep> createState() => _AdminSetupStepState();
}

class _AdminSetupStepState extends State<AdminSetupStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _pinController;
  late final TextEditingController _confirmPinController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data.adminName);
    _emailController = TextEditingController(text: widget.data.adminEmail);
    _phoneController = TextEditingController(text: widget.data.adminPhone);
    _passwordController = TextEditingController(text: widget.data.adminPassword);
    _confirmPasswordController = TextEditingController(text: widget.data.adminPassword);
    _pinController = TextEditingController(text: widget.data.adminPin);
    _confirmPinController = TextEditingController(text: widget.data.adminPin);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _saveAndComplete() {
    if (_formKey.currentState!.validate()) {
      widget.data.adminName = _nameController.text.trim();
      widget.data.adminEmail = _emailController.text.trim();
      widget.data.adminPhone = _phoneController.text.trim();
      widget.data.adminPassword = _passwordController.text;
      widget.data.adminPin = _pinController.text;
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.security_user, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create your admin account. Remember your password and PIN for login.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            AppTextField(
              controller: _nameController,
              label: 'Full Name *',
              hint: 'Enter your name',
              prefixIcon: const Icon(Iconsax.user),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            AppTextField(
              controller: _emailController,
              label: 'Email Address *',
              hint: 'Enter your email',
              prefixIcon: const Icon(Iconsax.sms),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number *',
              hint: 'Enter your phone number',
              prefixIcon: const Icon(Iconsax.call),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone is required';
                }
                if (value.length < 10) {
                  return 'Enter valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Password section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.lock, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Set Password',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _passwordController,
                    label: 'Password *',
                    hint: 'Create a password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Iconsax.eye : Iconsax.eye_slash),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password *',
                    hint: 'Re-enter password',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Iconsax.eye : Iconsax.eye_slash),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PIN section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.key, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Set Quick PIN',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick PIN is used for fast unlock when reopening the app',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _pinController,
                          label: '4-Digit PIN *',
                          hint: '••••',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'PIN required';
                            }
                            if (value.length != 4) {
                              return 'Enter 4 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _confirmPinController,
                          label: 'Confirm PIN *',
                          hint: '••••',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value != _pinController.text) {
                              return 'PINs don\'t match';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Back',
                    onPressed: widget.isLoading ? null : widget.onBack,
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.large,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: 'Complete Setup',
                    onPressed: widget.isLoading ? null : _saveAndComplete,
                    isLoading: widget.isLoading,
                    size: AppButtonSize.large,
                    icon: Iconsax.tick_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
