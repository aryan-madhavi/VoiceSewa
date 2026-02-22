import 'package:flutter_riverpod/legacy.dart';

enum AuthScreen { login, signup }

final authScreenProvider = StateProvider<AuthScreen>((ref) => AuthScreen.login);
