import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/color_constants.dart';

final ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  colorScheme: ColorScheme.fromSeed(
    seedColor: ColorConstants.seed,
    brightness: Brightness.light,
    surface: ColorConstants.scaffold,
  ),

  scaffoldBackgroundColor: ColorConstants.scaffold,

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ColorConstants.navBar,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? Colors.grey.shade900
            : Colors.grey.shade700,
      ),
    ),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 4,
    backgroundColor: ColorConstants.floatingActionButton,
    foregroundColor: Colors.black,
    shape: const CircleBorder(),
  ),

  cardTheme: CardThemeData(
    elevation: 4,
    color: Colors.white,
    margin: const EdgeInsets.all(6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    shadowColor: Colors.black.withAlpha(50),
    surfaceTintColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: ColorConstants.appBar,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(12),
      ),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorConstants.seed,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);
