import 'package:flutter/material.dart';

class Withdraw extends StatefulWidget {
  const Withdraw({super.key});

  @override
  State<Withdraw> createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text("Earnings"),
          Row(children: [Text("Completed"), Text("RS X,XXX")]),
          Row(children: [Text("Pending"), Text("RS X,XXX")]),
          Row(children: [Text("Withdrawn"), Text("RS XXXX")]),
          Row(children: [Text("Total Earned"), Text("RS XXXX")]),
          Row(children: [Text("Remaining"), Text("RS XXXX")]),
          ElevatedButton.icon(
            icon: Icon(Icons.download),
            label: Text("Withdraw"),
            onPressed: () {},
          ),
          TextButton.icon(
            label: Text("View Statement"),
            icon: Icon(Icons.remove_red_eye_outlined),
            onPressed: (){}
          ),

 
       ],
      ),
    );
  }
}