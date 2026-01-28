import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/services/api_service.dart';
import 'package:omega_chat/services/storage_service.dart';
import 'package:omega_chat/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _username = 'User';
  String _email = '';
  String? _avatarUrl;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final userData = await _apiService.getMe(widget.token);
      setState(() {
        _username = userData['username'] ?? 'User';
        _email = userData['email'] ?? '';
        if (userData['avatar_url'] != null) {
          _avatarUrl = userData['avatar_url'].toString().startsWith('http')
              ? userData['avatar_url']
              : ApiService.baseUrl + userData['avatar_url'];
        }
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      try {
        final decoded = JwtDecoder.decode(widget.token);
        setState(() => _username = decoded['username'] ?? 'User');
      } catch (_) {}
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploadingAvatar = true);
    HapticFeedback.selectionClick();

    try {
      final url = await _apiService.uploadFile(image);
      await _apiService.updateAvatar(widget.token, url);
      setState(() => _avatarUrl = url);

      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSnackbar('Аватар обновлён', isError: false);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnackbar('Ошибка загрузки', isError: true);
      }
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _LogoutDialog(),
    );

    if (result == true && mounted) {
      await _storageService.clearToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Header
                _buildHeader(),

                const SizedBox(height: 40),

                // Avatar
                _buildAvatar(),

                const SizedBox(height: 24),

                // Name & Email
                _buildUserInfo(),

                const SizedBox(height: 40),

                // Menu sections
                _buildMenuSections(),

                const SizedBox(height: 24),

                // Logout
                _buildLogoutButton(),

                const SizedBox(height: 32),

                // Version
                Text(
                  'Omega v1.0.0 (Beta)',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
        const SizedBox(width: 16),
        const Text(
          'Профиль',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _changeAvatar,
      child: Stack(
        children: [
          // Avatar container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(36),
              boxShadow: AppColors.glowShadow,
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(32),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: _isUploadingAvatar
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : _avatarUrl != null
                    ? Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        width: 112,
                        height: 112,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
            ),
          ),

          // Camera button
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.background, width: 3),
                boxShadow: AppColors.primaryShadow(0.4),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        _username.isNotEmpty ? _username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          _username,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        if (_email.isNotEmpty)
          Text(
            _email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 12),

        // Online badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'В сети',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account section
        _buildSectionTitle('АККАУНТ'),
        _buildMenuGroup([
          _MenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Редактировать профиль',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Безопасность',
            onTap: () {},
          ),
        ]),

        const SizedBox(height: 28),

        // Settings section
        _buildSectionTitle('НАСТРОЙКИ'),
        _buildMenuGroup([
          _MenuItem(
            icon: Icons.palette_outlined,
            title: 'Тема',
            subtitle: 'Тёмная',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.language_rounded,
            title: 'Язык',
            subtitle: 'Русский',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.storage_outlined,
            title: 'Данные и хранилище',
            onTap: () {},
          ),
        ]),

        const SizedBox(height: 28),

        // Game stats section
        _buildSectionTitle('ИГРЫ'),
        _buildMenuGroup([
          _MenuItem(
            icon: Icons.emoji_events_outlined,
            title: 'Статистика',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.history_rounded,
            title: 'История игр',
            onTap: () {},
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              _buildMenuItemWidget(item),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(
                    height: 1,
                    color: AppColors.surfaceLight.withOpacity(0.5),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItemWidget(_MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 12),
            Text(
              'Выйти из аккаунта',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

class _LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Выйти из аккаунта?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Вам нужно будет войти снова',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Выйти',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
