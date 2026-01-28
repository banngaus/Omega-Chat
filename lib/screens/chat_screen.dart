import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/services/api_service.dart';
import 'package:omega_chat/widgets/message_bubble.dart';
import 'package:omega_chat/widgets/chat_input_field.dart';
import 'package:omega_chat/widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String token;
  final int chatId;
  final String chatName;
  final String? chatAvatar;
  final VoidCallback? onBack;

  const ChatScreen({
    super.key,
    required this.token,
    required this.chatId,
    required this.chatName,
    this.chatAvatar,
    this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _apiService = ApiService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  WebSocketChannel? _channel;
  String _myUsername = '';
  bool _isConnected = false;
  bool _isTyping = false;
  bool _showScrollButton = false;
  String? _recipientAvatar;
  String? _recipientName;
  int? _recipientId;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initChat();
    _loadRecipientInfo();
    _scrollController.addListener(_onScroll);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  void _onScroll() {
    final showButton =
        _scrollController.hasClients &&
        _scrollController.offset <
            _scrollController.position.maxScrollExtent - 200;
    if (showButton != _showScrollButton) {
      setState(() => _showScrollButton = showButton);
    }
  }

  void _initChat() {
    try {
      final decodedToken = JwtDecoder.decode(widget.token);
      _myUsername = decodedToken['username'];
    } catch (e) {
      _myUsername = 'Unknown';
    }

    setState(() {
      _messages.clear();
      _isConnected = false;
    });

    const baseUrl = '26.81.184.119:8000';
    final wsUrl = 'ws://$baseUrl/ws/dm/${widget.chatId}?token=${widget.token}';

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        final decoded = jsonDecode(message);
        if (decoded['type'] == 'messages_read') {
          // Обновляем статус сообщений
          setState(() {
            for (var msg in _messages) {
              if (msg['sender_id'] == decoded['reader_id']) {
                // Это не наши сообщения, пропускаем
              } else {
                msg['is_read'] = true;
              }
            }
          });
          return;
        }
        if (mounted) {
          setState(() {
            _messages.add(decoded);
            _isConnected = true;
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
        setState(() => _isConnected = false);
      },
      onDone: () {
        setState(() => _isConnected = false);
      },
    );
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _channel == null) return;

    HapticFeedback.lightImpact();

    final messageData = {'text': text};
    _channel!.sink.add(jsonEncode(messageData));
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _loadRecipientInfo() async {
    // Получаем инфо о собеседнике
    setState(() {
      _recipientAvatar = widget.chatAvatar;
      _recipientName = widget.chatName;
    });
  }

  void _markAsRead() {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({"type": "read"}));
    }
  }

  Future<void> _pickAndSendImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    HapticFeedback.selectionClick();

    try {
      final imageUrl = await _apiService.uploadFile(image);
      final messageData = {'text': '', 'image': imageUrl};
      _channel?.sink.add(jsonEncode(messageData));
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Ошибка загрузки фото'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _onDoubleTapMessage(int index) {
    HapticFeedback.mediumImpact();
    // TODO: Add reaction to message
  }

  void _onLongPressMessage(int index) {
    HapticFeedback.heavyImpact();
    _showMessageOptions(index);
  }

  void _showMessageOptions(int index) {
    final message = _messages[index];
    final isMe = message['username'] == _myUsername;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            _MessageOption(
              icon: Icons.reply_rounded,
              title: 'Ответить',
              onTap: () {
                Navigator.pop(context);
                // TODO: Reply
              },
            ),
            _MessageOption(
              icon: Icons.content_copy_rounded,
              title: 'Копировать',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message['text'] ?? ''));
                Navigator.pop(context);
                HapticFeedback.selectionClick();
              },
            ),
            _MessageOption(
              icon: Icons.forward_rounded,
              title: 'Переслать',
              onTap: () {
                Navigator.pop(context);
                // TODO: Forward
              },
            ),
            if (isMe)
              _MessageOption(
                icon: Icons.delete_outline_rounded,
                title: 'Удалить',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Delete
                },
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  // Background decoration
                  _buildBackground(),

                  // Messages
                  _buildMessageList(),

                  // Scroll to bottom button
                  if (_showScrollButton) _buildScrollButton(),

                  // Typing indicator
                  if (_isTyping)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: TypingIndicator(username: widget.chatName),
                    ),
                ],
              ),
            ),
            ChatInputField(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _sendMessage,
              onAttach: _pickAndSendImage,
              token: widget.token,
              chatId: widget.chatId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (widget.onBack != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onBack!();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          if (widget.onBack != null) const SizedBox(width: 12),

          // Avatar
          GestureDetector(
            onTap: () {
              // TODO: Open user profile
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(15),
                boxShadow: AppColors.primaryShadow(0.2),
              ),
              child: widget.chatAvatar != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        widget.chatAvatar!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.chatName.isNotEmpty
                            ? widget.chatName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppColors.online
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                        boxShadow: _isConnected
                            ? [
                                BoxShadow(
                                  color: AppColors.online.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isConnected ? 'онлайн' : 'не в сети',
                      style: TextStyle(
                        color: _isConnected
                            ? AppColors.online
                            : AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              _AppBarButton(
                icon: Icons.videocam_rounded,
                onTap: () {
                  // TODO: Video call
                },
              ),
              const SizedBox(width: 8),
              _AppBarButton(
                icon: Icons.more_vert_rounded,
                onTap: () {
                  // TODO: More options
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF08080C)],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Начните общение 👋',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg['username'] == _myUsername;

        // Check if we should show date separator
        final showDateSeparator = _shouldShowDateSeparator(index);

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(msg['time']),
            MessageBubble(
              message: msg,
              isMe: isMe,
              recipientAvatar: isMe ? _recipientAvatar : null,
              recipientName: isMe ? _recipientName : null,
              onDoubleTap: () => _onDoubleTapMessage(index),
              onLongPress: () => _onLongPressMessage(index),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    // TODO: Compare dates properly
    return false;
  }

  Widget _buildDateSeparator(String? time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.surfaceLight.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Сегодня', // TODO: Format date properly
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.surfaceLight.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _scrollToBottom();
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.primaryShadow(0.4),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}

class _MessageOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MessageOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.error.withOpacity(0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
