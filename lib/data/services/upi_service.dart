
/// UPI Payment Service for generating UPI payment links and QR codes
class UPIService {
  static const String _upiScheme = 'upi://pay';
  
  /// Generate UPI payment URI
  /// 
  /// [upiId] - UPI ID (e.g., shop@upi)
  /// [payeeName] - Name of the payee
  /// [amount] - Payment amount
  /// [transactionNote] - Transaction note/description
  /// [transactionRef] - Unique transaction reference
  /// [merchantCode] - Optional merchant code
  static String generatePaymentUri({
    required String upiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
    String? transactionRef,
    String? merchantCode,
  }) {
    final params = <String, String>{
      'pa': upiId,                    // Payee UPI ID
      'pn': payeeName,                // Payee Name
      'am': amount.toStringAsFixed(2), // Amount
      'cu': 'INR',                    // Currency
    };

    if (transactionNote != null && transactionNote.isNotEmpty) {
      params['tn'] = transactionNote;  // Transaction Note
    }
    
    if (transactionRef != null && transactionRef.isNotEmpty) {
      params['tr'] = transactionRef;   // Transaction Reference
    }
    
    if (merchantCode != null && merchantCode.isNotEmpty) {
      params['mc'] = merchantCode;     // Merchant Code
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$_upiScheme?$queryString';
  }

  /// Generate QR code data for UPI payment
  /// This returns the same URI that can be encoded into a QR code
  static String generateQRData({
    required String upiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
    String? transactionRef,
  }) {
    return generatePaymentUri(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
      transactionRef: transactionRef,
    );
  }

  /// Supported UPI apps - for deep linking
  static const List<UPIApp> supportedApps = [
    UPIApp(
      name: 'Google Pay',
      packageName: 'com.google.android.apps.nbu.paisa.user',
      icon: '📱',
    ),
    UPIApp(
      name: 'PhonePe',
      packageName: 'com.phonepe.app',
      icon: '💜',
    ),
    UPIApp(
      name: 'Paytm',
      packageName: 'net.one97.paytm',
      icon: '💙',
    ),
    UPIApp(
      name: 'BHIM',
      packageName: 'in.org.npci.upiapp',
      icon: '🇮🇳',
    ),
    UPIApp(
      name: 'Amazon Pay',
      packageName: 'in.amazon.mShop.android.shopping',
      icon: '🛒',
    ),
  ];

  /// Parse UPI response
  /// Returns transaction status from UPI callback
  static UPIResponse parseResponse(String response) {
    try {
      final params = Uri.splitQueryString(response);
      return UPIResponse(
        status: params['Status'] ?? params['status'] ?? 'FAILURE',
        transactionId: params['txnId'] ?? params['txnid'],
        responseCode: params['responseCode'],
        approvalRefNo: params['ApprovalRefNo'],
      );
    } catch (e) {
      return UPIResponse(status: 'FAILURE', errorMessage: e.toString());
    }
  }
}

/// UPI App info
class UPIApp {
  final String name;
  final String packageName;
  final String icon;

  const UPIApp({
    required this.name,
    required this.packageName,
    required this.icon,
  });
}

/// UPI Response after payment
class UPIResponse {
  final String status;
  final String? transactionId;
  final String? responseCode;
  final String? approvalRefNo;
  final String? errorMessage;

  UPIResponse({
    required this.status,
    this.transactionId,
    this.responseCode,
    this.approvalRefNo,
    this.errorMessage,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
  bool get isPending => status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'SUBMITTED';
  bool get isFailed => !isSuccess && !isPending;
}

/// UPI Payment Details for orders
class UPIPaymentDetails {
  final String upiId;
  final String payeeName;
  final double amount;
  final String? transactionRef;
  final String? upiTransactionId;
  final String paymentUri;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String status;

  UPIPaymentDetails({
    required this.upiId,
    required this.payeeName,
    required this.amount,
    this.transactionRef,
    this.upiTransactionId,
    required this.paymentUri,
    required this.createdAt,
    this.completedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'upi_id': upiId,
      'payee_name': payeeName,
      'amount': amount,
      'transaction_ref': transactionRef,
      'upi_transaction_id': upiTransactionId,
      'payment_uri': paymentUri,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status,
    };
  }

  factory UPIPaymentDetails.fromJson(Map<String, dynamic> json) {
    return UPIPaymentDetails(
      upiId: json['upi_id'] as String,
      payeeName: json['payee_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionRef: json['transaction_ref'] as String?,
      upiTransactionId: json['upi_transaction_id'] as String?,
      paymentUri: json['payment_uri'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      status: json['status'] as String? ?? 'pending',
    );
  }
}
