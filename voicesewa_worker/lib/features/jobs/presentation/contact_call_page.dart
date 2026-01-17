import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';

class ContactCallPage extends StatefulWidget {
  const ContactCallPage({super.key});

  @override
  State<ContactCallPage> createState() => _ContactCallPageState();
}

class _ContactCallPageState extends State<ContactCallPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "ClientName",
            ),
            Text(
                "Calling",
            ),
            IconButton(
                onPressed: (){},
                icon: Icon(Icons.call_end),
            ),
          ],
        ),
      ),
    );
  }
}
