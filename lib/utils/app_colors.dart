import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Updated to match design)
  static const Color primary = Color(0xFF9E77F7); // Purple
  static const Color primaryDark = Color(0xFF7A52DB);
  static const Color accent = Color(0xFFF59E0B);

  // Backgrounds & Surfaces
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color background = surface;

  // Typography
  static const Color textPrimary = Color(0xFF1F2937); // Dark Gray
  static const Color textSecondary = Color(0xFF6B7280); // Gray

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = accent;
  static const Color info = primary;
  
  // Borders & Dividers
  static const Color borderColor = Color(0xFFE5E7EB);

  // Tags
  static const Color tagLostBg = Color(0xFFFFEDED);
  static const Color tagLostText = danger;
  static const Color tagFoundBg = Color(0xFFECFDF5);
  static const Color tagFoundText = success;
  static const Color tagResolvedBg = Color(0xFFF1F5F9);
  static const Color tagResolvedText = Color(0xFF475569);
}
