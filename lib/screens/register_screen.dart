import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/services/api_service.dart';
import 'package:omega_chat/widgets/animated_button.dart';
import 'package:omega_chat/widgets/animated_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _apiService = ApiService();

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController!.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController?.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void _clearErrors() {
    _safeSetState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });
  }

  bool _validate() {
    _clearErrors();
    bool isValid = true;

    if (_usernameController.text.trim().isEmpty) {
      _safeSetState(() => _usernameError = 'Введите никнейм');
      isValid = false;
    } else if (_usernameController.text.trim().length < 3) {
      _safeSetState(() => _usernameError = 'Минимум 3 символа');
      isValid = false;
    }

    if (_emailController.text.trim().isEmpty) {
      _safeSetState(() => _emailError = 'Введите email');
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      _safeSetState(() => _emailError = 'Некорректный email');
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      _safeSetState(() => _passwordError = 'Введите пароль');
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      _safeSetState(() => _passwordError = 'Минимум 6 символов');
      isValid = false;
    }

    if (_confirmController.text != _passwordController.text) {
      _safeSetState(() => _confirmError = 'Пароли не совпадают');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _register() async {
    if (!_validate()) return;

    _safeSetState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await _apiService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted && !_isDisposed) {
        HapticFeedback.mediumImpact();
        _showSuccessDialog();
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      final error = e.toString().replaceAll('Exception:', '').trim();
      if (error.toLowerCase().contains('email')) {
        _safeSetState(() => _emailError = error);
      } else if (error.toLowerCase().contains('никнейм') ||
          error.toLowerCase().contains('username')) {
        _safeSetState(() => _usernameError = error);
      } else {
        _safeSetState(() => _passwordError = error);
      }
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    if (!mounted || _isDisposed) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryStart.withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Аккаунт создан!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Теперь вы можете войти',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              AnimatedButton(
                text: 'Войти',
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем что анимации инициализированы
    if (_fadeAnimation == null || _slideAnimation == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          _buildDecorations(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation!,
                        child: SlideTransition(
                          position: _slideAnimation!,
                          child: _buildForm(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF12121A),
            Color(0xFF0A0A0F),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryEnd.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryStart.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
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
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.surfaceLight.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Регистрация',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Создайте аккаунт',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Никнейм
          AnimatedTextField(
            controller: _usernameController,
            label: 'Никнейм',
            hint: 'ivan_dev',
            icon: Icons.alternate_email_rounded,
            errorText: _usernameError,
          ),
          const SizedBox(height: 20),

          // Email
          AnimatedTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'example@mail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),
          const SizedBox(height: 20),

          // Пароль
          AnimatedTextField(
            controller: _passwordController,
            label: 'Пароль',
            hint: 'Минимум 6 символов',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            errorText: _passwordError,
          ),
          const SizedBox(height: 20),

          // Подтверждение
          AnimatedTextField(
            controller: _confirmController,
            label: 'Подтвердите пароль',
            hint: 'Повторите пароль',
            icon: Icons.lock_rounded,
            isPassword: true,
            errorText: _confirmError,
          ),
          const SizedBox(height: 32),

          // Кнопка
          AnimatedButton(
            text: 'Создать аккаунт',
            icon: Icons.arrow_forward_rounded,
            onPressed: _register,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),

          // Вход
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Уже есть аккаунт? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Войти',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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