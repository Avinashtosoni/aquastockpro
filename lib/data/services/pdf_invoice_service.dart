import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/business_settings.dart';
import '../models/customer.dart';
import '../models/refund_item.dart';

/// Service for generating PDF receipts and invoices
class PdfInvoiceService {
  static final PdfInvoiceService _instance = PdfInvoiceService._internal();
  factory PdfInvoiceService() => _instance;
  PdfInvoiceService._internal();

  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  
  // Use Rs. instead of ₹ to avoid font issues
  String _formatCurrency(double amount) {
    return 'Rs.${amount.toStringAsFixed(2)}';
  }

  /// Build QR code data with comprehensive order details
  String _buildQRData(Order order, BusinessSettings settings) {
    // Shop info
    final shop = settings.businessName;
    
    // Customer info
    final customer = order.customerName ?? 'Walk-in';
    
    // Items summary (product names with qty)
    final itemsSummary = order.items.map((item) => '${item.productName}x${item.quantity}').take(5).join(',');
    final moreItems = order.items.length > 5 ? '+${order.items.length - 5}more' : '';
    
    // Build QR data string
    return [
      'SHOP:$shop',
      'INV:${order.orderNumber}',
      'DT:${DateFormat('dd/MM/yy HH:mm').format(order.createdAt)}',
      'CUST:$customer',
      'ITEMS:$itemsSummary$moreItems',
      'TOTAL:${order.totalAmount.toStringAsFixed(0)}',
      'PAID:${order.paidAmount.toStringAsFixed(0)}',
      'DUE:${(order.totalAmount - order.paidAmount).toStringAsFixed(0)}',
      'MODE:${order.paymentMethodDisplayName}',
    ].join('|');
  }

  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;

