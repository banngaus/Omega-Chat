import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omega_chat/theme/app_colors.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String? recipientAvatar;
  final String? recipientName;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.recipientAvatar,
    this.recipientName,
    this.onDoubleTap,
    this.onLongPress,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDoubleTap() async {
    HapticFeedback.mediumImpact();
    setState(() => _showHeart = true);
    widget.onDoubleTap?.call();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _showHeart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.message['image'] != null &&
        widget.message['image'].toString().isNotEmpty;
    final hasText = widget.message['text'] != null &&
        widget.message['text'].toString().isNotEmpty;
    final isRead = widget.message['is_read'] == true;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onLongPress: () {
        HapticFeedback.heavyImpact();
        widget.onLongPress?.call();
      },
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: widget.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Аватар отправителя (для чужих сообщений)
                      if (!widget.isMe) ...[
                        _buildSenderAvatar(),
                        const SizedBox(width: 8),
                      ],

                      // Сообщение
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildBubble(hasImage, hasText),

                          // Сердечко при двойном тапе
                          if (_showHeart)
                            Positioned.fill(
                              child: Center(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: const Text(
                                        '❤️',
                                        style: TextStyle(fontSize: 48),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Статус прочтения — аватарка под сообщением
                  if (widget.isMe)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: _buildReadStatus(isRead),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSenderAvatar() {
    final avatar = widget.message['user_avatar'];
    final username = widget.message['username'] ?? '?';

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: avatar != null && avatar.toString().isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(avatar, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
    );
  }

  Widget _buildReadStatus(bool isRead) {
    if (!isRead) {
      // Не прочитано — точка
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message['time'] ?? '',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    }

    // Прочитано — маленькая аватарка получателя
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.message['time'] ?? '',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(5),
          ),
          child: widget.recipientAvatar != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    widget.recipientAvatar!,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    (widget.recipientName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBubble(bool hasImage, bool hasText) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        gradient: widget.isMe ? AppColors.messageGradient : null,
        color: widget.isMe ? null : AppColors.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(widget.isMe ? 20 : 6),
          bottomRight: Radius.circular(widget.isMe ? 6 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isMe
                ? AppColors.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(widget.isMe ? 20 : 6),
          bottomRight: Radius.circular(widget.isMe ? 6 : 20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Имя отправителя
            if (!widget.isMe)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 10, right: 14),
                child: Text(
                  widget.message['username'] ?? 'Аноним',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Картинка
            if (hasImage)
              Padding(
                padding: EdgeInsets.only(
                  top: widget.isMe ? 4 : 6,
                  left: 4,
                  right: 4,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.message['image'],
                    fit: BoxFit.cover,
                    width: 250,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 250,
                        height: 150,
                        color: AppColors.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Текст
            if (hasText)
              Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: hasImage ? 8 : (widget.isMe ? 12 : 6),
                  bottom: 12,
                ),
                child: Text(
                  widget.message['text'],
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.isMe ? Colors.white : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}