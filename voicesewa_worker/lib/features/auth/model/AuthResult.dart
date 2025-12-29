import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final bool isOffline;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.isOffline = false,
  });
}