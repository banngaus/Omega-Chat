import 'dart:math';
import 'package:flutter/material.dart';
import 'package:omega_chat/theme/app_colors.dart';

class WheelScreen extends StatefulWidget {
  final String token;
  final int chatId;

  const WheelScreen({
    super.key,
    required this.token,
    required this.chatId,
  });

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _optionController = TextEditingController();
  final List<String> _options = [];
  String? _result;
  bool _isSpinning = false;

  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  final List<Color> _colors = [
    const Color(0xFF6366F1),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFF10B981),
    const Color(0xFFF43F5E),
    const Color(0xFF3B82F6),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _addOption() {
    final text = _optionController.text.trim();
    if (text.isNotEmpty && _options.length < 8) {
      setState(() {
        _options.add(text);
        _optionController.clear();
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  Future<void> _spin() async {
    if (_isSpinning || _options.length < 2) return;

    setState(() {
      _isSpinning = true;
      _result = null;
    });

    // Случайный результат
    final random = Random();
    final winnerIndex = random.nextInt(_options.length);
    
    // Вычисляем угол
    final baseRotations = 5; // Полных оборотов
    final segmentAngle = 2 * pi / _options.length;
    final targetAngle = baseRotations * 2 * pi + (winnerIndex * segmentAngle) + segmentAngle / 2;

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.reset();
    await _animationController.forward();

    setState(() {
      _result = _options[winnerIndex];
      _isSpinning = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('🎡 Колесо фортуны'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Колесо
          Expanded(
            flex: 3,
            child: Center(
              child: _options.length < 2
                  ? _buildEmptyState()
                  : _buildWheel(),
            ),
          ),

          // Результат
          if (_result != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    _result!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Кнопка крутить
          if (_options.length >= 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _spin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isSpinning
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _isSpinning ? 'Крутится...' : '🎡 Крутить!',
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

          // Ввод вариантов
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Варианты (${_options.length}/8)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Поле ввода
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _optionController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Добавить вариант...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _addOption(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addOption,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Список вариантов
                if (_options.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _colors[index % _colors.length].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _colors[index % _colors.length],
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _options[index],
                                style: TextStyle(
                                  color: _colors[index % _colors.length],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeOption(index),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: _colors[index % _colors.length],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '🎡',
          style: TextStyle(fontSize: 80),
        ),
        const SizedBox(height: 16),
        const Text(
          'Добавьте минимум 2 варианта',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildWheel() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Указатель
            const Text(
              '▼',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 32,
              ),
            ),
            
            // Колесо
            Transform.rotate(
              angle: -_rotationAnimation.value,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: WheelPainter(
                    options: _options,
                    colors: _colors,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> options;
  final List<Color> colors;

  WheelPainter({required this.options, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / options.length;

    for (int i = 0; i < options.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + i * segmentAngle,
        segmentAngle,
        true,
        paint,
      );

      // Текст
      final textAngle = -pi / 2 + i * segmentAngle + segmentAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i].length > 10 
              ? '${options[i].substring(0, 10)}...' 
              : options[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Центр
    canvas.drawCircle(
      center,
      20,
      Paint()..color = AppColors.surface,
    );
    canvas.drawCircle(
      center,
      18,
      Paint()..color = AppColors.background,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}