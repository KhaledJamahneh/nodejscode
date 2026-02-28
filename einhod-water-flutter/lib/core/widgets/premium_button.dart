import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final double? width;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.width,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final bgColor = widget.backgroundColor ?? AppTheme.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: isDisabled ? null : (_) {
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width ?? double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: widget.isOutlined ? Colors.transparent : bgColor.withOpacity(isDisabled ? 0.5 : 1.0),
            borderRadius: BorderRadius.circular(12),
            border: widget.isOutlined
                ? Border.all(color: bgColor.withOpacity(isDisabled ? 0.3 : 0.5), width: 1.5)
                : null,
            boxShadow: widget.isOutlined || isDisabled
                ? null
                : [
                    BoxShadow(
                      color: bgColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isOutlined ? bgColor : fgColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: widget.isOutlined ? bgColor : fgColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: widget.isOutlined ? bgColor : fgColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
