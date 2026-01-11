import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/pin_input_widget.dart';
import '../../shell/screens/main_shell.dart';
import '../../onboarding/screens/setup_wizard_screen.dart';

/// Login modes:
/// - Full login: Email/Phone + Password (after logout or first time)
/// - PIN only: When app reopens with existing session
enum LoginMode { full, pinOnly }

class LoginScreen extends ConsumerStatefulWidget {
  final LoginMode mode;
  
  const LoginScreen({
    super.key,
    this.mode = LoginMode.full,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _savedUserName;

  @override
  void initState() {
    super.initState();
    if (widget.mode == LoginMode.pinOnly) {
      _loadSavedUserInfo();
    }
  }

  Future<void> _loadSavedUserInfo() async {
    // Load the saved user name for PIN login display
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      setState(() {
        _savedUserName = authState.user!.name;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).loginWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else {
        setState(() {
          _errorMessage = ref.read(authProvider).error ?? 'Invalid credentials. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithPin(String pin) async {
    if (pin.length != 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).loginWithPin(pin);
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN. Please try again.';
          _pinController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
        _pinController.clear();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchToFullLogin() {
    // User wants to login with different account
    ref.read(authProvider.notifier).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(mode: LoginMode.full),
      ),
    );
  }

  void _goToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SetupWizardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 48,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and branding
                    _buildHeader(isDark),
                    const SizedBox(height: 48),

                    // Login card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardBackground
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? AppColors.black.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: widget.mode == LoginMode.pinOnly
                          ? _buildPinLoginSection(isDark)
                          : _buildFullLoginSection(isDark),
                    ),

                    const SizedBox(height: 24),

                    // Version info
                    Text(
                      'v${AppConstants.appVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 40,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.mode == LoginMode.pinOnly
              ? 'Enter PIN to unlock'
              : 'Sign in to continue',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildFullLoginSection(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email/Phone field
          AppTextField(
            controller: _emailController,
            label: 'Email or Phone',
            hint: 'Enter your email or phone number',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Iconsax.user),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email or phone is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Password field
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Iconsax.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            onSubmitted: (_) => _loginWithEmailPassword(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 4) {
                return 'Password must be at least 4 characters';
              }
              return null;
            },
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Login button
          AppButton(
            label: 'Sign In',
            onPressed: _isLoading ? null : _loginWithEmailPassword,
            isLoading: _isLoading,
            isFullWidth: true,
            size: AppButtonSize.large,
            icon: Iconsax.login,
          ),

          const SizedBox(height: 16),

          // Register/Setup link - only show if no users exist
          Consumer(
            builder: (context, ref, _) {
              final hasUsersAsync = ref.watch(hasUsersProvider);
              return hasUsersAsync.when(
                data: (hasUsers) {
                  if (hasUsers) {
                    // Users exist - don't show registration
                    return const SizedBox.shrink();
                  }
                  // No users - show registration link
                  return Center(
                    child: TextButton(
                      onPressed: _goToSetup,
                      child: Text(
                        "Don't have an account? Set up now",
                        style: TextStyle(
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(), // Hide while checking
                error: (_, __) => const SizedBox.shrink(), // Hide on error
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPinLoginSection(bool isDark) {
    return Column(
      children: [
        // User info
        if (_savedUserName != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _savedUserName![0].toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        _savedUserName!,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // PIN Input
        PinInputWidget(
          controller: _pinController,
          onCompleted: _loginWithPin,
          isLoading: _isLoading,
          hasError: _errorMessage != null,
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 24),

        // Switch account option
        TextButton.icon(
          onPressed: _switchToFullLogin,
          icon: const Icon(Iconsax.user_edit, size: 18),
          label: const Text('Use different account'),
        ),
      ],
    );
  }
}
