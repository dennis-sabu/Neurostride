import 'package:flutter/material.dart';

class AppColors {
  // ── NuroStride "Modern Calm" Palette ────────────────────────────────
  /// Frosted Mint — calm off-white background base
  static const Color background = Color(0xFFF2F5F9);

  // White Glass Surfaces
  static const Color surface = Color(0xFFFFFFFF);

  // Soft Indigo — Primary Actions (legacy)
  static const Color primary = Color(0xFF5E5CE6);
  static const Color primaryLight = Color(0xFF7D7CFF);

  /// Serene Sage — progress rings, secondary highlights
  static const Color sereneSage = Color(0xFF789D8E);

  /// Deep Teal — primary action buttons ("Next", "Start Session")
  static const Color deepTeal = Color(0xFF2D5D62);

  /// Deep Charcoal — high-readability header text
  static const Color deepCharcoal = Color(0xFF1A202C);

  /// Hero title color
  static const Color heroTitle = Color(0xFF0F172A);

  // Success / Goals (Emerald / Sage)
  static const Color accent = Color(0xFF10B981);
  static const Color success = Color(0xFF10B981);

  // Error / Warning (Rose) — used for critical alerts
  static const Color warning = Color(0xFFF43F5E);

  // Moderate-state indicator amber — avoids clash with rose `warning`
  static const Color warningAmber = Color(0xFFF59E0B);

  // Subtle border / Glass stroke
  static const Color greyLight = Color(0xFFE2E8F0); // Slate 200

  // Secondary text (Slate 500)
  static const Color greyText = Color(0xFF64748B);

  // Near-black primary text (Slate 900)
  static const Color textPrimary = Color(0xFF0F172A);
}
