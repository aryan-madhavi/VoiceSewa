import 'package:flutter/material.dart';
import '../../../constants/core/helper_function.dart';
import '../../../extensions/context_extensions.dart';

class WorkHistoryPage extends StatelessWidget {
  const WorkHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            context.loc.workHistory, // "Work History",
            style: TextStyle(color: Colors.black)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return workHistoryPageBuildJobCard(index);
        },
      ),
    );
  }


}