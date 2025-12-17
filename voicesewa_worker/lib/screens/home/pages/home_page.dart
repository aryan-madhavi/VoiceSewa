import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/app_constants.dart';
import 'package:voicesewa_worker/screens/home/cards/dashboard.dart';
import 'package:voicesewa_worker/screens/home/cards/find_work.dart';
import 'package:voicesewa_worker/screens/home/cards/rating.dart';

import '../../../constants/core/color_constants.dart';
import '../../../constants/core/static_data.dart';
import '../../../constants/core/string_constants.dart';
import '../../../extensions/context_extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showdata = false;
  bool _iconarrowdirection = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),

              const SizedBox(
                height: 300,
                child: Dashboard(),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() {
                            _showdata = !_showdata;
                            _iconarrowdirection = !_iconarrowdirection;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.loc.findWorkTitle,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: flag ? Colors.green : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          flag ? context.loc.onlineAndVisible : context.loc.youAreOffline,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: flag ? Colors.green[700] : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Row(
                                children: [
                                  Switch(
                                    value: flag,
                                    activeColor: Colors.white,
                                    activeTrackColor: Colors.green,
                                    onChanged: (bool value) {
                                      setState(() {
                                        flag = value;
                                      });
                                      if (value) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(context.loc.youAreNowReceivingJobNotifications),
                                            backgroundColor: ColorConstants.primaryBlue,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _iconarrowdirection
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_showdata)
                        const FindWork(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Rating(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}