    try {
      _regularFont = await PdfGoogleFonts.notoSansRegular();
      _boldFont = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      debugPrint('Failed to load Google Fonts: $e');
      // Fallback to standard fonts if internet is unavailable
      _regularFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
    }
  }

  /// Load logo from network URL and convert to PDF image
  Future<pw.ImageProvider?> _loadLogo(String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Failed to load logo: $e');
    }
    return null;
  }

  /// Generate receipt PDF (thermal printer size)
  Future<Uint8List> generateReceiptPdf({
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
    double previousBalance = 0, // Customer's previous outstanding
  }) async {
    await _loadFonts();
    final pdf = pw.Document();
    
    // Load logo if enabled
    pw.ImageProvider? logoImage;
    if (settings.showLogo && settings.logoUrl != null) {
      logoImage = await _loadLogo(settings.logoUrl);
    }
    
    // 80mm width thermal receipt
    const receiptWidth = 80 * PdfPageFormat.mm;
    
    final baseStyle = pw.TextStyle(font: _regularFont, fontSize: 9);
    final boldStyle = pw.TextStyle(font: _boldFont, fontSize: 9);
    final titleStyle = pw.TextStyle(font: _boldFont, fontSize: 14);
    final smallStyle = pw.TextStyle(font: _regularFont, fontSize: 8);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(receiptWidth, double.infinity),
        margin: const pw.EdgeInsets.all(10),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Logo
            if (logoImage != null)
              pw.Container(
                height: 50,
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            // Header
            pw.Text(
              settings.businessName.toUpperCase(),
              style: titleStyle,
            ),
            if (settings.tagline != null)
              pw.Text(settings.tagline!, style: smallStyle),
            pw.SizedBox(height: 4),
            if (settings.fullAddress.isNotEmpty)
              pw.Text(settings.fullAddress, 
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),
            if (settings.phone != null)
              pw.Text('Tel: ${settings.phone}', style: smallStyle),
            if (settings.gstin != null)
              pw.Text('GSTIN: ${settings.gstin}', style: smallStyle),
            
            pw.Divider(thickness: 0.5),
            
            // Receipt header
            if (settings.receiptHeader != null && settings.receiptHeader!.isNotEmpty)
              pw.Text(settings.receiptHeader!, 
                style: baseStyle,
                textAlign: pw.TextAlign.center,
              ),
            
            pw.SizedBox(height: 6),
            
            // Order info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Receipt #:', style: smallStyle),
                pw.Text(order.orderNumber, style: boldStyle),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date:', style: smallStyle),
                pw.Text(_dateFormat.format(order.createdAt), style: smallStyle),
              ],
            ),
            if (order.customerName != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer:', style: smallStyle),
                  pw.Text(order.customerName!, style: smallStyle),
                ],
              ),
            
            pw.Divider(thickness: 0.5),
            
            // Items header with GST column
            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Item', style: boldStyle)),
                pw.Expanded(child: pw.Text('Qty', style: boldStyle, textAlign: pw.TextAlign.center)),
                pw.Expanded(child: pw.Text('GST%', style: boldStyle, textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 2, child: pw.Text('Price', style: boldStyle, textAlign: pw.TextAlign.right)),
              ],
            ),
            pw.Divider(thickness: 0.3),
            
            // Items with GST% column
            ...items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text(item.productName, style: baseStyle)),
                  pw.Expanded(child: pw.Text('${item.quantity}', style: baseStyle, textAlign: pw.TextAlign.center)),
                  pw.Expanded(child: pw.Text('${item.taxRate.toStringAsFixed(0)}%', style: baseStyle, textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text(_formatCurrency(item.total), style: baseStyle, textAlign: pw.TextAlign.right)),
                ],
              ),
            )),
            
            pw.Divider(thickness: 0.5),
            
            // Totals with CGST/SGST breakdown
            _buildTotalRow('Subtotal', order.subtotal, baseStyle),
            if (order.discountAmount > 0)
              _buildTotalRow('Discount', -order.discountAmount, baseStyle),
            // GST breakdown - CGST and SGST (half each for intrastate)
            if (order.taxAmount > 0) ...[
              _buildTotalRow('CGST', order.taxAmount / 2, baseStyle),
              _buildTotalRow('SGST', order.taxAmount / 2, baseStyle),
            ],
            
            pw.Divider(thickness: 1),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(font: _boldFont, fontSize: 12)),
                pw.Text(_formatCurrency(order.totalAmount), style: pw.TextStyle(font: _boldFont, fontSize: 12)),
              ],
            ),
            
            pw.Divider(thickness: 0.5),
            
            // Previous Outstanding (if any)
            if (previousBalance > 0) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Previous Outstanding', style: pw.TextStyle(font: _boldFont, fontSize: 9)),
                    pw.Text(_formatCurrency(previousBalance), style: pw.TextStyle(font: _boldFont, fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
            ],
            
            pw.Divider(thickness: 0.5),
            
            // Payment Breakdown Section
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Payment Method:', style: smallStyle),
                      pw.Text(order.paymentMethodDisplayName, style: boldStyle),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Amount Paid:', style: boldStyle),
                      pw.Text(_formatCurrency(order.paidAmount), style: pw.TextStyle(font: _boldFont, fontSize: 10)),
                    ],
                  ),
                  // Balance Due (UDHAR) - if not fully paid
                  if (order.totalAmount > order.paidAmount) ...[
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        border: pw.Border.all(color: PdfColors.red),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('BALANCE DUE (UDHAR)', style: pw.TextStyle(font: _boldFont, fontSize: 9, color: PdfColors.red)),
                          pw.Text(_formatCurrency(order.totalAmount - order.paidAmount), style: pw.TextStyle(font: _boldFont, fontSize: 11, color: PdfColors.red)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('Added to customer credit ledger', style: pw.TextStyle(font: _regularFont, fontSize: 7, color: PdfColors.red)),
                  ],
                  // Total Outstanding (Previous + Current Due)
                  if (previousBalance > 0 || order.totalAmount > order.paidAmount) ...[
                    pw.SizedBox(height: 6),
                    pw.Divider(thickness: 0.5),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL OUTSTANDING', style: pw.TextStyle(font: _boldFont, fontSize: 10)),
                        pw.Text(_formatCurrency(previousBalance + (order.totalAmount - order.paidAmount)), 
                          style: pw.TextStyle(font: _boldFont, fontSize: 11, color: PdfColors.red)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            pw.SizedBox(height: 10),
            
            // QR Code with order details
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: _buildQRData(order, settings),
                      width: 60,
                      height: 60,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Scan for verification', style: pw.TextStyle(font: _regularFont, fontSize: 6)),
                  ],
                ),
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Footer
            if (settings.receiptFooter != null && settings.receiptFooter!.isNotEmpty)
              pw.Text(settings.receiptFooter!, 
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),
            pw.Text(settings.thankYouMessage ?? 'Thank you for shopping with us!', 
              style: baseStyle,
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 0.3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Printed: ${DateFormat('dd/MM/yy hh:mm a').format(DateTime.now())}', 
                  style: pw.TextStyle(font: _regularFont, fontSize: 7)),
                pw.Text('Powered by AquaStock Pro', style: pw.TextStyle(font: _regularFont, fontSize: 7)),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Generate A4 invoice PDF
  Future<Uint8List> generateInvoicePdf({
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
    Customer? customer,
    double previousBalance = 0,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();
    
    // Load logo if enabled
    pw.ImageProvider? logoImage;
    if (settings.showLogo && settings.logoUrl != null) {
      logoImage = await _loadLogo(settings.logoUrl);
    }
    
    final baseStyle = pw.TextStyle(font: _regularFont, fontSize: 10);
    final boldStyle = pw.TextStyle(font: _boldFont, fontSize: 10);
    final titleStyle = pw.TextStyle(font: _boldFont, fontSize: 28, color: PdfColor.fromHex('#1E3A5F'));
    final headerStyle = pw.TextStyle(font: _boldFont, fontSize: 10, color: PdfColors.white);
    final smallStyle = pw.TextStyle(font: _regularFont, fontSize: 9);
    final accentColor = PdfColor.fromHex('#1E3A5F');
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ============ HEADER WITH LOGO ============
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Company info with logo
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          height: 70,
                          width: 70,
                          margin: const pw.EdgeInsets.only(right: 15),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(settings.businessName.toUpperCase(), style: titleStyle),
                          if (settings.tagline != null)
                            pw.Text(settings.tagline!, style: smallStyle.copyWith(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                          pw.SizedBox(height: 6),
                          if (settings.fullAddress.isNotEmpty)
                            pw.Text(settings.fullAddress, style: smallStyle),
                          if (settings.phone != null)
                            pw.Text('Tel: ${settings.phone}', style: smallStyle),
                          if (settings.email != null)
                            pw.Text('Email: ${settings.email}', style: smallStyle),
                          if (settings.gstin != null)
                            pw.Container(
                              margin: const pw.EdgeInsets.only(top: 4),
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: accentColor,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text('GSTIN: ${settings.gstin}', style: pw.TextStyle(font: _boldFont, fontSize: 9, color: PdfColors.white)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // Invoice title & details
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text('TAX INVOICE', style: pw.TextStyle(font: _boldFont, fontSize: 18, color: PdfColors.white)),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Invoice #: ${order.orderNumber}', style: boldStyle),
                      pw.Text('Date: ${_dateFormat.format(order.createdAt)}', style: smallStyle),
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 4),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#22C55E'),
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(order.status.name.toUpperCase(), style: pw.TextStyle(font: _boldFont, fontSize: 8, color: PdfColors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // ============ BILL TO SECTION ============
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: accentColor, width: 1),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(color: accentColor),
                          child: pw.Text('BILL TO', style: pw.TextStyle(font: _boldFont, fontSize: 10, color: PdfColors.white)),
                        ),
                        pw.SizedBox(height: 8),
                        if (customer != null) ...[
                          pw.Text(customer.name, style: boldStyle.copyWith(fontSize: 13)),
                          if (customer.phone != null && customer.phone!.isNotEmpty)
                            pw.Text('Phone: ${customer.phone}', style: smallStyle),
                          if (customer.address != null && customer.address!.isNotEmpty)
                            pw.Text(customer.address!, style: smallStyle),
                          if (customer.gstin != null && customer.gstin!.isNotEmpty)
                            pw.Text('GSTIN: ${customer.gstin}', style: boldStyle),
                        ] else if (order.customerName != null) ...[
                          pw.Text(order.customerName!, style: boldStyle.copyWith(fontSize: 13)),
                        ] else ...[
                          pw.Text('Walk-in Customer', style: smallStyle),
                        ],
                      ],
                    ),
                  ),
                ),
                // Previous Outstanding (if any)
                if (previousBalance > 0) ...[
                  pw.SizedBox(width: 15),
                  pw.Container(
                    width: 180,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber50,
                      border: pw.Border.all(color: PdfColors.amber, width: 1),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('PREVIOUS OUTSTANDING', style: pw.TextStyle(font: _boldFont, fontSize: 9, color: PdfColors.amber900)),
                        pw.SizedBox(height: 6),
                        pw.Text(_formatCurrency(previousBalance), style: pw.TextStyle(font: _boldFont, fontSize: 16, color: PdfColors.amber900)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // ============ ITEMS TABLE WITH GST DETAILS ============
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),  // S.No
                1: const pw.FlexColumnWidth(3),    // Item Description
                2: const pw.FixedColumnWidth(50),  // HSN
                3: const pw.FixedColumnWidth(35),  // Qty
                4: const pw.FixedColumnWidth(65),  // Rate
                5: const pw.FixedColumnWidth(40),  // GST%
                6: const pw.FixedColumnWidth(65),  // Taxable
                7: const pw.FixedColumnWidth(50),  // CGST
                8: const pw.FixedColumnWidth(50),  // SGST
                9: const pw.FixedColumnWidth(70),  // Amount
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: accentColor),
                  children: [
                    _tableHeader('S.No', headerStyle),
                    _tableHeader('Item Description', headerStyle),
                    _tableHeader('HSN', headerStyle),
                    _tableHeader('Qty', headerStyle),
                    _tableHeader('Rate', headerStyle),
                    _tableHeader('GST%', headerStyle),
                    _tableHeader('Taxable', headerStyle),
                    _tableHeader('CGST', headerStyle),
                    _tableHeader('SGST', headerStyle),
                    _tableHeader('Amount', headerStyle),
                  ],
                ),
                // Item rows with GST details
                ...items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final taxableValue = item.subtotal - item.discount;
                  final itemCgst = taxableValue * (item.taxRate / 2 / 100);
                  final itemSgst = taxableValue * (item.taxRate / 2 / 100);
                  final totalWithTax = taxableValue + itemCgst + itemSgst;
                  
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: entry.key.isEven ? PdfColors.white : PdfColors.grey50,
                    ),
                    children: [
                      _tableCell('${entry.key + 1}', baseStyle),
                      _tableCell(item.productName, baseStyle, align: pw.TextAlign.left),
                      _tableCell('9999', baseStyle), // Default HSN code
                      _tableCell('${item.quantity}', baseStyle),
                      _tableCell(_formatCurrency(item.unitPrice), baseStyle),
                      _tableCell('${item.taxRate.toStringAsFixed(0)}%', baseStyle),
                      _tableCell(_formatCurrency(taxableValue), baseStyle),
                      _tableCell(_formatCurrency(itemCgst), baseStyle),
                      _tableCell(_formatCurrency(itemSgst), baseStyle),
                      _tableCell(_formatCurrency(totalWithTax), baseStyle),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            // ============ SUMMARY & PAYMENT SECTION ============
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Terms on left (optional)
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TERMS & CONDITIONS:', style: boldStyle.copyWith(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('1. Goods once sold will not be taken back.', style: pw.TextStyle(font: _regularFont, fontSize: 8)),
                        pw.Text('2. Payment due as per agreed terms.', style: pw.TextStyle(font: _regularFont, fontSize: 8)),
                        pw.Text('3. Subject to local jurisdiction.', style: pw.TextStyle(font: _regularFont, fontSize: 8)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
                // Summary on right with CGST/SGST breakdown
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', _formatCurrency(order.subtotal), baseStyle, boldStyle),
                      if (order.discountAmount > 0)
                        _summaryRow('Discount', '-${_formatCurrency(order.discountAmount)}', baseStyle, boldStyle, isDiscount: true),
                      // CGST and SGST breakdown (half each for intrastate)
                      if (order.taxAmount > 0) ...[
                        _summaryRow('CGST', _formatCurrency(order.taxAmount / 2), baseStyle, boldStyle),
                        _summaryRow('SGST', _formatCurrency(order.taxAmount / 2), baseStyle, boldStyle),
                      ],
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Divider(thickness: 1.5, color: accentColor),
                      ),
                      // TOTAL box
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GRAND TOTAL', style: pw.TextStyle(font: _boldFont, fontSize: 12, color: PdfColors.white)),
                            pw.Text(_formatCurrency(order.totalAmount), style: pw.TextStyle(font: _boldFont, fontSize: 14, color: PdfColors.white)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // Payment breakdown
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Payment Mode:', style: smallStyle),
                                pw.Text(order.paymentMethodDisplayName, style: boldStyle),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Amount Paid:', style: boldStyle),
                                pw.Text(_formatCurrency(order.paidAmount), style: pw.TextStyle(font: _boldFont, fontSize: 11, color: PdfColor.fromHex('#22C55E'))),
                              ],
                            ),
                            // Balance Due (UDHAR)
                            if (order.totalAmount > order.paidAmount) ...[
                              pw.SizedBox(height: 8),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(6),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.red50,
                                  border: pw.Border.all(color: PdfColors.red),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Column(
                                  children: [
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text('BALANCE DUE', style: pw.TextStyle(font: _boldFont, fontSize: 10, color: PdfColors.red)),
                                        pw.Text(_formatCurrency(order.totalAmount - order.paidAmount), style: pw.TextStyle(font: _boldFont, fontSize: 12, color: PdfColors.red)),
                                      ],
                                    ),
                                    pw.Text('(Added to Credit Ledger)', style: pw.TextStyle(font: _regularFont, fontSize: 7, color: PdfColors.red)),
                                  ],
                                ),
                              ),
                            ],
                            // Total Outstanding
                            if (previousBalance > 0 || order.totalAmount > order.paidAmount) ...[
                              pw.SizedBox(height: 8),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(6),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.red100,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('TOTAL OUTSTANDING', style: pw.TextStyle(font: _boldFont, fontSize: 10)),
                                    pw.Text(_formatCurrency(previousBalance + (order.totalAmount - order.paidAmount)), 
                                      style: pw.TextStyle(font: _boldFont, fontSize: 12, color: PdfColors.red900)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.Spacer(),
            
            // ============ SIGNATURE SECTION ============
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Customer signature
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Customer Signature', style: smallStyle),
                    ],
                  ),
                  
                  // QR Code for verification
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: _buildQRData(order, settings),
                          width: 70,
                          height: 70,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Scan for verification', style: pw.TextStyle(font: _regularFont, fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                  
                  // Authorized signature
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Authorized Signature', style: smallStyle),
                      pw.Text('For ${settings.businessName}', style: pw.TextStyle(font: _boldFont, fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
            
            // ============ FOOTER ============
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(settings.thankYouMessage ?? 'Thank you for your business!', style: smallStyle.copyWith(color: PdfColors.grey600)),
                pw.Text('Printed: ${_dateFormat.format(DateTime.now())}', style: pw.TextStyle(font: _regularFont, fontSize: 8, color: PdfColors.grey500)),
                pw.Text('Generated by AquaStock Pro', style: pw.TextStyle(font: _regularFont, fontSize: 8, color: PdfColors.grey400)),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // Helper widgets
  pw.Widget _buildTotalRow(String label, double amount, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(_formatCurrency(amount), style: style),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  pw.Widget _tableCell(String text, pw.TextStyle style, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  pw.Widget _summaryRow(String label, String value, pw.TextStyle baseStyle, pw.TextStyle boldStyle, {bool isBold = false, bool isLarge = false, bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: isLarge 
            ? boldStyle.copyWith(fontSize: 12) 
            : (isBold ? boldStyle : baseStyle)),
          pw.Text(value, style: isLarge 
            ? boldStyle.copyWith(fontSize: 14) 
            : (isBold ? boldStyle : baseStyle).copyWith(
                color: isDiscount ? PdfColor.fromHex('#22C55E') : null,
              )),
        ],
      ),
    );
  }

  /// Print receipt using system print dialog
  Future<void> printReceipt({
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
    double previousBalance = 0,
  }) async {
    final pdfData = await generateReceiptPdf(
      order: order,
      settings: settings,
      items: items,
      previousBalance: previousBalance,
    );
    
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }

  /// Print A4 invoice
  Future<void> printInvoice({
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
  }) async {
    final pdfData = await generateInvoicePdf(
      order: order,
      settings: settings,
      items: items,
    );
    
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }

  /// Save receipt as PDF file (cross-platform, works on Web too)
  Future<String?> saveReceiptPdf({
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
  }) async {
    try {
      final pdfData = await generateReceiptPdf(
        order: order,
        settings: settings,
        items: items,
      );
      
      final filename = 'receipt_${order.orderNumber}.pdf';
      
      // Use sharePdf which triggers download on web and share on mobile
      await Printing.sharePdf(bytes: pdfData, filename: filename);
      
      return filename;
    } catch (e) {
      rethrow;
    }
  }

  /// Save invoice as PDF file (cross-platform, works on Web too)
  Future<String?> saveInvoicePdf({
    required Order order,
    required BusinessSettings settings,
    required List<OrderItem> items,
    Customer? customer,
    double previousBalance = 0,
  }) async {
    try {
      final pdfData = await generateInvoicePdf(
        order: order,
        settings: settings,
        items: items,
        customer: customer,
        previousBalance: previousBalance,
      );
      
      final filename = 'invoice_${order.orderNumber}.pdf';
      
      // Use sharePdf which triggers download on web and share on mobile
      await Printing.sharePdf(bytes: pdfData, filename: filename);
      
      return filename;
    } catch (e) {
      rethrow; // Let the caller handle the error
    }
  }

  /// Generate Refund Receipt PDF with customer and balance details
  Future<Uint8List> generateRefundReceiptPdf({
    required Order order,
    required BusinessSettings settings,
    required List<RefundItem> refundItems, // Changed to RefundItem for accurate quantities
    required String refundNumber,
    required double refundAmount,
    required String reason,
    String? notes,
    Customer? customer, // Customer details
    double previousBalance = 0, // Customer's balance before refund
  }) async {
    await _loadFonts();
    final pdf = pw.Document();
    
    // Load logo if enabled
    pw.ImageProvider? logoImage;
    if (settings.showLogo && settings.logoUrl != null) {
      logoImage = await _loadLogo(settings.logoUrl);
    }
    
    final baseStyle = pw.TextStyle(font: _regularFont, fontSize: 10);
    final boldStyle = pw.TextStyle(font: _boldFont, fontSize: 10);
    final headerStyle = pw.TextStyle(font: _boldFont, fontSize: 10, color: PdfColors.white);
    final smallStyle = pw.TextStyle(font: _regularFont, fontSize: 9);
    
    final accentColor = PdfColor.fromHex('#F59E0B'); // Orange for refund
    final newBalance = previousBalance - refundAmount; // Balance after refund credit
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ============ HEADER ============
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 60,
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    pw.Text(settings.businessName.toUpperCase(), style: pw.TextStyle(font: _boldFont, fontSize: 20, color: PdfColor.fromHex('#1E3A5F'))),
                    if (settings.tagline != null)
                      pw.Text(settings.tagline!, style: smallStyle.copyWith(color: PdfColors.grey700)),
                    pw.SizedBox(height: 6),
                    if (settings.fullAddress.isNotEmpty)
                      pw.Text(settings.fullAddress, style: smallStyle),
                    if (settings.phone != null)
                      pw.Text('Phone: ${settings.phone}', style: smallStyle),
                    if (settings.gstin != null)
                      pw.Text('GSTIN: ${settings.gstin}', style: boldStyle),
                  ],
                ),
                // Refund title & info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('REFUND RECEIPT', style: pw.TextStyle(font: _boldFont, fontSize: 16, color: PdfColors.white)),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Refund #: $refundNumber', style: boldStyle.copyWith(fontSize: 11)),
                    pw.Text('Date: ${_dateFormat.format(DateTime.now())}', style: smallStyle),
                    pw.SizedBox(height: 6),
                    pw.Text('Original Order: ${order.orderNumber}', style: smallStyle),
                    pw.Text('Order Date: ${_dateFormat.format(order.createdAt)}', style: smallStyle),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // ============ CUSTOMER & BALANCE INFO ============
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer details
                if (customer != null)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColor.fromHex('#1E3A5F'), width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#1E3A5F'),
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text('CUSTOMER', style: pw.TextStyle(font: _boldFont, fontSize: 8, color: PdfColors.white)),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(customer.name, style: boldStyle.copyWith(fontSize: 12)),
                          if (customer.phone != null)
                            pw.Text('Phone: ${customer.phone}', style: smallStyle),
                          if (customer.address != null)
                            pw.Text(customer.address!, style: smallStyle),
                        ],
                      ),
                    ),
                  ),
                pw.SizedBox(width: 15),
                // Balance info
                pw.Container(
                  width: 180,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: accentColor.shade(0.1),
                    border: pw.Border.all(color: accentColor, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('REFUND AMOUNT', style: pw.TextStyle(font: _boldFont, fontSize: 9, color: PdfColors.amber900)),
                      pw.SizedBox(height: 4),
                      pw.Text(_formatCurrency(refundAmount), style: pw.TextStyle(font: _boldFont, fontSize: 18, color: PdfColors.amber900)),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            // ============ REFUND REASON ============
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('REFUND REASON: $reason', style: boldStyle.copyWith(color: PdfColors.amber900)),
                  if (notes != null && notes.isNotEmpty)
                    pw.Text('Notes: $notes', style: smallStyle.copyWith(color: PdfColors.grey700)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 15),
            
            // ============ REFUNDED ITEMS TABLE ============
            pw.Text('REFUNDED ITEMS', style: boldStyle.copyWith(fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FixedColumnWidth(55),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: accentColor),
                  children: [
                    _tableHeader('#', headerStyle),
                    _tableHeader('Product Name', headerStyle),
                    _tableHeader('Qty', headerStyle),
                    _tableHeader('Unit Price', headerStyle),
                    _tableHeader('Refund', headerStyle),
                  ],
                ),
                ...refundItems.asMap().entries.map((entry) => pw.TableRow(
                  decoration: pw.BoxDecoration(color: entry.key.isEven ? PdfColors.white : PdfColors.grey50),
                  children: [
                    _tableCell('${entry.key + 1}', baseStyle),
                    _tableCell(entry.value.productName, baseStyle, align: pw.TextAlign.left),
                    _tableCell('${entry.value.quantity}', baseStyle), // Actual refunded qty
                    _tableCell(_formatCurrency(entry.value.unitPrice), baseStyle),
                    _tableCell(_formatCurrency(entry.value.totalAmount), baseStyle), // Actual refund amount
                  ],
                )),
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            // ============ SUMMARY & BALANCE ADJUSTMENT ============
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      _summaryRow('Items Refunded', '${refundItems.length} item(s)', baseStyle, boldStyle),
                      pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                      _summaryRow('Total Refund', _formatCurrency(refundAmount), baseStyle, boldStyle, isBold: true),
                      
                      // Balance adjustment section
                      if (customer != null) ...[
                        pw.SizedBox(height: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green50,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: PdfColors.green),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Previous Dues', style: smallStyle),
                                  pw.Text(_formatCurrency(previousBalance), style: baseStyle),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Refund Credit', style: smallStyle.copyWith(color: PdfColors.green800)),
                                  pw.Text('- ${_formatCurrency(refundAmount)}', style: baseStyle.copyWith(color: PdfColors.green800)),
                                ],
                              ),
                              pw.Divider(thickness: 1, color: PdfColors.green),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('NEW BALANCE', style: boldStyle),
                                  pw.Text(
                                    newBalance <= 0 ? 'CLEAR' : _formatCurrency(newBalance),
                                    style: boldStyle.copyWith(color: newBalance <= 0 ? PdfColors.green800 : PdfColors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            pw.Spacer(),
            
            // ============ SIGNATURES ============
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 15),
              decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 35, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)))),
                      pw.SizedBox(height: 4),
                      pw.Text('Customer Signature', style: smallStyle),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'REF:$refundNumber|ORD:${order.orderNumber}|AMT:${refundAmount.toStringAsFixed(2)}',
                    width: 55,
                    height: 55,
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 35, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)))),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signature', style: smallStyle),
                      pw.Text('For ${settings.businessName}', style: pw.TextStyle(font: _boldFont, fontSize: 7)),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('This is a refund receipt for your records.', style: smallStyle.copyWith(color: PdfColors.grey600)),
                pw.Text('Generated by AquaStock Pro', style: pw.TextStyle(font: _regularFont, fontSize: 7, color: PdfColors.grey400)),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Save refund receipt as PDF file
  Future<String?> saveRefundReceiptPdf({
    required Order order,
    required BusinessSettings settings,
    required List<RefundItem> refundItems, // Changed to RefundItem
    required String refundNumber,
    required double refundAmount,
    required String reason,
    String? notes,
    Customer? customer,
    double previousBalance = 0,
  }) async {
    try {
      final pdfData = await generateRefundReceiptPdf(
        order: order,
        settings: settings,
        refundItems: refundItems,
        refundNumber: refundNumber,
        refundAmount: refundAmount,
        reason: reason,
        notes: notes,
        customer: customer,
        previousBalance: previousBalance,
      );
      
      final filename = 'refund_$refundNumber.pdf';
      await Printing.sharePdf(bytes: pdfData, filename: filename);
      return filename;
    } catch (e) {
      rethrow;
    }
  }

  /// Share PDF via system share
  Future<void> sharePdf(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(bytes: pdfData, filename: filename);
  }

  /// Generate A4 quotation PDF
  Future<Uint8List> generateQuotationPdf({
    required Quotation quotation,
    required BusinessSettings settings,
    required List<QuotationItem> items,
    Customer? customer, // Optional full customer details for BILL TO section
  }) async {
    await _loadFonts();
    final pdf = pw.Document();
    
    // Load logo if enabled
    pw.ImageProvider? logoImage;
    if (settings.showLogo && settings.logoUrl != null) {
      logoImage = await _loadLogo(settings.logoUrl);
    }
    
    final baseStyle = pw.TextStyle(font: _regularFont, fontSize: 10);
    final boldStyle = pw.TextStyle(font: _boldFont, fontSize: 10);
    final titleStyle = pw.TextStyle(font: _boldFont, fontSize: 24, color: PdfColor.fromHex('#1E3A5F'));
    final headerStyle = pw.TextStyle(font: _boldFont, fontSize: 10, color: PdfColors.white);
    final smallStyle = pw.TextStyle(font: _regularFont, fontSize: 9);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with company info and logo
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company info with logo
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo
                    if (logoImage != null)
                      pw.Container(
                        height: 60,
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    pw.Text(settings.businessName.toUpperCase(), style: titleStyle),
                    if (settings.tagline != null)
                      pw.Text(settings.tagline!, style: smallStyle.copyWith(color: PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    if (settings.fullAddress.isNotEmpty)
                      pw.Text(settings.fullAddress, style: smallStyle),
                    if (settings.phone != null)
                      pw.Text('Phone: ${settings.phone}', style: smallStyle),
                    if (settings.email != null)
                      pw.Text('Email: ${settings.email}', style: smallStyle),
                    if (settings.gstin != null)
                      pw.Text('GSTIN: ${settings.gstin}', style: boldStyle),
                  ],
                ),
                // Quotation title
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#0EA5E9'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('QUOTATION', style: pw.TextStyle(font: _boldFont, fontSize: 20, color: PdfColors.white)),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Quote #: ${quotation.quotationNumber}', style: boldStyle),
                    pw.Text('Date: ${_dateFormat.format(quotation.createdAt)}', style: smallStyle),
                    if (quotation.validUntil != null)
                      pw.Text('Valid Until: ${DateFormat('dd/MM/yyyy').format(quotation.validUntil!)}', 
                        style: smallStyle.copyWith(color: quotation.isExpired ? PdfColors.red : PdfColors.green)),
                    pw.Text('Status: ${quotation.status.name.toUpperCase()}', 
                      style: smallStyle.copyWith(color: PdfColor.fromHex('#0EA5E9'))),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Customer BILL TO section (like invoice)
            if (quotation.customerName != null || customer != null)
              pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#1E3A5F'), width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#1E3A5F'),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text('BILL TO', style: pw.TextStyle(font: _boldFont, fontSize: 9, color: PdfColors.white)),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      customer?.name ?? quotation.customerName ?? 'Walk-in Customer',
                      style: boldStyle.copyWith(fontSize: 13),
                    ),
                    if (customer?.phone != null) ...[                      pw.SizedBox(height: 4),
                      pw.Text('Phone: ${customer!.phone}', style: smallStyle),
                    ],
                    if (customer?.address != null) ...[                      pw.SizedBox(height: 2),
                      pw.Text(customer!.address!, style: smallStyle),
                    ],
                  ],
                ),
              ),
            
            pw.SizedBox(height: 20),
            
            // Items table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(50),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FixedColumnWidth(60),
                5: const pw.FixedColumnWidth(80),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0EA5E9')),
                  children: [
                    _tableHeader('S.No', headerStyle),
                    _tableHeader('Item Description', headerStyle),
                    _tableHeader('Qty', headerStyle),
                    _tableHeader('Unit Price', headerStyle),
                    _tableHeader('Disc', headerStyle),
                    _tableHeader('Amount', headerStyle),
                  ],
                ),
                // Item rows
                ...items.asMap().entries.map((entry) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: entry.key.isEven ? PdfColors.white : PdfColors.grey50,
                  ),
                  children: [
                    _tableCell('${entry.key + 1}', baseStyle),
                    _tableCell(entry.value.productName, baseStyle, align: pw.TextAlign.left),
                    _tableCell('${entry.value.quantity}', baseStyle),
                    _tableCell(_formatCurrency(entry.value.unitPrice), baseStyle),
                    _tableCell(entry.value.discount > 0 ? '-${_formatCurrency(entry.value.discount)}' : '-', baseStyle),
                    _tableCell(_formatCurrency(entry.value.total), baseStyle),
                  ],
                )),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', _formatCurrency(quotation.subtotal + quotation.discountAmount), baseStyle, boldStyle),
                      if (quotation.discountAmount > 0)
                        _summaryRow('Discount', '-${_formatCurrency(quotation.discountAmount)}', baseStyle, boldStyle, isDiscount: true),
                      _summaryRow('Tax (${settings.taxRate}%)', _formatCurrency(quotation.taxAmount), baseStyle, boldStyle),
                      pw.Divider(thickness: 1),
                      _summaryRow('TOTAL', _formatCurrency(quotation.totalAmount), baseStyle, boldStyle, isBold: true, isLarge: true),
                    ],
                  ),
                ),
              ],
            ),
            
            // Notes
            if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.amber200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('NOTES:', style: boldStyle),
                    pw.SizedBox(height: 4),
                    pw.Text(quotation.notes!, style: smallStyle),
                  ],
                ),
              ),
            ],
            
            pw.Spacer(),
            
            // Terms and conditions
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TERMS & CONDITIONS:', style: boldStyle.copyWith(fontSize: 9)),
                  pw.SizedBox(height: 4),
                  pw.Text('1. This quotation is valid for the period mentioned above.', style: smallStyle),
                  pw.Text('2. Prices are subject to change without prior notice.', style: smallStyle),
                  pw.Text('3. Payment terms as per company policy.', style: smallStyle),
                ],
              ),
            ),
            
            pw.SizedBox(height: 10),
            
            // QR Code and Signature Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // QR Code
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'QT:${quotation.quotationNumber}|AMT:${quotation.totalAmount.toStringAsFixed(2)}|DT:${_dateFormat.format(quotation.createdAt)}|CUST:${quotation.customerName ?? "Walk-in"}',
                      width: 70,
                      height: 70,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Scan to verify', style: pw.TextStyle(font: _regularFont, fontSize: 7, color: PdfColors.grey500)),
                  ],
                ),
                
                // Customer Signature
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      height: 1,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Customer Signature', style: pw.TextStyle(font: _regularFont, fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                
                // STAMP placeholder
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text('STAMP', style: pw.TextStyle(font: _regularFont, fontSize: 8, color: PdfColors.grey400)),
                  ),
                ),
                
                // Authorized Signature
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      height: 1,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signature', style: pw.TextStyle(font: _regularFont, fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('For ${settings.businessName}', style: pw.TextStyle(font: _boldFont, fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(settings.thankYouMessage ?? 'Thank you for your interest!', style: smallStyle.copyWith(color: PdfColors.grey600)),
                pw.Text('Generated by AquaStock Pro', style: pw.TextStyle(font: _regularFont, fontSize: 8, color: PdfColors.grey400)),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Save quotation as PDF file
  Future<String?> saveQuotationPdf({
    required Quotation quotation,
    required BusinessSettings settings,
    required List<QuotationItem> items,
  }) async {
    try {
      final pdfData = await generateQuotationPdf(
        quotation: quotation,
        settings: settings,
        items: items,
      );
      
      final filename = 'quotation_${quotation.quotationNumber}.pdf';
      
      await Printing.sharePdf(bytes: pdfData, filename: filename);
      
      return filename;
    } catch (e) {
      rethrow;
    }
  }

  /// Print quotation PDF
  Future<void> printQuotationPdf({
    required Quotation quotation,
    required BusinessSettings settings,
    Customer? customer,
  }) async {
    final pdfData = await generateQuotationPdf(
      quotation: quotation,
      settings: settings,
      items: quotation.items,
      customer: customer,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfData,
      name: 'Quotation_${quotation.quotationNumber}.pdf',
    );
  }

  /// Generate Payment Receipt PDF (Invoice Style with QR Code)
  Future<Uint8List> generatePaymentReceiptPdf({
    required Customer customer,
    required double amountReceived,
    required double previousBalance,
    required double newBalance,
    required BusinessSettings settings,
    String? notes,
    List<Order>? pendingOrders,
    DateTime? paymentDate, // Original payment date for old receipts
  }) async {
    final pdf = pw.Document();
    final receiptDate = paymentDate ?? DateTime.now(); // Use payment date if provided
    final printedDate = DateTime.now(); // Always current for footer
    final receiptNo = 'PMT${receiptDate.millisecondsSinceEpoch.toString().substring(6)}';
    final isFullyPaid = newBalance <= 0;

    // Try to load logo if available
    pw.ImageProvider? logoImage;
    if (settings.logoUrl != null && settings.logoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(settings.logoUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Failed to load logo: $e');
      }
    }

    // Build QR data
    final qrData = [
      'RCPT:$receiptNo',
      'SHOP:${settings.businessName}',
      'CUST:${customer.name}',
      'AMT:${amountReceived.toStringAsFixed(0)}',
      'BAL:${newBalance.toStringAsFixed(0)}',
      'DT:${DateFormat('dd/MM/yy HH:mm').format(receiptDate)}',
      isFullyPaid ? 'STATUS:PAID' : 'STATUS:DUE',
    ].join('|');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header with Logo
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.businessName,
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                      ),
                      if (settings.address != null) pw.SizedBox(height: 4),
                      if (settings.address != null)
                        pw.Text(settings.address!, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                      if (settings.phone != null)
                        pw.Text('Ph: ${settings.phone}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                      if (settings.email != null)
                        pw.Text('Email: ${settings.email}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 70,
                      height: 70,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Title and Receipt Info Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Receipt No: $receiptNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(receiptDate)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Customer Info Row with QR
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer Details
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECEIVED FROM', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text(customer.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        if (customer.phone != null)
                          pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 11)),
                        if (customer.email != null)
                          pw.Text('Email: ${customer.email}', style: const pw.TextStyle(fontSize: 11)),
                        if (customer.address != null)
                          pw.Text('Address: ${customer.address}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                // QR Code
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: qrData,
                        width: 80,
                        height: 80,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Scan to verify', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Pending Invoices Table (if any)
            if (pendingOrders != null && pendingOrders.isNotEmpty) ...[
              pw.Text('OUTSTANDING INVOICES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.3),
                  3: const pw.FlexColumnWidth(1.3),
                  4: const pw.FlexColumnWidth(1.3),
                  5: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _receiptTableCell('Invoice No', isHeader: true),
                      _receiptTableCell('Date', isHeader: true),
                      _receiptTableCell('Total', isHeader: true),
                      _receiptTableCell('Paid', isHeader: true),
                      _receiptTableCell('Due', isHeader: true),
                      _receiptTableCell('Mode', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...pendingOrders.take(5).map((order) {
                    final due = order.totalAmount - order.paidAmount;
                    return pw.TableRow(
                      children: [
                        _receiptTableCell(order.orderNumber ?? '-'),
                        _receiptTableCell(DateFormat('dd/MM/yy').format(order.createdAt)),
                        _receiptTableCell(_formatCurrency(order.totalAmount)),
                        _receiptTableCell(_formatCurrency(order.paidAmount)),
                        _receiptTableCell(_formatCurrency(due), isRed: due > 0),
                        _receiptTableCell(order.paymentMethodDisplayName),
                      ],
                    );
                  }),
                ],
              ),
              if (pendingOrders.length > 5)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text('... and ${pendingOrders.length - 5} more invoices', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                ),
              pw.SizedBox(height: 20),
            ],
            
            // Payment Summary Box
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.indigo200, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  // Header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                    ),
                    child: pw.Center(
                      child: pw.Text('PAYMENT SUMMARY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    ),
                  ),
                  _pdfTableRow('Previous Outstanding', _formatCurrency(previousBalance), isHeader: false),
                  pw.Divider(height: 1, color: PdfColors.grey300),
                  _pdfTableRow('Amount Received', '- ${_formatCurrency(amountReceived)}', highlight: true, highlightColor: PdfColors.green50),
                  pw.Divider(height: 1, color: PdfColors.grey300),
                  pw.Container(
                    color: isFullyPaid ? PdfColors.green50 : PdfColors.amber50,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Balance Due', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text(
                          isFullyPaid ? 'NIL' : _formatCurrency(newBalance),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: isFullyPaid ? PdfColors.green700 : PdfColors.red700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // NO DUES Badge (if fully paid)
            if (isFullyPaid)
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'NO DUES - ACCOUNT CLEARED',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Notes
            if (notes != null && notes.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('Notes: $notes', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ),
            ],
            
            pw.Spacer(),
            
            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Printed: ${DateFormat('dd/MM/yy hh:mm a').format(printedDate)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    pw.Text('This is a computer generated receipt', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
                pw.Text('Thank you for your payment!', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
              ],
            ),
            pw.SizedBox(height: 12),
            // AquaStock Pro Branding
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Generated by AquaStock Pro',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Receipt table cell helper
  pw.Widget _receiptTableCell(String text, {bool isHeader = false, bool isRed = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: isRed ? PdfColors.red700 : null,
        ),
      ),
    );
  }



  /// Helper for PDF table row
  pw.Widget _pdfTableRow(String label, String value, {bool isHeader = false, bool highlight = false, PdfColor? highlightColor}) {
    return pw.Container(
      color: highlight ? highlightColor : null,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : null)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isHeader ? 14 : 12)),
        ],
      ),
    );
  }

  /// Print Payment Receipt
  Future<void> printPaymentReceipt({
    required Customer customer,
    required double amountReceived,
    required double previousBalance,
    required double newBalance,
    required BusinessSettings settings,
    String? notes,
    List<Order>? pendingOrders,
    DateTime? paymentDate,
  }) async {
    final pdfData = await generatePaymentReceiptPdf(
      customer: customer,
      amountReceived: amountReceived,
      previousBalance: previousBalance,
      newBalance: newBalance,
      settings: settings,
      notes: notes,
      pendingOrders: pendingOrders,
      paymentDate: paymentDate,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfData,
      name: 'Payment_Receipt_${customer.name.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Share Payment Receipt
  Future<void> sharePaymentReceipt({
    required Customer customer,
    required double amountReceived,
    required double previousBalance,
    required double newBalance,
    required BusinessSettings settings,
    String? notes,
    List<Order>? pendingOrders,
    DateTime? paymentDate,
  }) async {
    final pdfData = await generatePaymentReceiptPdf(
      customer: customer,
      amountReceived: amountReceived,
      previousBalance: previousBalance,
      newBalance: newBalance,
      settings: settings,
      notes: notes,
      pendingOrders: pendingOrders,
      paymentDate: paymentDate,
    );

    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Payment_Receipt_${customer.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
