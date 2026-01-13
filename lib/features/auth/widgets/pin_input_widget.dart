import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';

class PinInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final bool isLoading;
  final bool hasError;
  final int pinLength;

  const PinInputWidget({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.isLoading = false,
    this.hasError = false,
    this.pinLength = 4,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Auto-focus on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(PinInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    setState(() {});
    if (value.length == widget.pinLength) {
      widget.onCompleted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinValue = widget.controller.text;

    return Column(
      children: [
        // Hidden text field for controller state only (no system keyboard)
        SizedBox(
          height: 0,
          width: 0,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            readOnly: true, // Prevents system keyboard
            showCursor: false,
            maxLength: widget.pinLength,
            obscureText: true,
            enableInteractiveSelection: false,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),

        // Visual PIN dots
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final shakeOffset =
                  _shakeAnimation.value * 10 * ((_shakeAnimation.value * 4).round().isEven ? 1 : -1);
              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: child,
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive box size
                // Available width for boxes = total width - margins (10*2 per box * 4 boxes = 80)
                final availableWidth = constraints.maxWidth - 80;
                final boxSize = (availableWidth / 4).clamp(40.0, 56.0);
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.pinLength, (index) {
                    final isFilled = index < pinValue.length;
                    final isActive = index == pinValue.length;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? (widget.hasError
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1))
                              : (isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.grey100),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.hasError
                                ? AppColors.error
                                : isActive
                                    ? AppColors.primary
                                    : (isFilled
                                        ? AppColors.primary.withValues(alpha: 0.5)
                                        : Colors.transparent),
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isFilled
                              ? Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: widget.hasError
                                        ? AppColors.error
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : isActive && !widget.isLoading
                                  ? Container(
                                      width: 2,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    )
                                  : null,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Number pad
        if (!widget.isLoading) _buildNumberPad(isDark),

        if (widget.isLoading) ...[
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }

  Widget _buildNumberPad(bool isDark) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int col = 0; col < 3; col++)
                    _buildNumberButton(
                      row == 3
                          ? (col == 0
                              ? ''
                              : col == 1
                                  ? '0'
                                  : 'del')
                          : '${row * 3 + col + 1}',
                      isDark,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String value, bool isDark) {
    final isDelete = value == 'del';
    final isEmpty = value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEmpty
              ? null
              : () {
                  if (isDelete) {
                    if (widget.controller.text.isNotEmpty) {
                      widget.controller.text = widget.controller.text
                          .substring(0, widget.controller.text.length - 1);
                      setState(() {});
                    }
                  } else {
                    if (widget.controller.text.length < widget.pinLength) {
                      widget.controller.text += value;
                      _onPinChanged(widget.controller.text);
                    }
                  }
                  HapticFeedback.lightImpact();
                },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isEmpty
                  ? Colors.transparent
                  : (isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.grey100),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDelete
                  ? Icon(
                      Icons.backspace_outlined,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      size: 24,
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
