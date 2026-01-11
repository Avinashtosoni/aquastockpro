import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import '../../app/theme/app_colors.dart';

/// Unified alert service using QuickAlert for rich, animated alerts
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  /// Show success alert with green checkmark animation
  Future<void> showSuccess({
    required BuildContext context,
    required String title,
    String? text,
    String confirmBtnText = 'OK',
    VoidCallback? onConfirmBtnTap,
    bool autoCloseDuration = false,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText,
      confirmBtnColor: AppColors.success,
      onConfirmBtnTap: onConfirmBtnTap ?? () => Navigator.pop(context),
      autoCloseDuration: autoCloseDuration ? const Duration(seconds: 2) : null,
      animType: QuickAlertAnimType.scale,
    );
  }

  /// Show error alert with red X animation
  Future<void> showError({
    required BuildContext context,
    required String title,
    String? text,
    String confirmBtnText = 'OK',
    VoidCallback? onConfirmBtnTap,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText,
      confirmBtnColor: AppColors.error,
      onConfirmBtnTap: onConfirmBtnTap ?? () => Navigator.pop(context),
      animType: QuickAlertAnimType.scale,
    );
  }

  /// Show warning alert with yellow exclamation
  Future<void> showWarning({
    required BuildContext context,
    required String title,
    String? text,
    String confirmBtnText = 'OK',
    VoidCallback? onConfirmBtnTap,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText,
      confirmBtnColor: AppColors.warning,
      onConfirmBtnTap: onConfirmBtnTap ?? () => Navigator.pop(context),
      animType: QuickAlertAnimType.scale,
    );
  }

  /// Show info alert with blue info icon
  Future<void> showInfo({
    required BuildContext context,
    required String title,
    String? text,
    String confirmBtnText = 'Got it',
    VoidCallback? onConfirmBtnTap,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText,
      confirmBtnColor: AppColors.info,
      onConfirmBtnTap: onConfirmBtnTap ?? () => Navigator.pop(context),
      animType: QuickAlertAnimType.scale,
    );
  }

  /// Show confirmation alert with Yes/No buttons
  Future<void> showConfirm({
    required BuildContext context,
    required String title,
    String? text,
    String confirmBtnText = 'Yes',
    String cancelBtnText = 'Cancel',
    required VoidCallback onConfirmBtnTap,
    VoidCallback? onCancelBtnTap,
    Color? confirmBtnColor,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: title,
      text: text,
      confirmBtnText: confirmBtnText,
      cancelBtnText: cancelBtnText,
      confirmBtnColor: confirmBtnColor ?? AppColors.primary,
      onConfirmBtnTap: () {
        Navigator.pop(context);
        onConfirmBtnTap();
      },
      onCancelBtnTap: onCancelBtnTap ?? () => Navigator.pop(context),
      showCancelBtn: true,
      animType: QuickAlertAnimType.scale,
    );
  }

  /// Show loading alert (must be dismissed programmatically)
  Future<void> showLoading({
    required BuildContext context,
    String title = 'Loading...',
    String? text,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: title,
      text: text,
      barrierDismissible: false,
    );
  }

  /// Dismiss current alert (useful for loading alerts)
  void dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show delete confirmation with red styling
  Future<void> showDeleteConfirm({
    required BuildContext context,
    required String title,
    String? text,
    required VoidCallback onConfirmBtnTap,
  }) async {
    await showConfirm(
      context: context,
      title: title,
      text: text ?? 'This action cannot be undone.',
      confirmBtnText: 'Delete',
      confirmBtnColor: AppColors.error,
      onConfirmBtnTap: onConfirmBtnTap,
    );
  }

  /// Show order success alert with custom styling
  Future<void> showOrderSuccess({
    required BuildContext context,
    required String orderNumber,
    required String amount,
    VoidCallback? onPrint,
    VoidCallback? onNewSale,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Payment Successful!',
      text: 'Order #$orderNumber\nTotal: $amount',
      confirmBtnText: 'New Sale',
      confirmBtnColor: AppColors.success,
      onConfirmBtnTap: () {
        Navigator.pop(context);
        onNewSale?.call();
      },
      showCancelBtn: true,
      cancelBtnText: 'Print Receipt',
      onCancelBtnTap: () {
        Navigator.pop(context);
        onPrint?.call();
      },
      animType: QuickAlertAnimType.scale,
    );
  }
}
