import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/order.dart';
import '../models/product.dart';
import '../models/customer.dart';

/// Report export service for generating PDF and Excel reports
/// Currently provides structure and mock data for web compatibility
class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();
  factory ReportExportService() => _instance;
  ReportExportService._internal();

  /// Generate sales report data
  Future<ReportData> generateSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    List<Order>? orders,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
    
    // Calculate summary data
    final totalSales = orders?.fold<double>(0, (sum, o) => sum + o.totalAmount) ?? 0;
    final totalOrders = orders?.length ?? 0;
    final avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0;
    
    return ReportData(
      title: 'Sales Report',
      subtitle: '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
      generatedAt: DateTime.now(),
      summary: {
        'Total Sales': currencyFormat.format(totalSales),
        'Total Orders': totalOrders.toString(),
        'Average Order Value': currencyFormat.format(avgOrderValue),
      },
      columns: ['Date', 'Order #', 'Customer', 'Items', 'Payment', 'Total'],
      rows: orders?.map((o) => [
        dateFormat.format(o.createdAt),
        o.orderNumber,
        o.customerId ?? 'Walk-in',
        o.itemCount.toString(),
        o.paymentMethod.name,
        currencyFormat.format(o.totalAmount),
      ]).toList() ?? [],
    );
  }

  /// Generate inventory report data
  Future<ReportData> generateInventoryReport({
    List<Product>? products,
    bool lowStockOnly = false,
  }) async {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
    
    var filteredProducts = products ?? [];
    if (lowStockOnly) {
      filteredProducts = filteredProducts.where((p) => p.isLowStock).toList();
    }
    
    final totalValue = filteredProducts.fold<double>(
      0, (sum, p) => sum + (p.price * p.stockQuantity),
    );
    final lowStockCount = filteredProducts.where((p) => p.isLowStock).length;
    
    return ReportData(
      title: lowStockOnly ? 'Low Stock Report' : 'Inventory Report',
      subtitle: 'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      generatedAt: DateTime.now(),
      summary: {
        'Total Products': filteredProducts.length.toString(),
        'Total Stock Value': currencyFormat.format(totalValue),
        'Low Stock Items': lowStockCount.toString(),
      },
      columns: ['SKU', 'Product Name', 'Category', 'Stock', 'Min Stock', 'Price', 'Value'],
      rows: filteredProducts.map((p) => [
        p.sku ?? '-',
        p.name,
        p.categoryId,
        p.stockQuantity.toString(),
        p.lowStockThreshold.toString(),
        currencyFormat.format(p.price),
        currencyFormat.format(p.price * p.stockQuantity),
      ]).toList(),
    );
  }

  /// Generate customer report data
  Future<ReportData> generateCustomerReport({
    List<Customer>? customers,
  }) async {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
    
    final totalSpent = customers?.fold<double>(0, (sum, c) => sum + c.totalPurchases) ?? 0;
    
    return ReportData(
      title: 'Customer Report',
      subtitle: 'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
      generatedAt: DateTime.now(),
      summary: {
        'Total Customers': (customers?.length ?? 0).toString(),
        'Total Revenue': currencyFormat.format(totalSpent),
        'Avg Customer Value': currencyFormat.format(
          customers != null && customers.isNotEmpty 
            ? totalSpent / customers.length 
            : 0
        ),
      },
      columns: ['Name', 'Phone', 'Email', 'Orders', 'Total Spent', 'Loyalty Points'],
      rows: customers?.map((c) => [
        c.name,
        c.phone ?? '-',
        c.email ?? '-',
        c.visitCount.toString(),
        currencyFormat.format(c.totalPurchases),
        c.loyaltyPoints.toInt().toString(),
      ]).toList() ?? [],
    );
  }

  /// Generate tax report data
  Future<ReportData> generateTaxReport({
    required DateTime startDate,
    required DateTime endDate,
    List<Order>? orders,
    double taxRate = 5.0,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2);
    
    final totalSales = orders?.fold<double>(0, (sum, o) => sum + o.totalAmount) ?? 0;
    final totalTax = orders?.fold<double>(0, (sum, o) => sum + o.taxAmount) ?? 0;
    
    return ReportData(
      title: 'Tax Report (GST)',
      subtitle: '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
      generatedAt: DateTime.now(),
      summary: {
        'Total Sales': currencyFormat.format(totalSales),
        'Total Tax Collected': currencyFormat.format(totalTax),
        'Tax Rate': '$taxRate%',
        'Taxable Amount': currencyFormat.format(totalSales - totalTax),
      },
      columns: ['Date', 'Order #', 'Subtotal', 'Tax Amount', 'Total'],
      rows: orders?.map((o) => [
        dateFormat.format(o.createdAt),
        o.orderNumber,
        currencyFormat.format(o.subtotal),
        currencyFormat.format(o.taxAmount),
        currencyFormat.format(o.totalAmount),
      ]).toList() ?? [],
    );
  }

  /// Generate credit report data (customers with pending credit)
  Future<ReportData> generateCreditReport({
    List<Customer>? customers,
  }) async {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Filter customers with credit balance
    final creditCustomers = customers?.where((c) => c.creditBalance > 0).toList() ?? [];
    final totalCredit = creditCustomers.fold<double>(0, (sum, c) => sum + c.creditBalance);
    
    return ReportData(
      title: 'Credit Report - Pending Payments',
      subtitle: 'Generated on ${dateFormat.format(DateTime.now())}',
      generatedAt: DateTime.now(),
      summary: {
        'Customers with Credit': creditCustomers.length.toString(),
        'Total Pending Credit': currencyFormat.format(totalCredit),
        'Average Credit Balance': currencyFormat.format(
          creditCustomers.isNotEmpty ? totalCredit / creditCustomers.length : 0
        ),
      },
      columns: ['Customer Name', 'Phone', 'Credit Balance', 'Last Activity', 'Total Orders'],
      rows: creditCustomers.map((c) => [
        c.name,
        c.phone ?? '-',
        currencyFormat.format(c.creditBalance),
        dateFormat.format(c.updatedAt),
        c.visitCount.toString(),
      ]).toList(),
    );
  }

  /// Generate Profit & Loss report
  Future<ReportData> generateProfitLossReport({
    required DateTime startDate,
    required DateTime endDate,
    List<Order>? orders,
    List<Product>? products,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2);
    
    // Calculate revenue
    final totalRevenue = orders?.fold<double>(0, (sum, o) => sum + o.totalAmount) ?? 0;
    final totalOrders = orders?.length ?? 0;
    
    // Calculate estimated COGS (using average cost if available)
    double totalCost = 0;
    if (orders != null && products != null) {
      for (final order in orders) {
        for (final item in order.items) {
          final product = products.where((p) => p.id == item.productId).firstOrNull;
          if (product != null && product.costPrice != null) {
            totalCost += product.costPrice! * item.quantity;
          }
        }
      }
    }
    
    final grossProfit = totalRevenue - totalCost;
    final profitMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0;
    
    return ReportData(
      title: 'Profit & Loss Report',
      subtitle: '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
      generatedAt: DateTime.now(),
      summary: {
        'Total Revenue': currencyFormat.format(totalRevenue),
        'Cost of Goods Sold': currencyFormat.format(totalCost),
        'Gross Profit': currencyFormat.format(grossProfit),
        'Profit Margin': '${profitMargin.toStringAsFixed(1)}%',
        'Total Orders': totalOrders.toString(),
      },
      columns: ['Metric', 'Amount', 'Percentage'],
      rows: [
        ['Revenue', currencyFormat.format(totalRevenue), '100%'],
        ['Cost of Goods Sold', currencyFormat.format(totalCost), '${(totalCost / totalRevenue * 100).toStringAsFixed(1)}%'],
        ['Gross Profit', currencyFormat.format(grossProfit), '${profitMargin.toStringAsFixed(1)}%'],
        ['Discounts Given', currencyFormat.format(orders?.fold<double>(0, (s, o) => s + o.discountAmount) ?? 0), '-'],
        ['Tax Collected', currencyFormat.format(orders?.fold<double>(0, (s, o) => s + o.taxAmount) ?? 0), '-'],
      ],
    );
  }

  /// Generate GST Report with rate-wise breakdown
  Future<ReportData> generateGSTReport({
    required DateTime startDate,
    required DateTime endDate,
    List<Order>? orders,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2);
    
    // Group by tax rates (assuming 5%, 12%, 18% rates)
    final Map<String, double> taxByRate = {'5%': 0, '12%': 0, '18%': 0};
    final Map<String, double> salesByRate = {'5%': 0, '12%': 0, '18%': 0};
    
    // For simplicity, assume all sales are at 5% (can be enhanced per-item)
    final totalSales = orders?.fold<double>(0, (sum, o) => sum + o.subtotal) ?? 0;
    final totalTax = orders?.fold<double>(0, (sum, o) => sum + o.taxAmount) ?? 0;
    taxByRate['5%'] = totalTax;
    salesByRate['5%'] = totalSales;
    
    return ReportData(
      title: 'GST Report - GSTR-1 Summary',
      subtitle: '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
      generatedAt: DateTime.now(),
      summary: {
        'Total Taxable Sales': currencyFormat.format(totalSales),
        'Total GST Collected': currencyFormat.format(totalTax),
        'CGST': currencyFormat.format(totalTax / 2),
        'SGST': currencyFormat.format(totalTax / 2),
      },
      columns: ['Tax Rate', 'Taxable Amount', 'CGST', 'SGST', 'Total GST'],
      rows: taxByRate.entries.map((e) {
        final sales = salesByRate[e.key] ?? 0;
        final tax = e.value;
        return [
          e.key,
          currencyFormat.format(sales),
          currencyFormat.format(tax / 2),
          currencyFormat.format(tax / 2),
          currencyFormat.format(tax),
        ];
      }).toList(),
    );
  }

  /// Export report to PDF bytes
  /// Generates a professional PDF document with header, summary, and data table
  Future<Uint8List> exportToPdf(ReportData reportData) async {
    final pdf = pw.Document();
    
    // Colors
    final primaryColor = PdfColor.fromHex('#1E3A5F');
    final headerColor = PdfColor.fromHex('#2196F3');
    final altRowColor = PdfColor.fromHex('#F5F5F5');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AquaStock Pro',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Business Management System',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(reportData.generatedAt),
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: headerColor, thickness: 2),
            pw.SizedBox(height: 16),
            pw.Text(
              reportData.title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.Text(
              reportData.subtitle,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by AquaStock Pro',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E3F2FD'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: reportData.summary.entries.map((e) =>
                    pw.Container(
                      width: 150,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            e.key,
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            e.value,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Data Table
          if (reportData.columns.isNotEmpty && reportData.rows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: pw.BoxDecoration(color: headerColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: reportData.columns,
              data: reportData.rows.asMap().entries.map((entry) {
                return entry.value;
              }).toList(),
              oddRowDecoration: pw.BoxDecoration(color: altRowColor),
            )
          else
            pw.Text(
              'No data available for this report.',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
        ],
      ),
    );
    
    return pdf.save();
  }

  /// Export report to Excel/CSV bytes
  Future<Uint8List> exportToExcel(ReportData reportData) async {
    // Generate CSV format (Excel compatible)
    final buffer = StringBuffer();
    
    // Title
    buffer.writeln(reportData.title);
    buffer.writeln(reportData.subtitle);
    buffer.writeln('');
    
    // Summary
    buffer.writeln('Summary');
    reportData.summary.forEach((key, value) {
      buffer.writeln('$key,$value');
    });
    buffer.writeln('');
    
    // Data table
    buffer.writeln(reportData.columns.join(','));
    for (final row in reportData.rows) {
      // Escape commas in values
      final escapedRow = row.map((cell) {
        if (cell.contains(',') || cell.contains('"')) {
          return '"${cell.replaceAll('"', '""')}"';
        }
        return cell;
      });
      buffer.writeln(escapedRow.join(','));
    }
    
    return Uint8List.fromList(buffer.toString().codeUnits);
  }

  /// Format report as preview text
  String formatAsPreview(ReportData reportData, {int maxRows = 10}) {
    final buffer = StringBuffer();
    
    buffer.writeln('═' * 50);
    buffer.writeln(reportData.title.toUpperCase());
    buffer.writeln(reportData.subtitle);
    buffer.writeln('═' * 50);
    buffer.writeln('');
    
    buffer.writeln('SUMMARY:');
    reportData.summary.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln('');
    
    buffer.writeln('DATA (${reportData.rows.length} records):');
    buffer.writeln('-' * 50);
    
    final displayRows = reportData.rows.take(maxRows);
    for (final row in displayRows) {
      buffer.writeln(row.join(' | '));
    }
    
    if (reportData.rows.length > maxRows) {
      buffer.writeln('... and ${reportData.rows.length - maxRows} more records');
    }
    
    return buffer.toString();
  }
}

/// Report data model for export
class ReportData {
  final String title;
  final String subtitle;
  final DateTime generatedAt;
  final Map<String, String> summary;
  final List<String> columns;
  final List<List<String>> rows;

  const ReportData({
    required this.title,
    required this.subtitle,
    required this.generatedAt,
    required this.summary,
    required this.columns,
    required this.rows,
  });

  int get rowCount => rows.length;
  bool get isEmpty => rows.isEmpty;
}

/// Report type enum
enum ReportType {
  sales('Sales Report', 'Revenue and order analytics'),
  inventory('Inventory Report', 'Stock levels and valuation'),
  topProducts('Top Products', 'Best-selling items'),
  profit('Profit & Loss', 'Revenue, cost, and margins'),
  credit('Credit Report', 'Pending payments from customers'),
  customers('Customer Report', 'Customer analytics and loyalty'),
  tax('Tax Report', 'Tax summary'),
  gst('GST Report', 'GSTR-1 compliant GST breakdown');

  final String title;
  final String description;
  const ReportType(this.title, this.description);
}

/// Export format enum
enum ExportFormat {
  pdf('PDF', 'Portable Document Format'),
  excel('Excel/CSV', 'Spreadsheet format'),
  preview('Preview', 'View on screen');

  final String title;
  final String description;
  const ExportFormat(this.title, this.description);
}
