import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/screens/register_screen.dart';
import 'package:omega_chat/screens/main_layout.dart';
import 'package:omega_chat/services/api_service.dart';
import 'package:omega_chat/services/storage_service.dart';
import 'package:omega_chat/widgets/animated_button.dart';
import 'package:omega_chat/widgets/animated_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _storageService = StorageService();

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController!.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void _clearErrors() {
    _safeSetState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  bool _validate() {
    _clearErrors();
    bool isValid = true;

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
    }

    return isValid;
  }

  Future<void> _login() async {
    if (!_validate()) return;

    _safeSetState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final token = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      await _storageService.saveToken(token);

      if (mounted && !_isDisposed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MainLayout(token: token),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _safeSetState(() {
        _passwordError = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: SlideTransition(
                    position: _slideAnimation!,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildForm(),
                      ],
                    ),
                  ),
                ),
              ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0F),
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
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryStart.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryEnd.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.glowShadow,
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'OMEGA',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Добро пожаловать',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
          const Text(
            'Вход',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Введите данные для входа',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          AnimatedTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'example@mail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),
          const SizedBox(height: 20),

          AnimatedTextField(
            controller: _passwordController,
            label: 'Пароль',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            errorText: _passwordError,
          ),
          const SizedBox(height: 32),

          AnimatedButton(
            text: 'Войти',
            icon: Icons.arrow_forward_rounded,
            onPressed: _login,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Нет аккаунта? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Создать',
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