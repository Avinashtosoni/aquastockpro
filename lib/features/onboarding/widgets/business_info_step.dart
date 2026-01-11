import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../screens/setup_wizard_screen.dart';

class BusinessInfoStep extends StatefulWidget {
  final SetupWizardData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BusinessInfoStep({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<BusinessInfoStep> createState() => _BusinessInfoStepState();
}

class _BusinessInfoStepState extends State<BusinessInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.data.businessName);
    _taglineController = TextEditingController(text: widget.data.tagline);
    _phoneController = TextEditingController(text: widget.data.businessPhone);
    _addressController = TextEditingController(text: widget.data.address);
    _cityController = TextEditingController(text: widget.data.city);
    _stateController = TextEditingController(text: widget.data.state);
    _postalCodeController = TextEditingController(text: widget.data.postalCode);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (_formKey.currentState!.validate()) {
      widget.data.businessName = _businessNameController.text.trim();
      widget.data.tagline = _taglineController.text.trim().isEmpty
          ? null
          : _taglineController.text.trim();
      widget.data.businessPhone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();
      widget.data.address = _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim();
      widget.data.city = _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim();
      widget.data.state = _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim();
      widget.data.postalCode = _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim();
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {

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
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter your business details. This will appear on receipts and invoices.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Business name (required)
            AppTextField(
              controller: _businessNameController,
              label: 'Business Name *',
              hint: 'Enter your business name',
              prefixIcon: const Icon(Iconsax.shop),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tagline (optional)
            AppTextField(
              controller: _taglineController,
              label: 'Tagline (Optional)',
              hint: 'e.g., Quality products at best prices',
              prefixIcon: const Icon(Iconsax.quote_up),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Phone
            AppTextField(
              controller: _phoneController,
              label: 'Business Phone',
              hint: 'Enter phone number',
              prefixIcon: const Icon(Iconsax.call),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),

            // Address
            AppTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'Street address',
              prefixIcon: const Icon(Iconsax.location),
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // City and State in row
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'City',
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _stateController,
                    label: 'State',
                    hint: 'State',
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Postal code
            AppTextField(
              controller: _postalCodeController,
              label: 'Postal Code',
              hint: 'PIN Code',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
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
