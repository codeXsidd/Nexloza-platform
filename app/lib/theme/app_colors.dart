import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondaryDark = Color(0xFF0284C7);
  static const Color secondaryLight = Color(0xFF38BDF8);

  static const Color tertiary = Color(0xFF8B5CF6);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF16A34A);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // Device status
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color deviceWarning = Color(0xFFF59E0B);

  // Alarm severity
  static const Color alarmCritical = Color(0xFFEF4444);
  static const Color alarmHigh = Color(0xFFF97316);
  static const Color alarmMedium = Color(0xFFF59E0B);
  static const Color alarmWarning = Color(0xFFEAB308);
  static const Color alarmInfo = Color(0xFF3B82F6);

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color disabledLight = Color(0xFFCBD5E1);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceElevatedDark = Color(0xFF334155);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color dividerDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color disabledDark = Color(0xFF475569);
}
