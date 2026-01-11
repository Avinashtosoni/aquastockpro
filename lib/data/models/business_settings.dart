class BusinessSettings {
  final String id;
  final String businessName;
  final String? tagline;
  final String? logoUrl;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? gstin;
  final String currencySymbol;
  final String currencyCode;
  final double taxRate;
  final String? taxLabel;
  final String? receiptHeader;
  final String? receiptFooter;
  final String? thankYouMessage;
  final bool showLogo;
  final bool showTaxBreakdown;
  final bool enableLoyaltyPoints;
  final double loyaltyPointsPerAmount;
  // SMS Settings
  final bool smsEnabled;
  final String smsMethod; // 'sim' or 'cloud'
  final String smsProvider; // 'msg91', 'fast2sms', 'twilio'
  final String? smsApiKey;
  final String? smsSenderId;
  final String? smsTemplateId;
  final String smsTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const String defaultSmsTemplate = 
    'Thank you for shopping at {business_name}! '
    'Bill #{order_id}, Amount: Rs.{total}. '
    '{thank_you_message}';

  BusinessSettings({
    this.id = 'default',
    this.businessName = 'AquaStock Pro',
    this.tagline,
    this.logoUrl,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.gstin,
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.taxRate = 5.0,
    this.taxLabel = 'GST',
    this.receiptHeader,
    this.receiptFooter,
    this.thankYouMessage = 'Thank you for shopping with us!',
    this.showLogo = true,
    this.showTaxBreakdown = true,
    this.enableLoyaltyPoints = false,
    this.loyaltyPointsPerAmount = 100,
    // SMS Settings
    this.smsEnabled = false,
    this.smsMethod = 'sim',
    this.smsProvider = 'msg91',
    this.smsApiKey,
    this.smsSenderId,
    this.smsTemplateId,
    this.smsTemplate = defaultSmsTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  BusinessSettings copyWith({
    String? id,
    String? businessName,
    String? tagline,
    String? logoUrl,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? gstin,
    String? currencySymbol,
    String? currencyCode,
    double? taxRate,
    String? taxLabel,
    String? receiptHeader,
    String? receiptFooter,
    String? thankYouMessage,
    bool? showLogo,
    bool? showTaxBreakdown,
    bool? enableLoyaltyPoints,
    double? loyaltyPointsPerAmount,
    bool? smsEnabled,
    String? smsMethod,
    String? smsProvider,
    String? smsApiKey,
    String? smsSenderId,
    String? smsTemplateId,
    String? smsTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessSettings(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      tagline: tagline ?? this.tagline,
      logoUrl: logoUrl ?? this.logoUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      gstin: gstin ?? this.gstin,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      taxRate: taxRate ?? this.taxRate,
      taxLabel: taxLabel ?? this.taxLabel,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      showLogo: showLogo ?? this.showLogo,
      showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
      enableLoyaltyPoints: enableLoyaltyPoints ?? this.enableLoyaltyPoints,
      loyaltyPointsPerAmount: loyaltyPointsPerAmount ?? this.loyaltyPointsPerAmount,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      smsMethod: smsMethod ?? this.smsMethod,
      smsProvider: smsProvider ?? this.smsProvider,
      smsApiKey: smsApiKey ?? this.smsApiKey,
      smsSenderId: smsSenderId ?? this.smsSenderId,
      smsTemplateId: smsTemplateId ?? this.smsTemplateId,
      smsTemplate: smsTemplate ?? this.smsTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_name': businessName,
      'tagline': tagline,
      'logo_url': logoUrl,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'gstin': gstin,
      'currency_symbol': currencySymbol,
      'currency_code': currencyCode,
      'tax_rate': taxRate,
      'tax_label': taxLabel,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'thank_you_message': thankYouMessage,
      'show_logo': showLogo,
      'show_tax_breakdown': showTaxBreakdown,
      'enable_loyalty_points': enableLoyaltyPoints,
      'loyalty_points_per_amount': loyaltyPointsPerAmount,
      'sms_enabled': smsEnabled,
      'sms_method': smsMethod,
      'sms_provider': smsProvider,
      'sms_api_key': smsApiKey,
      'sms_sender_id': smsSenderId,
      'sms_template_id': smsTemplateId,
      'sms_template': smsTemplate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      id: map['id'] as String? ?? 'default',
      businessName: map['business_name'] as String? ?? 'AquaStock Pro',
      tagline: map['tagline'] as String?,
      logoUrl: map['logo_url'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      postalCode: map['postal_code'] as String?,
      gstin: map['gstin'] as String?,
      currencySymbol: map['currency_symbol'] as String? ?? '₹',
      currencyCode: map['currency_code'] as String? ?? 'INR',
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 5.0,
      taxLabel: map['tax_label'] as String? ?? 'GST',
      receiptHeader: map['receipt_header'] as String?,
      receiptFooter: map['receipt_footer'] as String?,
      thankYouMessage: map['thank_you_message'] as String?,
      showLogo: map['show_logo'] == 1 || map['show_logo'] == true,
      showTaxBreakdown: map['show_tax_breakdown'] == 1 || map['show_tax_breakdown'] == true,
      enableLoyaltyPoints: map['enable_loyalty_points'] == 1 || map['enable_loyalty_points'] == true,
      loyaltyPointsPerAmount: (map['loyalty_points_per_amount'] as num?)?.toDouble() ?? 100,
      smsEnabled: map['sms_enabled'] == 1 || map['sms_enabled'] == true,
      smsMethod: map['sms_method'] as String? ?? 'sim',
      smsProvider: map['sms_provider'] as String? ?? 'msg91',
      smsApiKey: map['sms_api_key'] as String?,
      smsSenderId: map['sms_sender_id'] as String?,
      smsTemplateId: map['sms_template_id'] as String?,
      smsTemplate: map['sms_template'] as String? ?? defaultSmsTemplate,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }
}
