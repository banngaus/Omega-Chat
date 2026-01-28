import 'dart:math';
import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/games/game_service.dart';

class DiceScreen extends StatefulWidget {
  final String token;
  final int chatId;

  const DiceScreen({
    super.key,
    required this.token,
    required this.chatId,
  });

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  
  int? _sessionId;
  int? _myResult;
  bool _isRolling = false;
  List<Map<String, dynamic>> _results = [];
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final List<String> _diceFaces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _createGame();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _createGame() async {
    try {
      final result = await _gameService.createGame(
        token: widget.token,
        gameType: 'dice',
        chatId: widget.chatId,
      );
      setState(() {
        _sessionId = result['id'];
      });
    } catch (e) {
      debugPrint('Error creating game: $e');
    }
  }

  Future<void> _rollDice() async {
    if (_isRolling || _sessionId == null) return;

    setState(() => _isRolling = true);
    
    // Анимация
    _animationController.repeat();
    
    // Имитация броска
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      final result = await _gameService.gameAction(
        token: widget.token,
        sessionId: _sessionId!,
        action: 'roll',
      );
      
      _animationController.stop();
      _animationController.reset();
      
      setState(() {
        _myResult = result['result'];
        _results.add({
          'user': result['user'],
          'result': result['result'],
        });
        _isRolling = false;
      });
    } catch (e) {
      _animationController.stop();
      _animationController.reset();
      setState(() => _isRolling = false);
      
      // Fallback на локальный бросок
      setState(() {
        _myResult = Random().nextInt(6) + 1;
        _results.add({
          'user': 'Ты',
          'result': _myResult,
        });
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🎲 Кости'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Основная область
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Кубик
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRolling ? _scaleAnimation.value : 1.0,
                        child: Transform.rotate(
                          angle: _isRolling ? _rotationAnimation.value : 0,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _myResult != null 
                                    ? _diceFaces[_myResult! - 1]
                                    : '🎲',
                                style: const TextStyle(fontSize: 64),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Результат
                  if (_myResult != null)
                    Text(
                      'Выпало: $_myResult',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Кнопка броска
                  GestureDetector(
                    onTap: _rollDice,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _isRolling 
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
                      child: Text(
                        _isRolling ? 'Бросаем...' : '🎲 Бросить',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // История бросков
          if (_results.isNotEmpty)
            Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'История бросков',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[_results.length - 1 - index];
                        final isMax = result['result'] == 6;
                        
                        return Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isMax 
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: isMax
                                ? Border.all(color: AppColors.primary)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _diceFaces[result['result'] - 1],
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${result['result']}',
                                style: TextStyle(
                                  color: isMax 
                                      ? AppColors.primary 
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}