import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';

/// Service for exporting data to CSV and Excel formats
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormat = DateFormat('yyyy-MM-dd_HH-mm');
  final _displayDateFormat = DateFormat('dd/MM/yyyy hh:mm a');
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  // ================== PRODUCTS EXPORT ==================

  /// Export products to CSV
  Future<String?> exportProductsToCSV(List<Product> products) async {
    try {
      final headers = [
        'Name',
        'SKU',
        'Category',
        'Price',
        'Cost Price',
        'Stock',
        'Unit',
        'Barcode',
        'Low Stock Threshold',
        'Active',
      ];

      final rows = products.map((p) => [
        p.name,
        p.sku ?? '',
        p.categoryId ?? '',
        p.price.toStringAsFixed(2),
        p.costPrice?.toStringAsFixed(2) ?? '',
        p.stockQuantity.toString(),
        p.unit,
        p.barcode ?? '',
        p.lowStockThreshold.toString(),
        p.isActive ? 'Yes' : 'No',
      ]).toList();

      return await _saveCSV('products', headers, rows);
    } catch (e) {
      return null;
    }
  }

  /// Export products to Excel
  Future<String?> exportProductsToExcel(List<Product> products) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Products'];

      // Headers
      final headers = [
        'Name', 'SKU', 'Category', 'Price', 'Cost Price',
        'Stock', 'Unit', 'Barcode', 'Low Stock Threshold', 'Active'
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
      }

      // Data rows
      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        final row = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(p.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(p.sku ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(p.categoryId ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(p.price);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(p.costPrice ?? 0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = IntCellValue(p.stockQuantity);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(p.unit ?? 'pcs');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(p.barcode ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = IntCellValue(p.lowStockThreshold);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = TextCellValue(p.isActive ? 'Yes' : 'No');
      }

      return await _saveExcel('products', excel);
    } catch (e) {
      return null;
    }
  }

  // ================== ORDERS EXPORT ==================

  /// Export orders to CSV
  Future<String?> exportOrdersToCSV(List<Order> orders) async {
    try {
      final headers = [
        'Order Number',
        'Date',
        'Customer',
        'Subtotal',
        'Tax',
        'Discount',
        'Total',
        'Paid Amount',
        'Payment Method',
        'Status',
      ];

      final rows = orders.map((o) => [
        o.orderNumber,
        _displayDateFormat.format(o.createdAt),
        o.customerName ?? 'Walk-in',
        o.subtotal.toStringAsFixed(2),
        o.taxAmount.toStringAsFixed(2),
        o.discountAmount.toStringAsFixed(2),
        o.totalAmount.toStringAsFixed(2),
        o.paidAmount.toStringAsFixed(2),
        o.paymentMethodDisplayName,
        o.statusDisplayName,
      ]).toList();

      return await _saveCSV('orders', headers, rows);
    } catch (e) {
      return null;
    }
  }

  /// Export orders to Excel
  Future<String?> exportOrdersToExcel(List<Order> orders) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Orders'];

      final headers = [
        'Order Number', 'Date', 'Customer', 'Subtotal', 'Tax',
        'Discount', 'Total', 'Paid Amount', 'Payment Method', 'Status'
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
      }

      for (var i = 0; i < orders.length; i++) {
        final o = orders[i];
        final row = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(o.orderNumber);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(_displayDateFormat.format(o.createdAt));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(o.customerName ?? 'Walk-in');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(o.subtotal);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = DoubleCellValue(o.taxAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(o.discountAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(o.totalAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(o.paidAmount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = TextCellValue(o.paymentMethodDisplayName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = TextCellValue(o.statusDisplayName);
      }

      return await _saveExcel('orders', excel);
    } catch (e) {
      return null;
    }
  }

  // ================== CUSTOMERS EXPORT ==================

  /// Export customers to CSV
  Future<String?> exportCustomersToCSV(List<Customer> customers) async {
    try {
      final headers = [
        'Name',
        'Phone',
        'Email',
        'Address',
        'Type',
        'Total Purchases',
        'Visit Count',
        'Credit Balance',
        'Credit Limit',
        'Loyalty Points',
      ];

      final rows = customers.map((c) => [
        c.name,
        c.phone ?? '',
        c.email ?? '',
        c.address ?? '',
        c.customerTypeDisplayName,
        c.totalPurchases.toStringAsFixed(2),
        c.visitCount.toString(),
        c.creditBalance.toStringAsFixed(2),
        c.creditLimit.toStringAsFixed(2),
        c.loyaltyPoints.toStringAsFixed(2),
      ]).toList();

      return await _saveCSV('customers', headers, rows);
    } catch (e) {
      return null;
    }
  }

  // ================== HELPER METHODS ==================

  Future<String?> _saveCSV(String name, List<String> headers, List<List<dynamic>> rows) async {
    try {
      final csvData = [headers, ...rows];
      final csvString = const ListToCsvConverter().convert(csvData);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${name}_${_dateFormat.format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);
      
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _saveExcel(String name, Excel excel) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${name}_${_dateFormat.format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Share a file
  Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles([XFile(filePath)], subject: subject);
  }
}
