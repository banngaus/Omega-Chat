import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/games/game_button.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final String token;
  final int chatId;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.token,
    required this.chatId,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onSend() {
    if (!_hasText) return;
    HapticFeedback.lightImpact();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceLight.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Кнопка прикрепить
            _ActionButton(
              icon: Icons.add_rounded,
              onPressed: widget.onAttach,
            ),
            const SizedBox(width: 8),

            // Кнопка игр
            GameButton(
              token: widget.token,
              chatId: widget.chatId,
            ),
            const SizedBox(width: 8),

            // Поле ввода
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Сообщение...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _onSend(),
                      ),
                    ),
                    // Эмодзи
                    GestureDetector(
                      onTap: () {
                        // TODO: открыть эмодзи пикер
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12, bottom: 12),
                        child: Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Кнопка отправить
            AnimatedBuilder(
              animation: _sendButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonAnimation.value,
                  child: _SendButton(
                    onPressed: _onSend,
                    isActive: _hasText,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const _SendButton({
    required this.onPressed,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? AppColors.primaryShadow(0.4) : [],
        ),
        child: Icon(
          Icons.send_rounded,
          color: isActive ? Colors.white : AppColors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}