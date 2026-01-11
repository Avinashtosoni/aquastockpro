import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/supabase_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences? prefs;
  
  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize SharedPreferences
    prefs = await SharedPreferences.getInstance();
    
    // Initialize Supabase using SupabaseService (so isInitialized flag is set)
    await SupabaseService.initialize();
    
    // Initialize connectivity service
    await ConnectivityService().initialize();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AquaStockProApp(),
    ),
  );
}

class AquaStockProApp extends ConsumerWidget {
  const AquaStockProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
