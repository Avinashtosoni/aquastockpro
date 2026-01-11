import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/business_settings.dart';
import '../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// Business settings
final settingsProvider = FutureProvider<BusinessSettings>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getSettings();
});

// Settings notifier for updates
class SettingsNotifier extends StateNotifier<AsyncValue<BusinessSettings>> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _ref.read(settingsRepositoryProvider).getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(BusinessSettings settings) async {
    try {
      await _ref.read(settingsRepositoryProvider).updateSettings(settings);
      await loadSettings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBusinessInfo({
    String? businessName,
    String? tagline,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? stateName,
    String? postalCode,
    String? gstin,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      businessName: businessName,
      tagline: tagline,
      email: email,
      phone: phone,
      address: address,
      city: city,
      state: stateName,
      postalCode: postalCode,
      gstin: gstin,
    );
    await updateSettings(updated);
  }

  Future<void> updateTaxSettings({
    double? taxRate,
    String? taxLabel,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      taxRate: taxRate,
      taxLabel: taxLabel,
    );
    await updateSettings(updated);
  }

  Future<void> updateReceiptSettings({
    bool? showLogo,
    bool? showTaxBreakdown,
    String? receiptHeader,
    String? receiptFooter,
    String? thankYouMessage,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      showLogo: showLogo,
      showTaxBreakdown: showTaxBreakdown,
      receiptHeader: receiptHeader,
      receiptFooter: receiptFooter,
      thankYouMessage: thankYouMessage,
    );
    await updateSettings(updated);
  }

  Future<void> updateLogo(String logoUrl) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(logoUrl: logoUrl);
    await updateSettings(updated);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<BusinessSettings>>((ref) {
  return SettingsNotifier(ref);
});
