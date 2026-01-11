import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/order_item.dart';
import '../models/business_settings.dart';
import 'package:intl/intl.dart';

/// Service for WhatsApp integration
class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  /// Share receipt via WhatsApp
  Future<bool> shareReceipt({
    required Order order,
    required List<OrderItem> items,
    required BusinessSettings settings,
    required String phoneNumber,
  }) async {
    final message = _generateReceiptMessage(order, items, settings);
    return await _sendWhatsAppMessage(phoneNumber, message);
  }

  /// Send order confirmation
  Future<bool> sendOrderConfirmation({
    required Order order,
    required Customer customer,
    required BusinessSettings settings,
  }) async {
    if (customer.phone == null || customer.phone!.isEmpty) return false;

    final message = '''
🛒 *Order Confirmation*
━━━━━━━━━━━━━━━━━━

Dear ${customer.name},

Your order has been placed successfully!

📋 Order #${order.orderNumber}
📅 Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}

💰 Total: ${_currencyFormat.format(order.totalAmount)}
💳 Payment: ${order.paymentMethodDisplayName}

Thank you for shopping with ${settings.businessName}!

For any queries, contact us at:
📞 ${settings.phone ?? 'N/A'}
''';

    return await _sendWhatsAppMessage(customer.phone!, message);
  }

  /// Send payment reminder
  Future<bool> sendPaymentReminder({
    required Customer customer,
    required double amount,
    required BusinessSettings settings,
  }) async {
    if (customer.phone == null || customer.phone!.isEmpty) return false;

    final message = '''
🔔 *Payment Reminder*
━━━━━━━━━━━━━━━━━━

Dear ${customer.name},

This is a friendly reminder that you have an outstanding balance of:

💰 *${_currencyFormat.format(amount)}*

Please clear your dues at your earliest convenience.

Thank you for your continued patronage!

${settings.businessName}
📞 ${settings.phone ?? 'N/A'}
''';

    return await _sendWhatsAppMessage(customer.phone!, message);
  }

  /// Send thank you message
  Future<bool> sendThankYouMessage({
    required Customer customer,
    required BusinessSettings settings,
  }) async {
    if (customer.phone == null || customer.phone!.isEmpty) return false;

    final message = '''
🙏 *Thank You!*
━━━━━━━━━━━━━━━━━━

Dear ${customer.name},

Thank you for shopping with us!

${settings.thankYouMessage ?? 'We appreciate your business and look forward to serving you again.'}

${settings.businessName}
📞 ${settings.phone ?? 'N/A'}
''';

    return await _sendWhatsAppMessage(customer.phone!, message);
  }

  /// Generate receipt message
  String _generateReceiptMessage(
    Order order,
    List<OrderItem> items,
    BusinessSettings settings,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('📄 *RECEIPT*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*${settings.businessName}*');
    if (settings.address != null) buffer.writeln(settings.address);
    if (settings.phone != null) buffer.writeln('📞 ${settings.phone}');
    buffer.writeln();
    buffer.writeln('Order: #${order.orderNumber}');
    buffer.writeln('Date: ${DateFormat('dd/MM/yyyy hh:mm a').format(order.createdAt)}');
    if (order.customerName != null) {
      buffer.writeln('Customer: ${order.customerName}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln();

    // Items
    for (final item in items) {
      buffer.writeln(item.productName);
      buffer.writeln('  ${item.quantity} x ${_currencyFormat.format(item.unitPrice)} = ${_currencyFormat.format(item.total)}');
    }

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Subtotal: ${_currencyFormat.format(order.subtotal)}');
    if (order.taxAmount > 0) {
      buffer.writeln('Tax: ${_currencyFormat.format(order.taxAmount)}');
    }
    if (order.discountAmount > 0) {
      buffer.writeln('Discount: -${_currencyFormat.format(order.discountAmount)}');
    }
    buffer.writeln('*TOTAL: ${_currencyFormat.format(order.totalAmount)}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('Payment: ${order.paymentMethodDisplayName}');
    if (order.paidAmount > 0) {
      buffer.writeln('Paid: ${_currencyFormat.format(order.paidAmount)}');
    }
    if (order.changeAmount > 0) {
      buffer.writeln('Change: ${_currencyFormat.format(order.changeAmount)}');
    }
    buffer.writeln();
    buffer.writeln(settings.thankYouMessage ?? 'Thank you for your purchase!');

    return buffer.toString();
  }

  /// Send WhatsApp message
  Future<bool> _sendWhatsAppMessage(String phoneNumber, String message) async {
    // Clean phone number - remove spaces, dashes, and ensure it has country code
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Add India country code if not present
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+91${cleanPhone.substring(1)}';
      } else if (!cleanPhone.startsWith('91')) {
        cleanPhone = '+91$cleanPhone';
      } else {
        cleanPhone = '+$cleanPhone';
      }
    }

    // Encode the message
    final encodedMessage = Uri.encodeComponent(message);
    
    // Create WhatsApp URL
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Open WhatsApp chat with a phone number (without message)
  Future<bool> openChat(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+91${cleanPhone.substring(1)}';
      } else if (!cleanPhone.startsWith('91')) {
        cleanPhone = '+91$cleanPhone';
      } else {
        cleanPhone = '+$cleanPhone';
      }
    }

    final url = Uri.parse('https://wa.me/$cleanPhone');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Make a phone call
  Future<bool> makeCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send SMS
  Future<bool> sendSMS(String phoneNumber, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('sms:$phoneNumber?body=$encodedMessage');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
