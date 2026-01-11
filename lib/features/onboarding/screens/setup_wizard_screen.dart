import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/business_settings.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../widgets/welcome_step.dart';
import '../widgets/business_info_step.dart';
import '../widgets/tax_currency_step.dart';
import '../widgets/admin_setup_step.dart';
import '../widgets/completion_step.dart';
import '../../auth/screens/login_screen.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  final String? initialPhone;

  const SetupWizardScreen({
    super.key,
    this.initialPhone,
  });

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  final _wizardData = SetupWizardData();

  final List<String> _stepTitles = [
    'Welcome',
    'Business Info',
    'Tax & Currency',
    'Admin Account',
    'All Done!',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _wizardData.adminPhone = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save business settings
      final settingsRepo = SettingsRepository();
      final settings = BusinessSettings(
        businessName: _wizardData.businessName,
        tagline: _wizardData.tagline,
        phone: _wizardData.businessPhone,
        address: _wizardData.address,
        city: _wizardData.city,
        state: _wizardData.state,
        postalCode: _wizardData.postalCode,
        gstin: _wizardData.gstin,
        currencySymbol: _wizardData.currencySymbol,
        currencyCode: _wizardData.currencyCode,
        taxRate: _wizardData.taxRate,
        taxLabel: _wizardData.taxLabel,
      );
      await settingsRepo.updateSettings(settings);

      // Create admin user
      final userRepo = UserRepository();
      await userRepo.createUser(
        email: _wizardData.adminEmail,
        name: _wizardData.adminName,
        phone: _wizardData.adminPhone,
        role: UserRole.admin,
        pin: _wizardData.adminPin,
        password: _wizardData.adminPassword,
      );

      // Mark setup as complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isSetupCompleteKey, true);

      // Move to completion step
      _nextStep();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(mode: LoginMode.full),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.background, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              _buildHeader(isDark),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    WelcomeStep(onNext: _nextStep),
                    BusinessInfoStep(
                      data: _wizardData,
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                    TaxCurrencyStep(
                      data: _wizardData,
                      onNext: _nextStep,
                      onBack: _previousStep,
                    ),
                    AdminSetupStep(
                      data: _wizardData,
                      onComplete: _completeSetup,
                      onBack: _previousStep,
                      isLoading: _isLoading,
                    ),
                    CompletionStep(onFinish: _goToLogin),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_stepTitles.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 32 : 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.grey300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 10,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  if (index < _stepTitles.length - 1)
                    Container(
                      width: 20,
                      height: 2,
                      color: isCompleted
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.grey300),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          // Step title
          Text(
            _stepTitles[_currentStep],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Data class to hold all wizard form data
class SetupWizardData {
  // Business Info
  String businessName = '';
  String? tagline;
  String? businessPhone;
  String? address;
  String? city;
  String? state;
  String? postalCode;
  String? gstin;

  // Tax & Currency
  String currencySymbol = '₹';
  String currencyCode = 'INR';
  double taxRate = 5.0;
  String taxLabel = 'GST';

  // Admin Account
  String adminName = '';
  String adminEmail = '';
  String adminPhone = '';
  String adminPin = '';
  String adminPassword = '';
}
