import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/business_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../shell/screens/main_shell.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ScreenBreakpoints.isMobile(context);
    final isDesktop = ScreenBreakpoints.isDesktop(context);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient accent
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.setting_2, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    'Configure your business settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 28),
          Expanded(
            child: settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (settings) => LayoutBuilder(
                builder: (context, constraints) {
                  // Use 2 columns on desktop (wide screens), 1 on mobile/tablet
                  final crossAxisCount = isDesktop && constraints.maxWidth > 700 ? 2 : 1;
                  final cardWidth = crossAxisCount == 2 
                      ? (constraints.maxWidth - 20) / 2 
                      : constraints.maxWidth;

                  final sections = [
                    // Theme/Appearance - NEW
                    _ThemeSection(ref: ref),
                    // Business Info - spans full width on 2-column
                    _SettingsSection(
                      title: 'Business Information',
                      subtitle: 'Your company details',
                      icon: Iconsax.building,
                      iconColor: AppColors.primary,
                      onEdit: () => _showBusinessInfoDialog(context, ref, settings),
                      child: Column(
                        children: [
                          _SettingsRow('Business Name', settings.businessName, Iconsax.shop),
                          _SettingsRow('Tagline', settings.tagline ?? 'Not set', Iconsax.text),
                          _SettingsRow('Address', settings.fullAddress.isEmpty ? 'Not set' : settings.fullAddress, Iconsax.location),
                          _SettingsRow('Phone', settings.phone ?? 'Not set', Iconsax.call),
                          _SettingsRow('Email', settings.email ?? 'Not set', Iconsax.sms),
                          _SettingsRow('GSTIN', settings.gstin ?? 'Not set', Iconsax.document),
                        ],
                      ),
                    ),
                    // Tax Settings
                    _SettingsSection(
                      title: 'Tax Settings',
                      subtitle: 'Tax rates & calculations',
                      icon: Iconsax.percentage_circle,
                      iconColor: AppColors.success,
                      onEdit: () => _showTaxSettingsDialog(context, ref, settings),
                      child: Column(
                        children: [
                          _SettingsRow('Tax Rate', '${settings.taxRate}%', Iconsax.chart),
                          _SettingsRow('Tax Label', settings.taxLabel ?? 'GST', Iconsax.tag),
                        ],
                      ),
                    ),
                    // Currency
                    _SettingsSection(
                      title: 'Currency',
                      subtitle: 'Payment display format',
                      icon: Iconsax.money,
                      iconColor: AppColors.warning,
                      onEdit: () => _showCurrencyDialog(context, ref, settings),
                      child: Column(
                        children: [
                          _SettingsRow('Currency Code', settings.currencyCode, Iconsax.global),
                          _SettingsRow('Currency Symbol', settings.currencySymbol, Iconsax.coin),
                        ],
                      ),
                    ),
                    // Receipt Settings
                    _SettingsSection(
                      title: 'Receipt Settings',
                      subtitle: 'Customize your receipts',
                      icon: Iconsax.receipt,
                      iconColor: AppColors.info,
                      onEdit: () => _showReceiptSettingsDialog(context, ref, settings),
                      child: Column(
                        children: [
                          _SettingsRow('Show Logo', settings.showLogo ? 'Yes' : 'No', Iconsax.image),
                          _SettingsRow('Tax Breakdown', settings.showTaxBreakdown ? 'Yes' : 'No', Iconsax.chart_2),
                          _SettingsRow('Header', settings.receiptHeader ?? 'Not set', Iconsax.text_block),
                          _SettingsRow('Footer', settings.receiptFooter ?? 'Not set', Iconsax.text_block),
                          _SettingsRow('Thank You', settings.thankYouMessage ?? 'Thank you!', Iconsax.heart),
                        ],
                      ),
                    ),
                    // Loyalty Program
                    _SettingsSection(
                      title: 'Loyalty Program',
                      subtitle: 'Reward your customers',
                      icon: Iconsax.gift,
                      iconColor: AppColors.error,
                      onEdit: () => _showLoyaltySettingsDialog(context, ref, settings),
                      child: Column(
                        children: [
                          _SettingsRow('Enable Points', settings.enableLoyaltyPoints ? 'Enabled' : 'Disabled', Iconsax.star),
                          _SettingsRow('Points Rate', '1 pt / ${settings.currencySymbol}${settings.loyaltyPointsPerAmount.toInt()}', Iconsax.award),
                        ],
                      ),
                    ),
                    // SMS Settings
                    _SettingsSection(
                      title: 'SMS Notifications',
                      subtitle: 'Auto-send bill SMS to customers',
                      icon: Iconsax.message,
                      iconColor: const Color(0xFF25D366),
                      onEdit: () => _showSmsSettingsDialog(context, ref, settings),
                      child: Column(
                        children: [
                          _SettingsRow('Status', settings.smsEnabled ? 'Enabled' : 'Disabled', Iconsax.notification),
                          _SettingsRow('Method', settings.smsMethod == 'cloud' ? 'Cloud API' : 'SIM Card', Iconsax.send_2),
                          if (settings.smsMethod == 'cloud')
                            _SettingsRow('Provider', settings.smsProvider.toUpperCase(), Iconsax.global),
                        ],
                      ),
                    ),
                    // Logo/Branding section
                    _LogoSection(settings: settings, ref: ref),
                    // Account / Logout section
                    _LogoutSection(ref: ref),
                  ];

                  if (crossAxisCount == 1) {
                    // Single column layout
                    return SingleChildScrollView(
                      child: Column(
                        children: sections.map((section) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: section,
                        )).toList(),
                      ),
                    );
                  }

                  // Two-column masonry-style layout
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        // Business Info spans full width
                        SizedBox(width: constraints.maxWidth, child: sections[0]),
                        // Rest in 2 columns
                        for (int i = 1; i < sections.length; i++)
                          SizedBox(width: cardWidth - 10, child: sections[i]),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBusinessInfoDialog(BuildContext context, WidgetRef ref, BusinessSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _BusinessInfoDialog(settings: settings),
    );
  }

  void _showTaxSettingsDialog(BuildContext context, WidgetRef ref, BusinessSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _TaxSettingsDialog(settings: settings),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, BusinessSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _CurrencyDialog(settings: settings),
    );
  }

  void _showReceiptSettingsDialog(BuildContext context, WidgetRef ref, BusinessSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _ReceiptSettingsDialog(settings: settings),
    );
  }

  void _showLoyaltySettingsDialog(BuildContext context, WidgetRef ref, BusinessSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _LoyaltySettingsDialog(settings: settings),
    );
  }

  void _showSmsSettingsDialog(BuildContext context, WidgetRef ref, BusinessSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _SmsSettingsDialog(settings: settings),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget child;
  final VoidCallback? onEdit;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.iconColor,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    final isDark = context.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadowColor : AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          hoverColor: color.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title, 
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (onEdit != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Iconsax.edit_2, size: 18, color: color),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  final WidgetRef ref;
  
  const _ThemeSection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadowColor : AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDark ? Iconsax.moon5 : Iconsax.sun_15,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Choose your preferred theme',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                _ThemeOption(
                  icon: Iconsax.autobrightness,
                  label: 'System',
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  icon: Iconsax.sun_1,
                  label: 'Light',
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  icon: Iconsax.moon,
                  label: 'Dark',
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends ConsumerStatefulWidget {
  final BusinessSettings settings;
  final WidgetRef ref;
  
  const _LogoSection({required this.settings, required this.ref});

  @override
  ConsumerState<_LogoSection> createState() => _LogoSectionState();
}

class _LogoSectionState extends ConsumerState<_LogoSection> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final bytes = await image.readAsBytes();
      final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.${image.name.split('.').last}';

      // Upload to Supabase
      final url = await SettingsRepository().uploadLogo(bytes, fileName);

      if (url != null) {
        // Refresh settings
        ref.invalidate(settingsNotifierProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo uploaded successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload logo. Please ensure the "logos" storage bucket exists in Supabase and is set to public.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } on Exception catch (e) {
      String errorMessage = 'Error uploading logo';
      
      // Parse error for more specific messages
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('bucket') || errorStr.contains('not found')) {
        errorMessage = 'Storage bucket "logos" not found. Please create it in Supabase Dashboard.';
      } else if (errorStr.contains('permission') || errorStr.contains('denied') || errorStr.contains('policy')) {
        errorMessage = 'Permission denied. Please check storage bucket policies in Supabase.';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorStr.contains('size') || errorStr.contains('large')) {
        errorMessage = 'Image too large. Please choose a smaller image.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLogo = widget.settings.logoUrl != null && widget.settings.logoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.image, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Logo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Used in receipts and branding',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // Logo preview or placeholder
            Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadLogo,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : hasLogo
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                widget.settings.logoUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholder(isDark);
                                },
                              ),
                            )
                          : _buildPlaceholder(isDark),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Upload button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: hasLogo ? 'Change Logo' : 'Upload Logo',
                icon: Iconsax.camera,
                variant: AppButtonVariant.outlined,
                isLoading: _isUploading,
                onPressed: _isUploading ? null : _pickAndUploadLogo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.gallery_add,
          size: 40,
          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _LogoutSection extends ConsumerWidget {
  final WidgetRef ref;
  
  const _LogoutSection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.user, color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (currentUser != null)
                        Text(
                          currentUser.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // User info row
            if (currentUser != null) ...[
              Row(
                children: [
                  Icon(Iconsax.profile_circle, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Name',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      currentUser.name,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.shield_tick, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Role',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      currentUser.roleDisplayName,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Logout',
                icon: Iconsax.logout,
                variant: AppButtonVariant.danger,
                onPressed: () => _confirmLogout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.logout, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout? You will need to enter your email/phone and password to login again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Logout',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(mode: LoginMode.full),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label, value;
  final IconData? icon;
  
  const _SettingsRow(this.label, this.value, [this.icon]);

  @override
  Widget build(BuildContext context) {
    final isNotSet = value == 'Not set';
    final isDark = context.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label, 
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isNotSet 
                    ? (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                fontStyle: isNotSet ? FontStyle.italic : FontStyle.normal,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


// ============== DIALOGS ==============

class _BusinessInfoDialog extends ConsumerStatefulWidget {
  final BusinessSettings settings;
  const _BusinessInfoDialog({required this.settings});

  @override
  ConsumerState<_BusinessInfoDialog> createState() => _BusinessInfoDialogState();
}

class _BusinessInfoDialogState extends ConsumerState<_BusinessInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _gstinController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.businessName);
    _taglineController = TextEditingController(text: widget.settings.tagline ?? '');
    _emailController = TextEditingController(text: widget.settings.email ?? '');
    _phoneController = TextEditingController(text: widget.settings.phone ?? '');
    _addressController = TextEditingController(text: widget.settings.address ?? '');
    _cityController = TextEditingController(text: widget.settings.city ?? '');
    _stateController = TextEditingController(text: widget.settings.state ?? '');
    _postalCodeController = TextEditingController(text: widget.settings.postalCode ?? '');
    _gstinController = TextEditingController(text: widget.settings.gstin ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: 'Edit Business Information'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Business Name *',
                        controller: _nameController,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Tagline',
                        controller: _taglineController,
                        hint: 'Your business tagline',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Phone',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Address',
                        controller: _addressController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'City',
                              controller: _cityController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'State',
                              controller: _stateController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Postal Code',
                              controller: _postalCodeController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'GSTIN',
                              controller: _gstinController,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _DialogActions(
              isLoading: _isLoading,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(settingsNotifierProvider.notifier).updateBusinessInfo(
        businessName: _nameController.text.trim(),
        tagline: _taglineController.text.trim().isEmpty ? null : _taglineController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        stateName: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business information updated'), backgroundColor: AppColors.success),
        );
      }
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

class _TaxSettingsDialog extends ConsumerStatefulWidget {
  final BusinessSettings settings;
  const _TaxSettingsDialog({required this.settings});

  @override
  ConsumerState<_TaxSettingsDialog> createState() => _TaxSettingsDialogState();
}

class _TaxSettingsDialogState extends ConsumerState<_TaxSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taxRateController;
  late TextEditingController _taxLabelController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taxRateController = TextEditingController(text: widget.settings.taxRate.toString());
    _taxLabelController = TextEditingController(text: widget.settings.taxLabel ?? 'GST');
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    _taxLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: 'Edit Tax Settings'),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Tax Rate (%)',
                      controller: _taxRateController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Tax Label',
                      controller: _taxLabelController,
                      hint: 'e.g., GST, VAT, Tax',
                    ),
                  ],
                ),
              ),
            ),
            _DialogActions(isLoading: _isLoading, onSave: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(settingsNotifierProvider.notifier).updateTaxSettings(
        taxRate: double.tryParse(_taxRateController.text) ?? 5.0,
        taxLabel: _taxLabelController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tax settings updated'), backgroundColor: AppColors.success),
        );
      }
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

class _CurrencyDialog extends ConsumerStatefulWidget {
  final BusinessSettings settings;
  const _CurrencyDialog({required this.settings});

  @override
  ConsumerState<_CurrencyDialog> createState() => _CurrencyDialogState();
}

class _CurrencyDialogState extends ConsumerState<_CurrencyDialog> {
  late String _selectedCurrency;
  bool _isLoading = false;

  final Map<String, String> _currencies = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SAR': '﷼',
    'JPY': '¥',
    'CNY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.settings.currencyCode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: 'Select Currency'),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final code = _currencies.keys.elementAt(index);
                  final symbol = _currencies[code]!;
                  final isSelected = code == _selectedCurrency;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          symbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(code),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () => setState(() => _selectedCurrency = code),
                  );
                },
              ),
            ),
            _DialogActions(isLoading: _isLoading, onSave: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final current = ref.read(settingsNotifierProvider).valueOrNull;
      if (current != null) {
        final updated = current.copyWith(
          currencyCode: _selectedCurrency,
          currencySymbol: _currencies[_selectedCurrency],
        );
        await ref.read(settingsNotifierProvider.notifier).updateSettings(updated);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Currency updated'), backgroundColor: AppColors.success),
        );
      }
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

