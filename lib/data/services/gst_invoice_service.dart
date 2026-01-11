import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/order.dart';
import '../models/business_settings.dart';

/// GST Invoice Generator for creating tax-compliant invoices
class GSTInvoiceService {
  /// Generate GST Invoice PDF
  static Future<pw.Document> generateInvoice({
    required Order order,
    required BusinessSettings settings,
    String? hsnCode,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd-MM-yyyy');
    final invoiceNumber = 'INV-${order.orderNumber}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildHeader(settings, invoiceNumber, order, dateFormat),
          pw.SizedBox(height: 20),
          
          // Customer & Supply details
          _buildPartyDetails(order, settings),
          pw.SizedBox(height: 20),
          
          // Items table
          _buildItemsTable(order, currencyFormat, hsnCode),
          pw.SizedBox(height: 20),
          
          // Summary
          _buildSummary(order, settings, currencyFormat),
          pw.SizedBox(height: 30),
          
          // Footer
          _buildFooter(settings),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
    BusinessSettings settings,
    String invoiceNumber,
    Order order,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  settings.businessName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (settings.tagline != null)
                  pw.Text(settings.tagline!, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Invoice #: $invoiceNumber', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Date: ${dateFormat.format(order.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        // Business details
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (settings.address != null)
                    pw.Text('Address: ${settings.fullAddress}', style: const pw.TextStyle(fontSize: 10)),
                  if (settings.phone != null)
                    pw.Text('Phone: ${settings.phone}', style: const pw.TextStyle(fontSize: 10)),
                  if (settings.email != null)
                    pw.Text('Email: ${settings.email}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (settings.gstin != null)
                    pw.Text(
                      'GSTIN: ${settings.gstin}',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  pw.Text('State: ${settings.state ?? "N/A"}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPartyDetails(Order order, BusinessSettings settings) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bill To:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
                pw.SizedBox(height: 4),
                pw.Text(order.customerName ?? 'Cash Customer', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Place of Supply:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
                pw.SizedBox(height: 4),
                pw.Text(settings.state ?? 'N/A', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    Order order,
    NumberFormat currencyFormat,
    String? defaultHsnCode,
  ) {
    final headers = ['#', 'Item', 'HSN', 'Qty', 'Rate', 'Tax', 'Amount'];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(50),
        6: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              h,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          )).toList(),
        ),
        // Data rows
        ...order.items.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          final taxAmount = item.total * 0.18; // Assuming 18% GST
          
          return pw.TableRow(
            children: [
              _tableCell('$idx'),
              _tableCell(item.productName, align: pw.TextAlign.left),
              _tableCell(defaultHsnCode ?? '9999'),
              _tableCell('${item.quantity}'),
              _tableCell(currencyFormat.format(item.unitPrice)),
              _tableCell('18%'),
              _tableCell(currencyFormat.format(item.total)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: align),
    );
  }

  static pw.Widget _buildSummary(
    Order order,
    BusinessSettings settings,
    NumberFormat currencyFormat,
  ) {
    final taxRate = settings.taxRate;
    final subtotal = order.subtotal;
    final cgst = subtotal * (taxRate / 2 / 100);
    final sgst = subtotal * (taxRate / 2 / 100);
    final totalTax = cgst + sgst;
    final grandTotal = subtotal + totalTax - order.discountAmount;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            children: [
              _summaryRow('Subtotal', currencyFormat.format(subtotal)),
              _summaryRow('CGST (${taxRate / 2}%)', currencyFormat.format(cgst)),
              _summaryRow('SGST (${taxRate / 2}%)', currencyFormat.format(sgst)),
              if (order.discountAmount > 0)
                _summaryRow('Discount', '- ${currencyFormat.format(order.discountAmount)}'),
              pw.Divider(),
              _summaryRow(
                'Grand Total',
                currencyFormat.format(grandTotal),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false}) {
    final style = isBold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
        : const pw.TextStyle(fontSize: 10);
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(BusinessSettings settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('1. Goods once sold will not be taken back.', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('2. Subject to local jurisdiction only.', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('For ${settings.businessName}', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 30),
                pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ],
        ),
        if (settings.thankYouMessage != null) ...[
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              settings.thankYouMessage!,
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  /// Calculate GST breakdown
  static Map<String, double> calculateGST({
    required double amount,
    required double gstRate,
    bool isInterstate = false,
  }) {
    if (isInterstate) {
      // IGST for interstate
      final igst = amount * (gstRate / 100);
      return {
        'IGST': igst,
        'Total': igst,
      };
    } else {
      // CGST + SGST for intrastate
      final halfRate = gstRate / 2;
      final cgst = amount * (halfRate / 100);
      final sgst = amount * (halfRate / 100);
      return {
        'CGST': cgst,
        'SGST': sgst,
        'Total': cgst + sgst,
      };
    }
  }
}

/// Common HSN codes for retail
class HSNCodes {
  static const Map<String, String> common = {
    'food': '2106',
    'beverages': '2202',
    'clothing': '6109',
    'electronics': '8471',
    'furniture': '9403',
    'stationery': '4820',
    'cosmetics': '3304',
    'medicines': '3004',
    'grocery': '1905',
    'hardware': '7318',
    'other': '9999',
  };

  static String getCode(String category) {
    return common[category.toLowerCase()] ?? '9999';
  }
}
