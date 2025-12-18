import 'package:flutter/material.dart';

import '../../../constants/core/helper_function.dart';
import '../../../extensions/context_extensions.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            context.loc.helpAndSupport, // "Help & Support",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
              context.loc.frequentlyAskedQuestions, // "Frequently Asked Questions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          snhPageBuildFaqTile("How do I withdraw money?", "Go to Bank Details and select your primary account..."),
          snhPageBuildFaqTile("How to change my profile photo?", "Click on the edit icon on the profile page..."),
          snhPageBuildFaqTile("Why is my rating low?", "Ratings are based on customer feedback after every job..."),

          const SizedBox(height: 30),
          Text(
              context.loc.contactUs, // "Contact Us",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.phone, color: Colors.green)),
            title: Text(
              context.loc.callSupport, // "Call Support"
            ),
            subtitle: const Text("+91 1800-123-456"),
            onTap: () {},
          ),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.email, color: Colors.red)),
            title: Text(
              context.loc.emailSupport, // "Email Support"
            ),
            subtitle: Text(
              context.loc.helpADRATEVoicesewaDOTCom, // "help@voicesewa.com"
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  }