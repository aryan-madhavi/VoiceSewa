import 'package:flutter/material.dart';
import 'package:voicesewa_worker/screens/my_jobs/cards/Active/ongoing.dart';
import 'package:voicesewa_worker/screens/my_jobs/cards/Active/pending.dart';
import 'package:voicesewa_worker/screens/my_jobs/cards/Recent/completed.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 15,),
            Text ("Active"),
            
            SizedBox(height: 15,),
            Ongoing(),
            Pending(),
      
            SizedBox(height: 15,),
            Text("Recent"),
      
            SizedBox(height: 15,),
      
            Completed(),
            SizedBox(height: 15,),
          ],
        ),
      ),
    );
  }
}
