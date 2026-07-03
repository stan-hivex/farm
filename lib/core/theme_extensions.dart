import 'package:flutter/material.dart';
import 'app_theme.dart';

extension ThemeExtension on BuildContext {
  /// Get text color that adapts to current theme
  Color get textPrimary => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkTextPrimary
      : AppTheme.lightTextPrimary;

  Color get textSecondary => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkTextSecondary
      : AppTheme.lightTextSecondary;

  Color get textTertiary => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkTextTertiary
      : AppTheme.lightTextTertiary;

  /// Get background color that adapts to current theme
  Color get background => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkBackground
      : AppTheme.lightBackground;

  Color get surface => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkSurface
      : AppTheme.lightSurface;

  /// Get border color that adapts to current theme
  Color get borderColor => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkBorder
      : AppTheme.lightBorder;

  Color get dividerColor => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkDivider
      : AppTheme.lightDivider;

  Color get onBackground => Theme.of(this).colorScheme.onSurface;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;

  /// Get primary color (brand color)
  Color get primaryColor => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkPrimary
      : AppTheme.lightPrimary;

  Color get secondaryColor => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkSecondary
      : AppTheme.lightSecondary;

  /// Status colors (consistent across themes)
  Color get successColor => AppTheme.success;
  Color get errorColor => AppTheme.error;
  Color get warningColor => AppTheme.warning;
  Color get infoColor => AppTheme.info;
  Color get successColorAccent => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkSuccess.withOpacity(0.9)
      : AppTheme.success.withOpacity(0.9);
  Color get errorColorAccent => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkError.withOpacity(0.9)
      : AppTheme.error.withOpacity(0.9);
  Color get warningColorAccent => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkWarning.withOpacity(0.9)
      : AppTheme.warning.withOpacity(0.9);
  Color get infoColorAccent => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.darkInfo.withOpacity(0.9)
      : AppTheme.info.withOpacity(0.9);

  /// Check if dark mode is active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
