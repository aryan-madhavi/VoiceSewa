import 'package:flutter/material.dart';
// import 'package:voicesewa_worker/constants/core/string_constants.dart';
import 'package:voicesewa_worker/screens/home/cards/dashboard.dart';
import 'package:voicesewa_worker/screens/home/cards/find_work.dart';
import 'package:voicesewa_worker/screens/home/cards/rating.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 50),
              Dashboard(),
              FindWork(),
              Rating(),
              
              // Text(
              //   StringConstants.welcomeMessage,
              //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              //   textAlign: TextAlign.center,
              // ),
              // SizedBox(height: 20),
              // Text(
              //   'This is where you can manage your jobs and earnings.',
              //   style: TextStyle(fontSize: 16),
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
