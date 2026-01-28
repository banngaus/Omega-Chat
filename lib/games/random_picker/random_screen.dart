import 'dart:math';
import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';

class RandomScreen extends StatefulWidget {
  final String token;
  final int chatId;

  const RandomScreen({
    super.key,
    required this.token,
    required this.chatId,
  });

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _participants = [];
  String? _winner;
  bool _isPicking = false;
  int _currentIndex = 0;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  void _addParticipant() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && !_participants.contains(name)) {
      setState(() {
        _participants.add(name);
        _nameController.clear();
      });
    }
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
      _winner = null;
    });
  }

  Future<void> _pickRandom() async {
    if (_isPicking || _participants.length < 2) return;

    setState(() {
      _isPicking = true;
      _winner = null;
    });

    final random = Random();
    final winnerIndex = random.nextInt(_participants.length);

    // Анимация перебора
    for (int i = 0; i < 20 + winnerIndex; i++) {
      await Future.delayed(Duration(milliseconds: 50 + i * 10));
      setState(() {
        _currentIndex = i % _participants.length;
      });
    }

    setState(() {
      _winner = _participants[winnerIndex];
      _isPicking = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🎯 Рандомайзер'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Результат
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_winner != null) ...[
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Выбран:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Text(
                        _winner!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (_participants.isEmpty) ...[
                    const Text(
                      '🎯',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Добавьте участников',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ] else if (_isPicking) ...[
                    const Text(
                      '🎲',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _participants[_currentIndex],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '👇',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Нажмите "Выбрать"',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Список участников
          if (_participants.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final isHighlighted = _isPicking && _currentIndex == index;
                  final isWinner = _winner == _participants[index];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isWinner
                          ? AppColors.primary
                          : isHighlighted
                              ? AppColors.primary.withOpacity(0.5)
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isWinner || isHighlighted
                            ? AppColors.primary
                            : AppColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: isWinner || isHighlighted
                                    ? Colors.white.withOpacity(0.2)
                                    : AppColors.surfaceLight,
                                child: Text(
                                  _participants[index][0].toUpperCase(),
                                  style: TextStyle(
                                    color: isWinner || isHighlighted
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _participants[index].length > 8
                                    ? '${_participants[index].substring(0, 8)}...'
                                    : _participants[index],
                                style: TextStyle(
                                  color: isWinner || isHighlighted
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        // Кнопка удаления
                        if (!_isPicking)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeParticipant(index),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Кнопка выбора
          if (_participants.length >= 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _pickRandom,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isPicking
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isPicking ? 'Выбираем...' : '🎯 Выбрать случайно',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Ввод участника
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Имя участника...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _addParticipant(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addParticipant,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}