class _ReceiptSettingsDialog extends ConsumerStatefulWidget {
  final BusinessSettings settings;
  const _ReceiptSettingsDialog({required this.settings});

  @override
  ConsumerState<_ReceiptSettingsDialog> createState() => _ReceiptSettingsDialogState();
}

class _ReceiptSettingsDialogState extends ConsumerState<_ReceiptSettingsDialog> {
  late bool _showLogo;
  late bool _showTaxBreakdown;
  late TextEditingController _headerController;
  late TextEditingController _footerController;
  late TextEditingController _thankYouController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _showLogo = widget.settings.showLogo;
    _showTaxBreakdown = widget.settings.showTaxBreakdown;
    _headerController = TextEditingController(text: widget.settings.receiptHeader ?? '');
    _footerController = TextEditingController(text: widget.settings.receiptFooter ?? '');
    _thankYouController = TextEditingController(text: widget.settings.thankYouMessage ?? '');
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _thankYouController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: 'Edit Receipt Settings'),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Show Logo on Receipt'),
                    value: _showLogo,
                    onChanged: (v) => setState(() => _showLogo = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Show Tax Breakdown'),
                    value: _showTaxBreakdown,
                    onChanged: (v) => setState(() => _showTaxBreakdown = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Receipt Header',
                    controller: _headerController,
                    hint: 'Text to show at top of receipt',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Receipt Footer',
                    controller: _footerController,
                    hint: 'Text to show at bottom of receipt',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Thank You Message',
                    controller: _thankYouController,
                    hint: 'e.g., Thank you for shopping with us!',
                  ),
                ],
              ),
            ),
            _DialogActions(isLoading: _isLoading, onSave: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(settingsNotifierProvider.notifier).updateReceiptSettings(
        showLogo: _showLogo,
        showTaxBreakdown: _showTaxBreakdown,
        receiptHeader: _headerController.text.trim().isEmpty ? null : _headerController.text.trim(),
        receiptFooter: _footerController.text.trim().isEmpty ? null : _footerController.text.trim(),
        thankYouMessage: _thankYouController.text.trim().isEmpty ? null : _thankYouController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt settings updated'), backgroundColor: AppColors.success),
        );
      }
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

