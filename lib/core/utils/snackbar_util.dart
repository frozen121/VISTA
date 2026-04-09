import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SnackBarUtil {
  static OverlayEntry? _overlayEntry;

  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      AppColors.success,
      Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      AppColors.error,
      Icons.error_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      AppColors.info,
      Icons.info_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      AppColors.warning,
      Icons.warning_rounded,
    );
  }

  static void _showCustomSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    // Удаляем предыдущее уведомление
    _overlayEntry?.remove();

    final overlay = Overlay.of(context);
    bool isVisible = true;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: _AnimatedSnackBar(
          message: message,
          backgroundColor: backgroundColor,
          icon: icon,
          onClose: () {
            if (isVisible) {
              isVisible = false;
              _overlayEntry?.remove();
            }
          },
          duration: const Duration(seconds: 4),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);

    // Автоматическое удаление через 4.4 секунды (4 сек + 0.4 сек анимация)
    Future.delayed(const Duration(milliseconds: 4400), () {
      if (isVisible && _overlayEntry != null) {
        isVisible = false;
        _overlayEntry?.remove();
      }
    });
  }
}

class _AnimatedSnackBar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onClose;
  final Duration duration;

  const _AnimatedSnackBar({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onClose,
    required this.duration,
  });

  @override
  State<_AnimatedSnackBar> createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<_AnimatedSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late bool _shouldClose;

  @override
  void initState() {
    super.initState();
    _shouldClose = false;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Автоматическое скрытие через указанное время
    Future.delayed(widget.duration, () {
      if (mounted && !_shouldClose) {
        _closeSnackBar();
      }
    });
  }

  void _closeSnackBar() {
    if (_shouldClose) return;
    _shouldClose = true;
    _controller.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  softWrap: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _closeSnackBar,
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


