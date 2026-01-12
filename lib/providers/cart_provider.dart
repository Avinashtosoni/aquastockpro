import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product.dart';
import '../data/models/order_item.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double discount;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }

  double get subtotal => product.price * quantity;
  double get total => subtotal - discount;
  
  /// Returns effective GST rate: product's GST if set (>0), otherwise defaultRate from settings
  double effectiveGstRate(double defaultRate) {
    return product.gstRate > 0 ? product.gstRate : defaultRate;
  }
  
  /// Calculate tax amount for this item using effective GST rate
  double taxAmount(double defaultRate) {
    final rate = effectiveGstRate(defaultRate);
    return (subtotal - discount) * (rate / 100);
  }
}

class CartState {
  final List<CartItem> items;
  final String? customerId;
  final String? customerName;
  final double discountAmount;
  final double taxRate; // Default tax rate from settings (fallback for products with 0% GST)
  final String? notes;
  final bool isOnHold;

  const CartState({
    this.items = const [],
    this.customerId,
    this.customerName,
    this.discountAmount = 0,
    this.taxRate = 5.0,
    this.notes,
    this.isOnHold = false,
  });

  CartState copyWith({
    List<CartItem>? items,
    String? customerId,
    String? customerName,
    double? discountAmount,
    double? taxRate,
    String? notes,
    bool? isOnHold,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      isOnHold: isOnHold ?? this.isOnHold,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  
  double get itemDiscounts => items.fold(0, (sum, item) => sum + item.discount);
  
  double get totalDiscount => itemDiscounts + discountAmount;
  
  double get taxableAmount => subtotal - totalDiscount;
  
  /// Calculate total tax using per-product GST rates
  /// For products with gstRate > 0, use product's rate
  /// For products with gstRate = 0, use the default taxRate from settings
  double get taxAmount {
    // Calculate per-product tax with effective GST rates
    double totalTax = 0;
    for (final item in items) {
      totalTax += item.taxAmount(taxRate);
    }
    // Apply discount proportionally (discount reduces taxable amount)
    if (discountAmount > 0 && subtotal > 0) {
      final discountRatio = discountAmount / subtotal;
      totalTax = totalTax * (1 - discountRatio);
    }
    return totalTax;
  }
  
  double get total => taxableAmount + taxAmount;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  List<OrderItem> toOrderItems(String orderId) {
    return items.map((item) => OrderItem(
      orderId: orderId,
      productId: item.product.id,
      productName: item.product.name,
      unitPrice: item.product.price,
      quantity: item.quantity,
      discount: item.discount,
      taxRate: item.effectiveGstRate(taxRate), // Use product's GST or default
    )).toList();
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, quantity: quantity)],
      );
    }
  }

  void removeProduct(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void incrementQuantity(String productId) {
    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void decrementQuantity(String productId) {
    final item = state.items.firstWhere((i) => i.product.id == productId);
    if (item.quantity <= 1) {
      removeProduct(productId);
    } else {
      updateQuantity(productId, item.quantity - 1);
    }
  }

  void setItemDiscount(String productId, double discount) {
    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(discount: discount);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void setCustomer(String? customerId, String? customerName) {
    state = state.copyWith(
      customerId: customerId,
      customerName: customerName,
    );
  }

  void setDiscount(double discount) {
    state = state.copyWith(discountAmount: discount);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void holdOrder() {
    state = state.copyWith(isOnHold: true);
  }

  void clearCart() {
    state = const CartState();
  }

  // For holding orders
  CartState getState() => state;

  void restoreState(CartState savedState) {
    state = savedState.copyWith(isOnHold: false);
  }
}

// Providers
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).total;
});

// Held orders storage
final heldOrdersProvider = StateProvider<List<CartState>>((ref) => []);
