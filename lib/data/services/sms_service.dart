import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/business_settings.dart';

/// SMS sending method
enum SmsMethod {
  sim,    // Opens SMS app with pre-filled message (user taps send)
  cloud,  // SMS via Cloud API (fully automatic)
}

/// SMS provider for cloud sending
enum SmsProvider {
  msg91,
  fast2sms,
  twilio,
}

/// SMS Settings model
class SmsSettings {
  final bool enabled;
  final SmsMethod method;
  final SmsProvider provider;
  final String? apiKey;
  final String? senderId;
  final String? templateId;
  final String template;

  const SmsSettings({
    this.enabled = false,
    this.method = SmsMethod.sim,
    this.provider = SmsProvider.msg91,
    this.apiKey,
    this.senderId,
    this.templateId,
    this.template = defaultTemplate,
  });

  static const String defaultTemplate = 
    'Thank you for shopping at {business_name}! '
    'Bill #{order_id}, Amount: Rs.{total}. '
    '{thank_you_message}';

  SmsSettings copyWith({
    bool? enabled,
    SmsMethod? method,
    SmsProvider? provider,
    String? apiKey,
    String? senderId,
    String? templateId,
    String? template,
  }) {
    return SmsSettings(
      enabled: enabled ?? this.enabled,
      method: method ?? this.method,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      senderId: senderId ?? this.senderId,
      templateId: templateId ?? this.templateId,
      template: template ?? this.template,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'method': method.name,
    'provider': provider.name,
    'api_key': apiKey,
    'sender_id': senderId,
    'template_id': templateId,
    'template': template,
  };

  factory SmsSettings.fromMap(Map<String, dynamic> map) {
    return SmsSettings(
      enabled: map['enabled'] as bool? ?? false,
      method: SmsMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => SmsMethod.sim,
      ),
      provider: SmsProvider.values.firstWhere(
        (e) => e.name == map['provider'],
        orElse: () => SmsProvider.msg91,
      ),
      apiKey: map['api_key'] as String?,
      senderId: map['sender_id'] as String?,
      templateId: map['template_id'] as String?,
      template: map['template'] as String? ?? defaultTemplate,
    );
  }
}

/// Result of SMS sending attempt
class SmsResult {
  final bool success;
  final String? messageId;
  final String? error;

  const SmsResult({
    required this.success,
    this.messageId,
    this.error,
  });

  factory SmsResult.sent([String? messageId]) => SmsResult(
    success: true,
    messageId: messageId,
  );

  factory SmsResult.failed(String error) => SmsResult(
    success: false,
    error: error,
  );
}

