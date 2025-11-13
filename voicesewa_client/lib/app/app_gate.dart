import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart'; 
import 'package:voicesewa_client/features/auth/data/db_login.dart';

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late Future<bool> _check;

  @override
  void initState() {
    super.initState();
    _check = DbLogin().isSessionValid();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final valid = snap.data == true;
        if (valid) {
          return RootScaffold(); 
        } else {
          return const LoginScreen(); 
        }
      },
    );
  }
}
