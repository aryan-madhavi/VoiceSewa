import 'package:flutter/material.dart';

class MonthlyGoal extends StatefulWidget {
  const MonthlyGoal({super.key});

  @override
  State<MonthlyGoal> createState() => _MonthlyGoalState();
}

class _MonthlyGoalState extends State<MonthlyGoal> {
  double _progress = 0.2;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Row(
            children: [
              Text("Monthly Goal"),
              Container(
                child: Text("${(_progress * 100).toInt()}%"),
                ),
            ],
          ),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey,
            color: Colors.blue,
          ),
          Row(children: [Text("Rs XXXX"), Text("Rs XXXX")]),
          Text("Keep it up I believe in you"),
          TextButton.icon(
            icon: Icon(Icons.edit),
            label: Text("Edit"),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
