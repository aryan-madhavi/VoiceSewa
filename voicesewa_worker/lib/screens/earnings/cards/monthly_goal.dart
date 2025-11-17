import 'package:flutter/material.dart';

class MonthlyGoal extends StatefulWidget {
  const MonthlyGoal({super.key});

  @override
  State<MonthlyGoal> createState() => _MonthlyGoalState();
}

class _MonthlyGoalState extends State<MonthlyGoal> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Row(
            children: [
              Text("Monthly Goal"),
              Container(child: Text("XX%")),
            ],
          ),
          Slider(
            value: 20,
            onChanged: (){},
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
