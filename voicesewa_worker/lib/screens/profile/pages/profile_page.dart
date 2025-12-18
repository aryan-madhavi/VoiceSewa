import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/color_constants.dart';
import 'package:voicesewa_worker/screens/profile/pages/bank_details_page.dart';
import 'package:voicesewa_worker/screens/profile/pages/settings_page.dart';
import 'package:voicesewa_worker/screens/profile/pages/support_and_help_page.dart';
import 'package:voicesewa_worker/screens/profile/pages/work_history_page.dart';

import '../../../constants/core/helper_function.dart';
import '../../../extensions/context_extensions.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfileState();
}

class _ProfileState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.loc.myProfile, // "My Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_rounded, color: Colors.black),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            profilePageBuildProfileHeader(),
            const SizedBox(height: 30),
            profilePageBuildStatsRow(context.loc),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.loc.general, // "General",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey
                ),
              ),
            ),
            const SizedBox(height: 15),

            profilePageBuildMenuCard(
              icon: Icons.settings,
              title: context.loc.settings,  //"Settings",
              subtitle: context.loc.privacyNotificationsLanguage, //"Privacy, notifications, language",
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage())
                );
                },
            ),
            profilePageBuildMenuCard(
              icon: Icons.history,
              title: context.loc.workHistory,  //"Work History",
              subtitle: context.loc.viewPastJobsAndEarnings, //"View past jobs and earnings",
              onTap: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const WorkHistoryPage())
                );
                },
            ),
            profilePageBuildMenuCard(
              icon: Icons.account_balance_wallet,
              title: context.loc.bankDetails,  //"Bank Details",
              subtitle: context.loc.managePayoutsAndAccounts, //"Manage payouts and accounts",
              onTap:  (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BankDetailsPage())
                );
                },
            ),
            profilePageBuildMenuCard(
              icon: Icons.help_outline,
              title: context.loc.helpAndSupport,  //"Support & Help",
              subtitle: context.loc.fAQsContactUs, //"FAQs, Contact us",
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportPage())
                );
                },
            ),

            // Logout Button
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.loc.logOut, // "Log Out",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget profilePageBuildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                    "https://i.pravatar.cc/300"),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          "Ramesh Kumar",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          "@ramesh_worker | +91 98765 43210",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }


  
}