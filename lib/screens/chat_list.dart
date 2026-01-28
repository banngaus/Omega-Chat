import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/services/api_service.dart';
import 'package:omega_chat/screens/chat_tile.dart';

class ChatList extends StatefulWidget {
  final String token;
  final int? selectedChatId;
  final Function(int chatId, String name, String? avatar) onChatSelected;

  const ChatList({
    super.key,
    required this.token,
    required this.selectedChatId,
    required this.onChatSelected,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _apiService.getDirectChats(widget.token);
      setState(() {
        _chats = List<Map<String, dynamic>>.from(chats);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading chats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Пока нет чатов',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажмите ✏️ чтобы начать',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final isSelected = widget.selectedChatId == chat['id'];

          return ChatTile(
            chat: chat,
            isSelected: isSelected,
            onTap: () {
              widget.onChatSelected(
                chat['id'],
                chat['name'] ?? chat['username'] ?? 'Чат',
                chat['avatar_url'],
              );
            },
          );
        },
      ),
    );
  }
}