class _LoyaltySettingsDialog extends ConsumerStatefulWidget {
  final BusinessSettings settings;
  const _LoyaltySettingsDialog({required this.settings});

  @override
  ConsumerState<_LoyaltySettingsDialog> createState() => _LoyaltySettingsDialogState();
}

class _LoyaltySettingsDialogState extends ConsumerState<_LoyaltySettingsDialog> {
  late bool _enableLoyalty;
  late TextEditingController _pointsPerAmountController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _enableLoyalty = widget.settings.enableLoyaltyPoints;
    _pointsPerAmountController = TextEditingController(
      text: widget.settings.loyaltyPointsPerAmount.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _pointsPerAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: 'Loyalty Program Settings'),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Loyalty Points'),
                    subtitle: const Text('Award points on purchases'),
                    value: _enableLoyalty,
                    onChanged: (v) => setState(() => _enableLoyalty = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Amount per 1 Point',
                    controller: _pointsPerAmountController,
                    hint: 'e.g., 100 means 1 point per ₹100 spent',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: _enableLoyalty,
                  ),
                ],
              ),
            ),
            _DialogActions(isLoading: _isLoading, onSave: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final current = ref.read(settingsNotifierProvider).valueOrNull;
      if (current != null) {
        final updated = current.copyWith(
          enableLoyaltyPoints: _enableLoyalty,
          loyaltyPointsPerAmount: double.tryParse(_pointsPerAmountController.text) ?? 100,
        );
        await ref.read(settingsNotifierProvider.notifier).updateSettings(updated);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loyalty settings updated'), backgroundColor: AppColors.success),
        );
      }
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

