// lib/core/extensions.dart

extension DurationFormat on Duration {
  /// Formats a call duration for display.
  /// Under 1 hour:  "04:32"
  /// Over 1 hour:   "1:04:32"
  String toCallDuration() {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

extension Bcp47 on String {
  /// "hi-IN" → "hi"   (base language code required by Google Translate API)
  String toBaseLang() => split('-').first;

  /// "hi-IN" → "IN"
  String toRegionCode() {
    final parts = split('-');
    return parts.length > 1 ? parts.last : '';
  }
}