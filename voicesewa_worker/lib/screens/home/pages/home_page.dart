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
  bool flag = false;
  bool _showdata = false;
  bool _iconarrowdirection = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 50),

              SizedBox(
                height: 300,
                child: Dashboard(),
                ),

              SizedBox(height: 50),

              Padding(
                padding: EdgeInsets.all(10),
                child: Card(
                  margin: EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showdata = !_showdata;
                        _iconarrowdirection = !_iconarrowdirection;
                      });
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text("Find Works"),

                            SizedBox(width: 50),

                            Switch(
                              value: flag,
                              activeThumbColor: Colors.green,
                              onChanged: (bool value) {
                                setState(() {
                                  flag = value;
                                });
                              },
                            ),
                            Icon(
                              _iconarrowdirection
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                          ],
                        ),
                        if (_showdata) SizedBox(height: 200,child: FindWork()),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 50),

              Rating(),
            ],
          ),
        ),
      ),
    );
  }
}
