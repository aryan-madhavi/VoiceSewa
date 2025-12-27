import 'package:flutter_riverpod/legacy.dart';

/// Auth mode provider (login vs register)
/// true = login, false = register
final authModeProvider = StateProvider<bool>((ref) => true);

/// Loading state provider for auth operations
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Password visibility providers
final loginPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final registerPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final confirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);