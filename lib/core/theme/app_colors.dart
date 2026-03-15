import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // macOS Accent
  static const Color accent = Color(0xFF0A84FF);
  static const Color accentHover = Color(0xFF409CFF);
  static const Color accentLight = Color(0xFF142A3E);

  // Surfaces — macOS dark mode
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF2D2D2D);
  static const Color surfaceSecondary = Color(0xFF383838);
  static const Color toolbar = Color(0xFF2A2A2A);

  // Text — Apple HIG dark
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF98989D);
  static const Color textTertiary = Color(0xFF636366);

  // Borders & Separators — subtle dark lines
  static const Color separator = Color(0xFF3A3A3C);
  static const Color separatorLight = Color(0xFF333335);
  static const Color border = Color(0xFF48484A);

  // Status — brighter for dark backgrounds
  static const Color success = Color(0xFF30D158);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color info = Color(0xFF64D2FF);

  // Legacy aliases
  static const Color primary = accent;
  static const Color primaryLight = accentLight;
  static const Color primaryDark = Color(0xFF0060C0);
  static const Color secondary = Color(0xFF5E5CE6);
  static const Color cardBackground = surface;
  static const Color textHint = textTertiary;
  static const Color divider = separator;
  static const Color surfaceVariant = surfaceSecondary;
  static const Color sidebarBg = Color(0xFF252525);
  static const Color sidebarText = textPrimary;
  static const Color sidebarActiveItem = accentLight;
  static const Color secondaryLight = Color(0xFF7A79E0);
}
