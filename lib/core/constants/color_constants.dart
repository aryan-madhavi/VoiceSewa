import 'package:flutter/material.dart';

class ColorConstants {
  static const Color seed = Colors.lightBlue;
  static const Color scaffold = Color(0xFFF2F8FC);
  static const Color appBar = Color(0xFFB3E5FC);
  static const Color navBar = Color(0xFFE1F5FE);
  static const Color floatingActionButton = Color(0xFF81D4FA);
  static const Color primaryBlue = Color(0xFF0056D2);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textGrey = Color(0xFF757575);
  static const Color urgentRed = Color(0xFFE74C3C);
  static const Color newBlue = Color(0xFF3498DB);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ── Status / feedback colors ───────────────────────────────────────────────
  /// Teal used for in-progress, start-job, slide-to-end, and bill actions.
  static const Color successTeal = Color(0xFF00BFA5);

  /// Standard green used for completed status, call buttons, snackbars.
  static const Color successGreen = Colors.green;

  /// Red used for errors, decline actions, and snackbars.
  static const Color errorRed = Colors.red;

  /// Orange used for warning snackbars (e.g. job declined).
  static const Color warningOrange = Colors.orange;

  /// Amber used for star ratings and feedback UI.
  static const Color ratingAmber = Colors.amber;

  /// Darker amber shade used for feedback button backgrounds and text.
  static const Color ratingAmberDark = Color(0xFFFFB300); // amber.shade700

  // ── Neutral / surface colors ───────────────────────────────────────────────
  /// Pure white — used for card/container backgrounds, AppBar, input fills,
  /// icon/text on dark backgrounds, and bottom sheets.
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Used for box-shadow color (always paired with .withOpacity()).
  static const Color shadowBlack = Color(0xFF000000);

  /// Light grey used for dividers, OTP box borders, unselected tab labels,
  /// star borders, drag-handle indicators, and disabled/inactive surfaces.
  static const Color dividerGrey = Color(
    0xFFE0E0E0,
  ); // grey.shade300 equivalent

  /// Slightly darker grey used for disabled button backgrounds.
  static const Color disabledGrey = Color(
    0xFFEEEEEE,
  ); // grey.shade200 equivalent

  /// Background colour for the chat screen and message input area.
  static const Color chatBackground = Color(0xFFF0F4F8);

  /// Sending-state colour for the chat send button.
  static const Color sendingGrey = Color(
    0xFFBDBDBD,
  ); // grey.shade300 equivalent

  /// Fully transparent — used for modal/bottom sheet backgrounds that rely
  /// on child decoration for shape and colour.
  static const Color transparent = Colors.transparent;

  // ── Info / hint blue tones (worker profile form, info banners) ────────────
  /// Standard blue used for submit buttons, section headers, and info boxes
  /// where primaryBlue (0056D2) is too dark.
  static const Color infoBlue = Colors.blue;

  /// Very light blue used for info-box background fills.
  static const Color infoBlueSurface = Color(0xFFE3F2FD); // blue.shade50

  /// Light blue used for info-box borders.
  static const Color infoBlueBorder = Color(0xFF90CAF9); // blue.shade200

  /// Medium-dark blue used for section-header icons, section-header text,
  /// and notification icon tint.
  static const Color infoBlueDark = Color(0xFF1976D2); // blue.shade700

  /// Deep blue used for info-box body text.
  static const Color infoBlueDeep = Color(0xFF0D47A1); // blue.shade900

  /// Pale blue used for divider lines next to section headers.
  static const Color infoBlueDivider = Color(0xFFBBDEFB); // blue.shade100

  // ── Extended status / notification tones ──────────────────────────────────
  /// Purple used for profile-type FCM notification icons.
  static const Color notifPurple = Colors.purple;

  /// Dark green used for success status text (e.g. location captured label).
  static const Color successGreenDark = Color(0xFF388E3C); // green.shade700

  /// Dark orange used for warning status text (e.g. location warning label).
  static const Color warningOrangeDark = Color(0xFFEF6C00); // orange.shade800

  // ── Unselected / inactive grey tones ─────────────────────────────────────
  /// Mid grey used for unselected icons, password-visibility eye icons,
  /// and plain "Later" button text in dialogs.
  static const Color unselectedGrey = Colors.grey;

  /// Darker grey used for unselected skill-card label text.
  static const Color unselectedGreyDark = Color(0xFF616161); // grey.shade700

  /// Light grey used for subtitle / helper text (e.g. grey[600]).
  static const Color subtitleGrey = Color(0xFF757575); // grey.shade600

  // ── Chip / filter UI colors ───────────────────────────────────────────────
  /// Unselected chip/card background (grey.shade100).
  static const Color chipGreySurface = Color(0xFFF5F5F5);

  /// Lighter unselected chip/dropdown background (grey.shade50).
  static const Color chipGreySurface2 = Color(0xFFFAFAFA);

  /// Unselected chip border colour (grey.shade300).
  static const Color chipGreyBorder = Color(0xFFE0E0E0);

  /// Unselected chip count badge background (grey.shade400).
  static const Color chipGreyBadge = Color(0xFFBDBDBD);

  /// Mid grey used for separators/decorators in pickers (grey.shade500).
  static const Color chipGreyMid = Color(0xFF9E9E9E);

  /// Grey used for "Withdrawn" status text, icons, and accent bar (grey.shade600).
  static const Color withdrawnGrey = Color(0xFF757575);

  // ── Status chip accent colors ─────────────────────────────────────────────
  /// Orange used for "New" incoming chip, "In Progress" ongoing chip,
  /// and quotation-submitted status badge.
  static const Color chipOrange = Color(0xFFFF9800);

  /// Soft red used for the "Declined" incoming chip (red.shade400).
  static const Color chipRedSoft = Color(0xFFEF5350);

  /// Purple used for the "Quoted" incoming chip.
  static const Color chipPurple = Color(0xFF8B5CF6);

  /// Dark green used for "Seen by client" text and quotation-accepted badge
  /// (green.shade600).
  static const Color seenGreen = Color(0xFF43A047);
}