// Common dialog widgets
class _DialogHeader extends StatelessWidget {
  final String title;
  const _DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSave;

  const _DialogActions({required this.isLoading, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
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
              label: 'Save Changes',
              icon: Iconsax.tick_circle,
              isLoading: isLoading,
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

// ============== SMS SETTINGS DIALOG ==============

class _SmsSettingsDialog extends ConsumerStatefulWidget {
  final BusinessSettings settings;
  const _SmsSettingsDialog({required this.settings});

  @override
  ConsumerState<_SmsSettingsDialog> createState() => _SmsSettingsDialogState();
}

class _SmsSettingsDialogState extends ConsumerState<_SmsSettingsDialog> {
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testResult;
  
  late bool _smsEnabled;
  late String _smsMethod;
  late String _smsProvider;
  late TextEditingController _apiKeyController;
  late TextEditingController _senderIdController;
  late TextEditingController _templateIdController;
  late TextEditingController _templateController;
  late TextEditingController _testPhoneController;

  @override
  void initState() {
    super.initState();
    _smsEnabled = widget.settings.smsEnabled;
    _smsMethod = widget.settings.smsMethod;
    _smsProvider = widget.settings.smsProvider;
    _apiKeyController = TextEditingController(text: widget.settings.smsApiKey ?? '');
    _senderIdController = TextEditingController(text: widget.settings.smsSenderId ?? '');
    _templateIdController = TextEditingController(text: widget.settings.smsTemplateId ?? '');
    _templateController = TextEditingController(text: widget.settings.smsTemplate);
    _testPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _senderIdController.dispose();
    _templateIdController.dispose();
    _templateController.dispose();
    _testPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: 'SMS Notifications'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enable Toggle
                    SwitchListTile(
                      title: const Text('Enable SMS Notifications'),
                      subtitle: Text(_smsEnabled 
                        ? 'SMS will be sent when bill is confirmed'
                        : 'SMS notifications are disabled'),
                      value: _smsEnabled,
                      activeThumbColor: const Color(0xFF25D366),
                      onChanged: (value) => setState(() => _smsEnabled = value),
                    ),
                    
                    if (_smsEnabled) ...[
                      const Divider(height: 32),
                      
                      // Method Selection
                      Text('Sending Method', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'sim', label: Text('SIM Card'), icon: Icon(Iconsax.mobile)),
                          ButtonSegment(value: 'cloud', label: Text('Cloud API'), icon: Icon(Iconsax.cloud)),
                        ],
                        selected: {_smsMethod},
                        onSelectionChanged: (value) => setState(() => _smsMethod = value.first),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.info_circle, size: 16, color: AppColors.info),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _smsMethod == 'sim'
                                  ? 'Uses device SIM to send SMS (Android only, free)'
                                  : 'Uses cloud API to send SMS (all platforms, paid)',
                                style: const TextStyle(fontSize: 12, color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (_smsMethod == 'cloud') ...[
                        const SizedBox(height: 24),
                        
                        // Provider Selection
                        Text('SMS Provider', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _smsProvider,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Iconsax.global),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'msg91', child: Text('MSG91 (India)')),
                            DropdownMenuItem(value: 'fast2sms', child: Text('Fast2SMS (India)')),
                            DropdownMenuItem(value: 'twilio', child: Text('Twilio (International)')),
                          ],
                          onChanged: (value) => setState(() => _smsProvider = value!),
                        ),
                        
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _apiKeyController,
                          label: _smsProvider == 'twilio' ? 'Account SID:Auth Token' : 'API Key',
                          hint: _smsProvider == 'twilio' ? 'ACXXXX:your_auth_token' : 'Enter API key',
                          prefixIcon: const Icon(Iconsax.key),
                          obscureText: true,
                        ),
                        
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _senderIdController,
                          label: 'Sender ID',
                          hint: 'e.g. AQUAPO',
                          prefixIcon: const Icon(Iconsax.user_tag),
                        ),
                        
