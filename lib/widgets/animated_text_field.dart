import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';

class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? errorText;

  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: hasError
                ? AppColors.error
                : _isFocused
                    ? AppColors.primary
                    : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 10),

        // Input
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : Color.lerp(
                          Colors.transparent,
                          AppColors.primary,
                          _focusAnimation.value,
                        )!,
                  width: 2,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: (hasError ? AppColors.error : AppColors.primary)
                              .withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.isPassword && _obscureText,
                keyboardType: widget.keyboardType,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      widget.icon,
                      color: hasError
                          ? AppColors.error
                          : _isFocused
                              ? AppColors.primary
                              : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 56,
                  ),
                  suffixIcon: widget.isPassword
                      ? GestureDetector(
                          onTap: () {
                            setState(() => _obscureText = !_obscureText);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(
                              _obscureText
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                  ),
                ),
              ),
            );
          },
        ),

        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}