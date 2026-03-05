// lib/core/theme.dart
//
// Design tokens shared across the translate_call feature.
// In-call screens use the dark callBackground palette.
// List and form screens inherit Material 3 surface colours from the app theme.

import 'package:flutter/material.dart';

abstract final class AppTheme {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary    = Color(0xFF1A73E8);
  static const Color success    = Color(0xFF16A34A);
  static const Color warning    = Color(0xFFD97706);
  static const Color danger     = Color(0xFFDC2626);

  // ── In-call dark palette ──────────────────────────────────────────────────
  static const Color callBg         = Color(0xFF0A1628);
  static const Color callSurface    = Color(0xFF121F35);
  static const Color callBorder     = Color(0x1AFFFFFF); // white 10 %
  static const Color callTextPrimary   = Colors.white;
  static const Color callTextSecondary = Color(0x99FFFFFF); // white 60 %

  // ── Status badge colours ──────────────────────────────────────────────────
  static const Color statusActive   = Color(0xFF34D399); // emerald-400
  static const Color statusMissed   = Color(0xFFF87171); // red-400
  static const Color statusDeclined = Color(0xFFF87171);
  static const Color statusRinging  = Color(0xFFFBBF24); // amber-400

  // ── Animation durations ───────────────────────────────────────────────────
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow   = Duration(milliseconds: 400);

  // ── App-level MaterialApp theme ───────────────────────────────────────────
  static ThemeData light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  static ThemeData dark() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}

// ── In-call text styles (used by active / incoming / outgoing screens) ────────

extension CallTextStyles on TextTheme {
  TextStyle get callName => const TextStyle(
        color: AppTheme.callTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      );

  TextStyle get callStatus => const TextStyle(
        color: AppTheme.callTextSecondary,
        fontSize: 15,
      );

  TextStyle get callTimer => const TextStyle(
        color: AppTheme.callTextSecondary,
        fontSize: 14,
        fontFamily: 'monospace',
        letterSpacing: 1.2,
      );

  TextStyle get caption => const TextStyle(
        color: AppTheme.callTextPrimary,
        fontSize: 16,
        height: 1.5,
      );
}