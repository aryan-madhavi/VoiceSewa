import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'package:voicesewa_worker/features/jobs/presentation/contact_call_page.dart';

class ContactMsgPage extends StatefulWidget {
  const ContactMsgPage({super.key});

  @override
  State<ContactMsgPage> createState() => _ContactMsgPageState();
}

class _ContactMsgPageState extends State<ContactMsgPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          "ClientName",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
              onPressed: (){
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context)=> const ContactCallPage()
                ),
            );
          },
              icon: Icon(Icons.call))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: Text(
                "client or your msg",
              ),
            ),
            TextField(
            ),
          ],
        ),
      ),
    );
  }
}
