/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AquaStock Pro';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart POS for Smart Business';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const int decimalPlaces = 2;

  // Tax
  static const double defaultTaxRate = 5.0; // 5%
  static const double gstRate = 18.0; // GST

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String businessSettingsKey = 'business_settings';
  static const String themeKey = 'app_theme';
  static const String lastSyncKey = 'last_sync';
  static const String isSetupCompleteKey = 'is_setup_complete';
  static const String lastLoggedInUserKey = 'last_logged_in_user';
  static const String hasActiveSessionKey = 'has_active_session';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd/MM/yyyy hh:mm a';

  // Order Number Prefix
  static const String orderPrefix = 'ORD';
  static const String invoicePrefix = 'INV';

  // Default Values
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 5;

  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Layout
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 80.0;
  static const double headerHeight = 70.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
}
