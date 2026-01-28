import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/games/game_service.dart';
import 'package:omega_chat/games/dice/dice_screen.dart';
import 'package:omega_chat/games/wheel/wheel_screen.dart';
import 'package:omega_chat/games/rps/rps_screen.dart';
import 'package:omega_chat/games/random_picker/random_screen.dart';

class GameMenu extends StatelessWidget {
  final String token;
  final int chatId;
  final bool isGroup;

  const GameMenu({
    super.key,
    required this.token,
    required this.chatId,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Заголовок
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Выбери игру',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Простые игры
          _buildSection('Быстрые игры'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _GameCard(
                    icon: '🎲',
                    title: 'Кости',
                    onTap: () => _openGame(context, 'dice'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GameCard(
                    icon: '🎡',
                    title: 'Колесо',
                    onTap: () => _openGame(context, 'wheel'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _GameCard(
                    icon: '✊',
                    title: 'КНБ',
                    onTap: () => _openGame(context, 'rps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GameCard(
                    icon: '🎯',
                    title: 'Рандом',
                    onTap: () => _openGame(context, 'random'),
                  ),
                ),
              ],
            ),
          ),
          
          // Словесные игры
          const SizedBox(height: 16),
          _buildSection('Словесные игры'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _GameCard(
                    icon: '🎭',
                    title: 'Кто я?',
                    onTap: () => _showComingSoon(context),
                    comingSoon: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GameCard(
                    icon: '📢',
                    title: 'Alias',
                    onTap: () => _showComingSoon(context),
                    comingSoon: true,
                  ),
                ),
              ],
            ),
          ),
          
          // Командные игры
          const SizedBox(height: 16),
          _buildSection('Командные игры'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GameCard(
              icon: '🕵️',
              title: 'Codenames',
              onTap: () => _showComingSoon(context),
              comingSoon: true,
              fullWidth: true,
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _openGame(BuildContext context, String gameType) {
    Navigator.pop(context); // Закрываем меню
    
    Widget screen;
    switch (gameType) {
      case 'dice':
        screen = DiceScreen(token: token, chatId: chatId);
        break;
      case 'wheel':
        screen = WheelScreen(token: token, chatId: chatId);
        break;
      case 'rps':
        screen = RpsScreen(token: token, chatId: chatId);
        break;
      case 'random':
        screen = RandomScreen(token: token, chatId: chatId);
        break;
      default:
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚧 Скоро будет!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  final bool comingSoon;
  final bool fullWidth;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.comingSoon = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: comingSoon 
                ? Colors.white.withOpacity(0.05)
                : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: comingSoon 
                    ? AppColors.textSecondary 
                    : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (comingSoon) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'скоро',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}