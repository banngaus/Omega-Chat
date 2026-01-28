import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/games/game_menu.dart';

class GameButton extends StatelessWidget {
  final String token;
  final int chatId;
  final bool isGroup;

  const GameButton({
    super.key,
    required this.token,
    required this.chatId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showGameMenu(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.sports_esports_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  void _showGameMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GameMenu(
        token: token,
        chatId: chatId,
        isGroup: isGroup,
      ),
    );
  }
}