/// SMS Service for sending bill notifications
class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  /// Send bill SMS to customer
  Future<SmsResult> sendBillSms({
    required Order order,
    required String customerPhone,
    required BusinessSettings businessSettings,
    required SmsSettings smsSettings,
    String? customerName,
  }) async {
    if (!smsSettings.enabled) {
      return SmsResult.failed('SMS not enabled');
    }

    if (customerPhone.isEmpty) {
      return SmsResult.failed('No phone number provided');
    }

    // Generate message from template
    final message = _generateMessage(
      template: smsSettings.template,
      order: order,
      businessSettings: businessSettings,
      customerName: customerName,
    );

    // Clean phone number
    final cleanPhone = _cleanPhoneNumber(customerPhone);

    try {
      switch (smsSettings.method) {
        case SmsMethod.sim:
          return await _sendViaSim(cleanPhone, message);
        case SmsMethod.cloud:
          return await _sendViaCloud(
            phone: cleanPhone,
            message: message,
            settings: smsSettings,
          );
      }
    } catch (e) {
      debugPrint('SMS Error: $e');
      return SmsResult.failed(e.toString());
    }
  }

  /// Send SMS via device SMS app (opens SMS app with pre-filled message)
  Future<SmsResult> _sendViaSim(String phone, String message) async {
    if (kIsWeb) {
      return SmsResult.failed('SIM SMS not available on web');
    }

    try {
      // Use sms: URI scheme to open SMS app with pre-filled message
      final encodedMessage = Uri.encodeComponent(message);
      final smsUri = Uri.parse('sms:$phone?body=$encodedMessage');
      
      final canLaunch = await canLaunchUrl(smsUri);
      if (canLaunch) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        return SmsResult.sent('opened');
      } else {
        return SmsResult.failed('Cannot open SMS app');
      }
    } catch (e) {
      return SmsResult.failed('SMS Error: $e');
    }
  }

  /// Send SMS via Cloud API (fully automatic, no user action needed)
  Future<SmsResult> _sendViaCloud({
    required String phone,
    required String message,
    required SmsSettings settings,
  }) async {
    if (settings.apiKey == null || settings.apiKey!.isEmpty) {
      return SmsResult.failed('API key not configured');
    }

    switch (settings.provider) {
      case SmsProvider.msg91:
        return await _sendViaMSG91(phone, message, settings);
      case SmsProvider.fast2sms:
        return await _sendViaFast2SMS(phone, message, settings);
      case SmsProvider.twilio:
        return await _sendViaTwilio(phone, message, settings);
    }
  }

  /// Send via MSG91 API
  Future<SmsResult> _sendViaMSG91(String phone, String message, SmsSettings settings) async {
    try {
      final url = Uri.parse('https://api.msg91.com/api/v5/flow/');
      
      final body = {
        'template_id': settings.templateId,
        'short_url': '0',
        'mobiles': phone,
        'VAR1': message,
      };

      final response = await http.post(
        url,
        headers: {
          'authkey': settings.apiKey!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SmsResult.sent(data['request_id']?.toString());
      } else {
        return SmsResult.failed('MSG91 Error: ${response.body}');
      }
    } catch (e) {
      return SmsResult.failed('MSG91 Error: $e');
    }
  }

  /// Send via Fast2SMS API
  Future<SmsResult> _sendViaFast2SMS(String phone, String message, SmsSettings settings) async {
    try {
      final url = Uri.parse('https://www.fast2sms.com/dev/bulkV2');
      
      final response = await http.post(
        url,
        headers: {
          'authorization': settings.apiKey!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'route': 'q',
          'message': message,
          'flash': 0,
          'numbers': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['return'] == true) {
          return SmsResult.sent(data['request_id']?.toString());
        } else {
          return SmsResult.failed(data['message'] ?? 'Fast2SMS Error');
        }
      } else {
        return SmsResult.failed('Fast2SMS Error: ${response.body}');
      }
    } catch (e) {
      return SmsResult.failed('Fast2SMS Error: $e');
    }
  }

  /// Send via Twilio API
  Future<SmsResult> _sendViaTwilio(String phone, String message, SmsSettings settings) async {
    final credentials = settings.apiKey!.split(':');
    if (credentials.length != 2) {
      return SmsResult.failed('Invalid Twilio credentials. Use format: ACCOUNT_SID:AUTH_TOKEN');
    }

    try {
      final accountSid = credentials[0];
      final authToken = credentials[1];
      
      final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'
      );
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': '+$phone',
          'From': settings.senderId ?? '',
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SmsResult.sent(data['sid']?.toString());
      } else {
        return SmsResult.failed('Twilio Error: ${response.body}');
      }
    } catch (e) {
      return SmsResult.failed('Twilio Error: $e');
    }
  }

  /// Generate SMS message from template
  String _generateMessage({
    required String template,
    required Order order,
    required BusinessSettings businessSettings,
    String? customerName,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yy');

    return template
      .replaceAll('{business_name}', businessSettings.businessName)
      .replaceAll('{order_id}', order.orderNumber)
      .replaceAll('{total}', currencyFormat.format(order.totalAmount).replaceAll('Rs.', ''))
      .replaceAll('{date}', dateFormat.format(order.createdAt))
      .replaceAll('{customer_name}', customerName ?? 'Customer')
      .replaceAll('{thank_you_message}', businessSettings.thankYouMessage ?? 'Thank you!');
  }

  /// Clean and format phone number
  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    
    return cleaned;
  }

  /// Send test SMS
  Future<SmsResult> sendTestSms({
    required String phone,
    required SmsSettings smsSettings,
    required BusinessSettings businessSettings,
  }) async {
    final testOrder = Order(
      orderNumber: 'TEST001',
      employeeId: 'test-employee',
      employeeName: 'Test Employee',
      items: [],
      subtotal: 100,
      taxAmount: 5,
      discountAmount: 0,
      totalAmount: 105,
      paidAmount: 105,
      paymentMethod: PaymentMethod.cash,
      status: OrderStatus.completed,
    );

    return await sendBillSms(
      order: testOrder,
      customerPhone: phone,
      businessSettings: businessSettings,
      smsSettings: smsSettings,
      customerName: 'Test Customer',
    );
  }
}