                        if (_smsProvider == 'msg91') ...[
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _templateIdController,
                            label: 'DLT Template ID',
                            hint: 'Required for India',
                            prefixIcon: const Icon(Iconsax.document),
                          ),
                        ],
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Template
                      Text('SMS Template', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _templateController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Message template...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          helperText: 'Variables: {business_name}, {order_id}, {total}, {date}, {customer_name}',
                          helperMaxLines: 2,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Test SMS
                      Text('Test SMS', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _testPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '9876543210',
                                prefixText: '+91 ',
                                prefixIcon: const Icon(Iconsax.call),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isTesting ? null : _sendTestSms,
                            icon: _isTesting 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Iconsax.send_1),
                            label: const Text('Test'),
                          ),
                        ],
                      ),
                      
                      if (_testResult != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _testResult!.startsWith('✅') 
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _testResult!.startsWith('✅') ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            _DialogActions(isLoading: _isLoading, onSave: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestSms() async {
    if (_testPhoneController.text.isEmpty) {
      setState(() => _testResult = '❌ Please enter a phone number');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    // Note: Test SMS sending requires SmsService integration
    // For now, we'll just validate the configuration
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isTesting = false;
      if (_smsMethod == 'cloud' && _apiKeyController.text.isEmpty) {
        _testResult = '❌ API Key is required for cloud SMS';
      } else {
        _testResult = '✅ Configuration looks good! Save and test with a real order.';
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final updatedSettings = widget.settings.copyWith(
        smsEnabled: _smsEnabled,
        smsMethod: _smsMethod,
        smsProvider: _smsProvider,
        smsApiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
        smsSenderId: _senderIdController.text.trim().isEmpty ? null : _senderIdController.text.trim(),
        smsTemplateId: _templateIdController.text.trim().isEmpty ? null : _templateIdController.text.trim(),
        smsTemplate: _templateController.text.trim().isEmpty 
          ? BusinessSettings.defaultSmsTemplate 
          : _templateController.text.trim(),
      );

      await ref.read(settingsNotifierProvider.notifier).updateSettings(updatedSettings);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
