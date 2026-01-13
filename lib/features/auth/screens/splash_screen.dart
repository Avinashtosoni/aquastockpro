import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../onboarding/screens/setup_wizard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Check if we have internet connectivity and Supabase is initialized
    final connectivity = ConnectivityService();
    if (!connectivity.isOnline) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No internet connection. Please check your network and try again.';
        });
      }
      return;
    }

    if (!SupabaseService.isInitialized) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to connect to server. Please try again.';
        });
      }
      return;
    }

    try {
      // Check if any users exist - Setup wizard only shows if NO users exist
      // This ensures only the first user (admin) sees the wizard
      final users = await UserRepository().getAll();
      final hasNoUsers = users.isEmpty;

      // Check if user has active session (logged in before)
      final prefs = await SharedPreferences.getInstance();
      final hasActiveSession = prefs.getBool(AppConstants.hasActiveSessionKey) ?? false;
      final lastUserId = prefs.getString(AppConstants.lastLoggedInUserKey);

      if (!mounted) return;

      Widget destination;
      
      if (hasNoUsers) {
        // No users exist - first time setup, show wizard
        // First user created will be admin
        destination = const SetupWizardScreen();
      } else if (hasActiveSession && lastUserId != null) {
        // User was logged in - ask for PIN only
        // First, restore the user session
        await ref.read(authProvider.notifier).restoreSession(lastUserId);
        destination = const LoginScreen(mode: LoginMode.pinOnly);
      } else {
        // Users exist but not logged in - full login required
        destination = const LoginScreen(mode: LoginMode.full);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      debugPrint('SplashScreen error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: ${e.toString().contains('internet') ? 'No internet connection' : 'Unable to connect to server'}';
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
    });
    _initializeAndNavigate();
  }



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final isTablet = size.width > 600 && size.width <= 800;
    
    // Responsive sizes
    final logoSize = isDesktop ? 160.0 : isTablet ? 140.0 : 100.0;
    final iconSize = isDesktop ? 80.0 : isTablet ? 70.0 : 50.0;
    final borderRadius = isDesktop ? 40.0 : isTablet ? 35.0 : 25.0;
    final titleSize = isDesktop ? 36.0 : isTablet ? 32.0 : 26.0;
    final taglineSize = isDesktop ? 18.0 : isTablet ? 16.0 : 14.0;
    final loaderSize = isDesktop ? 50.0 : 40.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                  ]
                : [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Main content centered
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container - Responsive
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(borderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.2),
                              blurRadius: isDesktop ? 40 : 30,
                              spreadRadius: isDesktop ? 8 : 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          size: iconSize,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 48 : 32),
                      // App Name - Responsive
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: titleSize,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      // Tagline - Responsive
                      Text(
                        AppConstants.appTagline,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: taglineSize,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 80 : 60),
                      // Show error or loading indicator
                      if (_errorMessage != null) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 32),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: isDesktop ? 16 : 14,
                            ),
                          ),
                        ),
                        SizedBox(height: isDesktop ? 32 : 24),
                        ElevatedButton.icon(
                          onPressed: _retry,
                          icon: Icon(Icons.refresh, size: isDesktop ? 24 : 20),
                          label: Text('Retry', style: TextStyle(fontSize: isDesktop ? 16 : 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 48 : 32, 
                              vertical: isDesktop ? 16 : 12,
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: loaderSize,
                          height: loaderSize,
                          child: CircularProgressIndicator(
                            strokeWidth: isDesktop ? 4 : 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
