import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/discount.dart';
import '../data/repositories/discount_repository.dart';

// Discount state
class DiscountState {
  final List<Discount> discounts;
  final List<Discount> activeDiscounts;
  final Discount? appliedDiscount;
  final bool isLoading;
  final String? error;

  const DiscountState({
    this.discounts = const [],
    this.activeDiscounts = const [],
    this.appliedDiscount,
    this.isLoading = false,
    this.error,
  });

  DiscountState copyWith({
    List<Discount>? discounts,
    List<Discount>? activeDiscounts,
    Discount? appliedDiscount,
    bool? isLoading,
    String? error,
    bool clearAppliedDiscount = false,
  }) {
    return DiscountState(
      discounts: discounts ?? this.discounts,
      activeDiscounts: activeDiscounts ?? this.activeDiscounts,
      appliedDiscount: clearAppliedDiscount ? null : (appliedDiscount ?? this.appliedDiscount),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Discount notifier
class DiscountNotifier extends StateNotifier<DiscountState> {
  final DiscountRepository _repository;

  DiscountNotifier(this._repository) : super(const DiscountState());

  /// Load all discounts
  Future<void> loadDiscounts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final discounts = await _repository.getAll();
      final activeDiscounts = await _repository.getActiveDiscounts();
      state = state.copyWith(
        discounts: discounts,
        activeDiscounts: activeDiscounts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Validate and apply a discount code
  Future<bool> applyDiscountCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final discount = await _repository.validateCode(code);
      if (discount != null) {
        state = state.copyWith(appliedDiscount: discount, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid or expired discount code',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Apply a discount directly
  void applyDiscount(Discount discount) {
    if (discount.isValid) {
      state = state.copyWith(appliedDiscount: discount);
    }
  }

  /// Remove applied discount
  void removeDiscount() {
    state = state.copyWith(clearAppliedDiscount: true);
  }

  /// Calculate discount for subtotal
  double calculateDiscount(double subtotal) {
    if (state.appliedDiscount == null) return 0;
    return state.appliedDiscount!.calculateDiscount(subtotal);
  }

  /// Confirm discount usage (after order is placed)
  Future<void> confirmUsage() async {
    if (state.appliedDiscount != null) {
      await _repository.incrementUsage(state.appliedDiscount!.id);
      state = state.copyWith(clearAppliedDiscount: true);
    }
  }

  /// Create a new discount
  Future<bool> createDiscount(Discount discount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.insert(discount);
      await loadDiscounts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Update a discount
  Future<bool> updateDiscount(Discount discount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.update(discount);
      await loadDiscounts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Deactivate a discount
  Future<bool> deactivateDiscount(String discountId) async {
    try {
      await _repository.deactivate(discountId);
      await loadDiscounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a discount
  Future<bool> deleteDiscount(String discountId) async {
    try {
      await _repository.delete(discountId);
      await loadDiscounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get discounts applicable to a product
  Future<List<Discount>> getProductDiscounts(String productId, String categoryId) async {
    try {
      return await _repository.getForProduct(productId, categoryId);
    } catch (e) {
      return [];
    }
  }

  /// Get expiring discounts
  Future<List<Discount>> getExpiringSoon({int days = 7}) async {
    try {
      return await _repository.getExpiringSoon(days: days);
    } catch (e) {
      return [];
    }
  }

  /// Get discount statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      return await _repository.getStats();
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

// Providers
final discountRepositoryProvider = Provider((ref) => DiscountRepository());

final discountProvider = StateNotifierProvider<DiscountNotifier, DiscountState>((ref) {
  return DiscountNotifier(ref.watch(discountRepositoryProvider));
});

// Convenience providers
final activeDiscountsProvider = Provider<List<Discount>>((ref) {
  return ref.watch(discountProvider).activeDiscounts;
});

final appliedDiscountProvider = Provider<Discount?>((ref) {
  return ref.watch(discountProvider).appliedDiscount;
});

final discountAmountProvider = Provider.family<double, double>((ref, subtotal) {
  final state = ref.watch(discountProvider);
  if (state.appliedDiscount == null) return 0;
  return state.appliedDiscount!.calculateDiscount(subtotal);
});
