import 'package:flutter/material.dart';

class AppColors {
  // ============ ФОНЫ ============
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceLight = Color(0xFF1E1E2A);
  static const Color card = Color(0xFF16161F);

  // ============ АКЦЕНТЫ ============
  // Основной градиент
  static const Color primaryStart = Color(0xFF667EEA);
  static const Color primaryEnd = Color(0xFF764BA2);
  static const Color primary = Color(0xFF7C5CFF);

  // Вторичный градиент (для кнопок)
  static const Color secondaryStart = Color(0xFF11998E);
  static const Color secondaryEnd = Color(0xFF38EF7D);

  // Акцентный (для важного)
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentSoft = Color(0xFFFFE66D);

  // ============ ТЕКСТ ============
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color textMuted = Color(0xFF5A5A6A);

  // ============ СООБЩЕНИЯ ============
  static const Color myMessageStart = Color(0xFF667EEA);
  static const Color myMessageEnd = Color(0xFF764BA2);
  static const Color otherMessage = Color(0xFF1E1E2A);

  // ============ СТАТУСЫ ============
  static const Color online = Color(0xFF4ADE80);
  static const Color offline = Color(0xFF6B7280);
  static const Color typing = Color(0xFF60A5FA);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // ============ ГРАДИЕНТЫ ============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryStart, secondaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get messageGradient => const LinearGradient(
    colors: [myMessageStart, myMessageEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ ТЕНИ ============
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> primaryShadow(double opacity) => [
    BoxShadow(
      color: primary.withOpacity(opacity),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}