import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? child;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    Widget buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary
                    ? AppColors.white
                    : AppColors.primary,
              ),
            ),
          )
        : child ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: _getIconSize()),
                  const SizedBox(width: 8),
                ],
                Text(label, style: textStyle),
              ],
            );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
            backgroundColor: const WidgetStatePropertyAll(AppColors.accent),
            foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle.copyWith(
            padding: WidgetStatePropertyAll(padding),
            backgroundColor: const WidgetStatePropertyAll(AppColors.error),
          ),
          child: buttonChild,
        );
        break;
    }

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  ButtonStyle _getButtonStyle() {
    return ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }

  TextStyle _getTextStyle() {
    double fontSize;
    switch (size) {
      case AppButtonSize.small:
        fontSize = 12;
        break;
      case AppButtonSize.medium:
        fontSize = 14;
        break;
      case AppButtonSize.large:
        fontSize = 16;
        break;
    }
    return TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600);
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }
}
