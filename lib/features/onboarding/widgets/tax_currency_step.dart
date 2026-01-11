import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../screens/setup_wizard_screen.dart';

class TaxCurrencyStep extends StatefulWidget {
  final SetupWizardData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const TaxCurrencyStep({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<TaxCurrencyStep> createState() => _TaxCurrencyStepState();
}

class _TaxCurrencyStepState extends State<TaxCurrencyStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _taxRateController;
  late final TextEditingController _taxLabelController;
  late final TextEditingController _gstinController;

  String _selectedCurrency = 'INR';

  final Map<String, Map<String, String>> _currencies = {
    'INR': {'symbol': '₹', 'name': 'Indian Rupee'},
    'USD': {'symbol': '\$', 'name': 'US Dollar'},
    'EUR': {'symbol': '€', 'name': 'Euro'},
    'GBP': {'symbol': '£', 'name': 'British Pound'},
    'AED': {'symbol': 'د.إ', 'name': 'UAE Dirham'},
  };

  @override
  void initState() {
    super.initState();
    _taxRateController = TextEditingController(text: widget.data.taxRate.toString());
    _taxLabelController = TextEditingController(text: widget.data.taxLabel);
    _gstinController = TextEditingController(text: widget.data.gstin);
    _selectedCurrency = widget.data.currencyCode;
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    _taxLabelController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (_formKey.currentState!.validate()) {
      widget.data.currencyCode = _selectedCurrency;
      widget.data.currencySymbol = _currencies[_selectedCurrency]!['symbol']!;
      widget.data.taxRate = double.tryParse(_taxRateController.text) ?? 5.0;
      widget.data.taxLabel = _taxLabelController.text.trim();
      widget.data.gstin = _gstinController.text.trim().isEmpty
          ? null
          : _gstinController.text.trim();
      widget.onNext();
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
            // Currency selection
            Text(
              'Currency',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _currencies.entries.map((entry) {
                final isSelected = _selectedCurrency == entry.key;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = entry.key;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkCardBackground
                              : AppColors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkCardBorder
                                : AppColors.cardBorder),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          entry.value['symbol']!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.8)
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Tax settings section
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
                      Icon(
                        Iconsax.receipt_text,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tax Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tax rate and label in row
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _taxRateController,
                          label: 'Tax Rate (%)',
                          hint: '5.0',
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate < 0 || rate > 100) {
                              return 'Invalid rate';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _taxLabelController,
                          label: 'Tax Label',
                          hint: 'GST',
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // GSTIN
                  AppTextField(
                    controller: _gstinController,
                    label: 'GSTIN (Optional)',
                    hint: 'Enter your GST number',
                    prefixIcon: const Icon(Iconsax.document),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
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
                    onPressed: widget.onBack,
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.large,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: 'Continue',
                    onPressed: _saveAndNext,
                    size: AppButtonSize.large,
                    icon: Iconsax.arrow_right_1,
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
