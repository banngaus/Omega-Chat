import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omega_chat/theme/app_colors.dart';
import 'package:omega_chat/services/api_service.dart';
import 'package:omega_chat/screens/chat_screen.dart';
import 'package:omega_chat/screens/profile_screen.dart';
import 'package:omega_chat/screens/chat_list.dart';

class MainLayout extends StatefulWidget {
  final String token;

  const MainLayout({super.key, required this.token});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  final _apiService = ApiService();

  int? _selectedChatId;
  String _selectedChatName = '';
  String? _selectedChatAvatar;

  String? _myAvatarUrl;
  String _myUsername = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadMyProfile();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyProfile() async {
    try {
      final me = await _apiService.getMe(widget.token);
      setState(() {
        _myUsername = me['username'] ?? '';
        if (me['avatar_url'] != null) {
          _myAvatarUrl = me['avatar_url'].toString().startsWith('http')
              ? me['avatar_url']
              : ApiService.baseUrl + me['avatar_url'];
        }
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  void _onChatSelected(int chatId, String name, String? avatar) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChatId = chatId;
      _selectedChatName = name;
      _selectedChatAvatar = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(
                color: AppColors.surfaceLight.withOpacity(0.3),
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ChatList(
                  token: widget.token,
                  selectedChatId: _selectedChatId,
                  onChatSelected: _onChatSelected,
                ),
              ),
              _buildProfileBar(),
            ],
          ),
        ),

        // Chat area
        Expanded(
          child: _selectedChatId != null
              ? ChatScreen(
                  key: ValueKey(_selectedChatId),
                  token: widget.token,
                  chatId: _selectedChatId!,
                  chatName: _selectedChatName,
                  chatAvatar: _selectedChatAvatar,
                )
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _selectedChatId != null
        ? ChatScreen(
            key: ValueKey(_selectedChatId),
            token: widget.token,
            chatId: _selectedChatId!,
            chatName: _selectedChatName,
            chatAvatar: _selectedChatAvatar,
            onBack: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedChatId = null);
            },
          )
        : Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ChatList(
                  token: widget.token,
                  selectedChatId: _selectedChatId,
                  onChatSelected: _onChatSelected,
                ),
              ),
              _buildProfileBar(),
            ],
          );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            AppColors.surface.withOpacity(0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Text(
              'Чаты',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),

          // Search
          _HeaderButton(
            icon: Icons.search_rounded,
            onTap: () {
              // TODO: search
            },
          ),
          const SizedBox(width: 8),

          // New chat
          _HeaderButton(
            icon: Icons.edit_rounded,
            isPrimary: true,
            onTap: () => _showNewChatDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBar() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProfileScreen(token: widget.token),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
        _loadMyProfile();
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceLight.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.primaryShadow(0.3),
              ),
              child: _myAvatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(_myAvatarUrl!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Text(
                        _myUsername.isNotEmpty ? _myUsername[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _myUsername.isNotEmpty ? _myUsername : 'Профиль',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'В сети',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Settings icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textMuted,
                size: 44,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Выберите чат',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Или начните новую переписку',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatDialog() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Новый чат',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Введите имя пользователя',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '@username',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Button
              GestureDetector(
                onTap: () async {
                  final username = controller.text.trim();
                  if (username.isEmpty) return;

                  Navigator.pop(context);
                  await _startNewChat(username);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.primaryShadow(0.4),
                  ),
                  child: const Center(
                    child: Text(
                      'Начать чат',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startNewChat(String username) async {
    try {
      final chat = await _apiService.createDirectChat(widget.token, username);

      setState(() {
        _selectedChatId = chat['id'];
        _selectedChatName = chat['name'] ?? username;
        _selectedChatAvatar = chat['avatar_url'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Пользователь не найден'),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isPrimary ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isPrimary ? AppColors.primaryShadow(0.3) : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}