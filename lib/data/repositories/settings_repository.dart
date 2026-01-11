import 'package:flutter/foundation.dart';
import '../models/business_settings.dart';
import '../services/connectivity_service.dart';
import '../services/supabase_service.dart';
import '../../core/constants/supabase_config.dart';

class SettingsRepository {
  static final SettingsRepository _instance = SettingsRepository._internal();
  final ConnectivityService _connectivityService = ConnectivityService();

  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  void _checkConnection() {
    if (!_connectivityService.isOnline || !SupabaseService.isInitialized) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

  Future<BusinessSettings> getSettings() async {
    _checkConnection();
    
    final response = await SupabaseService.client
        .from(SupabaseConfig.businessSettingsTable)
        .select()
        .eq('id', 'default')
        .maybeSingle();
    
    if (response == null) {
      // Return default settings
      return BusinessSettings();
    }
    
    return BusinessSettings.fromMap(response);
  }

  Future<BusinessSettings> updateSettings(BusinessSettings settings) async {
    _checkConnection();
    
    final map = settings.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    
    // Check if exists
    final existing = await SupabaseService.client
        .from(SupabaseConfig.businessSettingsTable)
        .select('id')
        .eq('id', settings.id)
        .maybeSingle();
    
    if (existing == null) {
      await SupabaseService.client
          .from(SupabaseConfig.businessSettingsTable)
          .insert(map);
    } else {
      await SupabaseService.client
          .from(SupabaseConfig.businessSettingsTable)
          .update(map)
          .eq('id', settings.id);
    }
    
    return settings;
  }

  Future<void> updateLogo(String logoUrl) async {
    _checkConnection();
    
    await SupabaseService.client
        .from(SupabaseConfig.businessSettingsTable)
        .update({
          'logo_url': logoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 'default');
  }

  Future<void> updateReceiptSettings({
    String? header,
    String? footer,
    String? thankYouMessage,
    bool? showLogo,
    bool? showTaxBreakdown,
  }) async {
    _checkConnection();
    
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (header != null) updates['receipt_header'] = header;
    if (footer != null) updates['receipt_footer'] = footer;
    if (thankYouMessage != null) updates['thank_you_message'] = thankYouMessage;
    if (showLogo != null) updates['show_logo'] = showLogo;
    if (showTaxBreakdown != null) updates['show_tax_breakdown'] = showTaxBreakdown;
    
    await SupabaseService.client
        .from(SupabaseConfig.businessSettingsTable)
        .update(updates)
        .eq('id', 'default');
  }

  Future<void> updateTaxSettings(double taxRate, String taxLabel) async {
    _checkConnection();
    
    await SupabaseService.client
        .from(SupabaseConfig.businessSettingsTable)
        .update({
          'tax_rate': taxRate,
          'tax_label': taxLabel,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 'default');
  }

  /// Upload logo to Supabase storage
  Future<String?> uploadLogo(List<int> imageBytes, String fileName) async {
    debugPrint('SettingsRepository.uploadLogo: Starting upload...');
    
    if (!_connectivityService.isOnline) {
      debugPrint('SettingsRepository.uploadLogo: FAILED - Device is offline');
      return null;
    }
    
    if (!SupabaseService.isInitialized) {
      debugPrint('SettingsRepository.uploadLogo: FAILED - Supabase not initialized');
      return null;
    }

    try {
      final path = fileName;
      debugPrint('SettingsRepository.uploadLogo: Uploading to ${SupabaseConfig.logosBucket}/$path');
      
      final publicUrl = await SupabaseService.uploadImage(
        SupabaseConfig.logosBucket,
        path,
        imageBytes,
      );
      
      debugPrint('SettingsRepository.uploadLogo: Got public URL: $publicUrl');
      
      // Update settings with logo URL
      await updateLogo(publicUrl);
      
      debugPrint('SettingsRepository.uploadLogo: SUCCESS');
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('SettingsRepository.uploadLogo ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
