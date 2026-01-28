import 'dart:math';
import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';

class RpsScreen extends StatefulWidget {
  final String token;
  final int chatId;

  const RpsScreen({
    super.key,
    required this.token,
    required this.chatId,
  });

  @override
  State<RpsScreen> createState() => _RpsScreenState();
}

class _RpsScreenState extends State<RpsScreen> with TickerProviderStateMixin {
  String? _myChoice;
  String? _opponentChoice;
  String? _result;
  bool _isPlaying = false;
  int _myScore = 0;
  int _opponentScore = 0;

  final Map<String, String> _choices = {
    'rock': '🪨',
    'paper': '📄',
    'scissors': '✂️',
  };

  final Map<String, String> _names = {
    'rock': 'Камень',
    'paper': 'Бумага',
    'scissors': 'Ножницы',
  };

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  void _play(String choice) async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _myChoice = choice;
      _opponentChoice = null;
      _result = null;
    });

    // Анимация
    for (int i = 0; i < 3; i++) {
      _shakeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _shakeController.reverse();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Выбор противника (пока рандом, потом можно сделать мультиплеер)
    final random = Random();
    final opponentChoice = _choices.keys.elementAt(random.nextInt(3));

    setState(() {
      _opponentChoice = opponentChoice;
      _result = _getResult(choice, opponentChoice);
      _isPlaying = false;

      if (_result == 'win') {
        _myScore++;
      } else if (_result == 'lose') {
        _opponentScore++;
      }
    });
  }

  String _getResult(String my, String opponent) {
    if (my == opponent) return 'draw';

    if ((my == 'rock' && opponent == 'scissors') ||
        (my == 'paper' && opponent == 'rock') ||
        (my == 'scissors' && opponent == 'paper')) {
      return 'win';
    }

    return 'lose';
  }

  void _reset() {
    setState(() {
      _myChoice = null;
      _opponentChoice = null;
      _result = null;
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('✊ Камень-ножницы-бумага'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Счёт
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreCard('Ты', _myScore, AppColors.primary),
                const Text(
                  ':',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildScoreCard('Соперник', _opponentScore, AppColors.error),
              ],
            ),
          ),

          // Игровое поле
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Противник
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _isPlaying ? sin(_shakeAnimation.value) * 5 : 0,
                        0,
                      ),
                      child: _buildChoiceDisplay(
                        _opponentChoice,
                        'Соперник',
                        isTop: true,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Результат
                if (_result != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getResultColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getResultColor()),
                    ),
                    child: Text(
                      _getResultText(),
                      style: TextStyle(
                        color: _getResultColor(),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Мой выбор
                _buildChoiceDisplay(
                  _myChoice,
                  'Ты',
                  isTop: false,
                ),
              ],
            ),
          ),

          // Кнопки выбора
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                if (_result != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: _reset,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Center(
                          child: Text(
                            'Ещё раз',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _choices.entries.map((entry) {
                    final isSelected = _myChoice == entry.key;
                    return GestureDetector(
                      onTap: _result == null ? () => _play(entry.key) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry.value,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _names[entry.key]!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceDisplay(String? choice, String label, {required bool isTop}) {
    return Column(
      children: [
        if (!isTop)
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: choice != null
                  ? AppColors.primary
                  : AppColors.surfaceLight,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              choice != null ? _choices[choice]! : '❓',
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isTop)
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Color _getResultColor() {
    switch (_result) {
      case 'win':
        return AppColors.online;
      case 'lose':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getResultText() {
    switch (_result) {
      case 'win':
        return '🎉 Победа!';
      case 'lose':
        return '😔 Поражение';
      default:
        return '🤝 Ничья';
    }
  }
}