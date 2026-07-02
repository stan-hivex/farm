/// Color Management Utility for App-Wide Theming
/// This file provides centralized methods for all UI color decisions
/// All hardcoded Colors.* references should be replaced with these methods

import 'package:flutter/material.dart';
import 'theme_extensions.dart';

class ColorManager {
  /// === TEXT COLORS ===
  
  static Color textPrimary(BuildContext context) => context.textPrimary;
  static Color textSecondary(BuildContext context) => context.textSecondary;
  static Color textTertiary(BuildContext context) => context.textTertiary;
  
  /// Adaptive text - white in dark mode, black in light mode
  static Color textAdaptive(BuildContext context) {
    return context.isDarkMode ? Colors.white : Colors.black;
  }
  
  /// === BACKGROUND & SURFACE COLORS ===
  
  static Color background(BuildContext context) => context.background;
  static Color surface(BuildContext context) => context.surface;
  static Color surfaceVariant(BuildContext context) {
    return context.isDarkMode
        ? const Color(0xFF263238)
        : const Color(0xFFF5F5F5);
  }
  
  /// === BORDER & DIVIDER COLORS ===
  
  static Color border(BuildContext context) => context.borderColor;
  static Color divider(BuildContext context) => context.dividerColor;
  static Color shadow(BuildContext context) {
    return context.isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
  }
  
  /// === STATUS COLORS ===
  
  static Color success(BuildContext context) => context.successColor;
  static Color error(BuildContext context) => context.errorColor;
  static Color warning(BuildContext context) => context.warningColor;
  static Color info(BuildContext context) => context.infoColor;
  
  /// === SEMANTIC COLORS ===
  
  static Color pending(BuildContext context) => context.warningColor;
  static Color completed(BuildContext context) => context.successColor;
  static Color failed(BuildContext context) => context.errorColor;
  static Color inProgress(BuildContext context) => context.infoColor;
  
  /// === BUTTON COLORS ===
  
  static Color buttonBackground(BuildContext context) => context.primaryColor;
  static Color buttonForeground(BuildContext context) => context.background;
  
  static Color outlinedButtonBorder(BuildContext context) => context.borderColor;
  static Color outlinedButtonText(BuildContext context) => context.textPrimary;
  
  /// === INPUT FIELD COLORS ===
  
  static Color inputBackground(BuildContext context) => context.surface;
  static Color inputBorder(BuildContext context) => context.borderColor;
  static Color inputFocusedBorder(BuildContext context) => context.primaryColor;
  static Color inputText(BuildContext context) => context.textPrimary;
  static Color inputHint(BuildContext context) => context.textTertiary;
  
  /// === ICON COLORS ===
  
  static Color iconPrimary(BuildContext context) => context.textPrimary;
  static Color iconSecondary(BuildContext context) => context.textSecondary;
  static Color iconActive(BuildContext context) => context.primaryColor;
  static Color iconDisabled(BuildContext context) => context.textTertiary;
  
  /// === NAVIGATION COLORS ===
  
  static Color navBarBackground(BuildContext context) => context.surface;
  static Color navBarSelected(BuildContext context) => context.primaryColor;
  static Color navBarUnselected(BuildContext context) => context.textTertiary;
  
  static Color appBarBackground(BuildContext context) => context.surface;
  static Color appBarText(BuildContext context) => context.textPrimary;
  static Color appBarIcon(BuildContext context) => context.textPrimary;
  
  /// === CARD & CONTAINER COLORS ===
  
  static Color cardBackground(BuildContext context) => context.surface;
  static Color cardBorder(BuildContext context) => context.borderColor;
  static Color cardShadow(BuildContext context) {
    return context.isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.grey.withOpacity(0.1);
  }
  
  /// === DIALOG & SHEET COLORS ===
  
  static Color dialogBackground(BuildContext context) => context.surface;
  static Color dialogText(BuildContext context) => context.textPrimary;
  static Color barrierColor(BuildContext context) {
    return context.isDarkMode
        ? Colors.black.withOpacity(0.5)
        : Colors.black.withOpacity(0.3);
  }
  
  /// === CHIP & TAG COLORS ===
  
  static Color chipBackground(BuildContext context) => context.surface;
  static Color chipText(BuildContext context) => context.textPrimary;
  static Color chipBorder(BuildContext context) => context.borderColor;
  
  static Color tagBackground(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'success':
      case 'completed':
        return context.isDarkMode
            ? const Color(0xFF1B5E20).withOpacity(0.3)
            : const Color(0xFFC8E6C9);
      case 'error':
      case 'failed':
        return context.isDarkMode
            ? const Color(0xFFB71C1C).withOpacity(0.3)
            : const Color(0xFFFFCDD2);
      case 'warning':
      case 'pending':
        return context.isDarkMode
            ? const Color(0xFFF57F17).withOpacity(0.3)
            : const Color(0xFFFFE0B2);
      case 'info':
      default:
        return context.isDarkMode
            ? const Color(0xFF01579B).withOpacity(0.3)
            : const Color(0xFFB3E5FC);
    }
  }
  
  static Color tagText(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'success':
      case 'completed':
        return context.isDarkMode ? Colors.lightGreen : Colors.green[700]!;
      case 'error':
      case 'failed':
        return context.isDarkMode ? Colors.redAccent : Colors.red[700]!;
      case 'warning':
      case 'pending':
        return context.isDarkMode ? Colors.amber : Colors.orange[700]!;
      case 'info':
      default:
        return context.isDarkMode ? Colors.lightBlue : Colors.blue[700]!;
    }
  }
  
  /// === PROGRESS INDICATOR COLORS ===
  
  static Color progressBar(BuildContext context) => context.primaryColor;
  static Color progressBarBackground(BuildContext context) => context.borderColor;
  
  /// === SHIMMER & LOADING COLORS ===
  
  static Color shimmerBase(BuildContext context) {
    return context.isDarkMode
        ? const Color(0xFF263238).withOpacity(0.5)
        : Colors.grey[300]!;
  }
  
  static Color shimmerHighlight(BuildContext context) {
    return context.isDarkMode
        ? const Color(0xFF455A64).withOpacity(0.5)
        : Colors.grey[100]!;
  }
  
  /// === BADGE & NOTIFICATION COLORS ===
  
  static Color badgeBackground(BuildContext context) => context.errorColor;
  static Color badgeText(BuildContext context) => context.background;
  
  /// === TRANSACTION SPECIFIC ===
  
  static Color transactionIn(BuildContext context) => context.successColor;
  static Color transactionOut(BuildContext context) => context.errorColor;
  static Color transactionPending(BuildContext context) => context.warningColor;
}
