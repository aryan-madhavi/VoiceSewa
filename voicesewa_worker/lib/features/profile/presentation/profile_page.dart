import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/auth/provider/logout_provider.dart';
import 'package:voicesewa_worker/features/profile/presentation/bank_details_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/settings_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/support_and_help_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/work_history_page.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/constants/helper_function.dart';
import '../../../core/extensions/context_extensions.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    // final height = MediaQuery.of(context).size.height;
    // final width = MediaQuery.of(context).size.width;

    // Watch logout state
    final logoutState = ref.watch(logoutProvider);

    // Listen to logout state changes
    ref.listen<LogoutState>(logoutProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${next.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.loc.myProfile, // "My Profile",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_rounded, color: Colors.black),
          ),
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
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 15),

            profilePageBuildMenuCard(
              icon: Icons.settings,
              title: context.loc.settings, //"Settings",
              subtitle: context
                  .loc
                  .privacyNotificationsLanguage, //"Privacy, notifications, language",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            profilePageBuildMenuCard(
              icon: Icons.history,
              title: context.loc.workHistory, //"Work History",
              subtitle: context
                  .loc
                  .viewPastJobsAndEarnings, //"View past jobs and earnings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkHistoryPage(),
                  ),
                );
              },
            ),
            profilePageBuildMenuCard(
              icon: Icons.account_balance_wallet,
              title: context.loc.bankDetails, //"Bank Details",
              subtitle: context
                  .loc
                  .managePayoutsAndAccounts, //"Manage payouts and accounts",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BankDetailsPage(),
                  ),
                );
              },
            ),
            profilePageBuildMenuCard(
              icon: Icons.help_outline,
              title: context.loc.helpAndSupport, //"Support & Help",
              subtitle: context.loc.fAQsContactUs, //"FAQs, Contact us",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportPage()),
                );
              },
            ),

            // Logout Button
            const SizedBox(height: 30),
            // SizedBox(
            //   width: double.infinity,
            //   height: 50,
            //   child: ElevatedButton(
            //     onPressed: logoutState.isLoading ? null : _handleLogout,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.redAccent.withOpacity(0.1),
            //       elevation: 0,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       disabledBackgroundColor: Colors.grey.withOpacity(0.1),
            //     ),
            //     child: logoutState.isLoading
            //         ? const SizedBox(
            //             width: 24,
            //             height: 24,
            //             child: CircularProgressIndicator(
            //               strokeWidth: 2.5,
            //               valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            //             ),
            //           )
            //         : Text(
            //             context.loc.logOut, // "Log Out",
            //             style: const TextStyle(
            //               color: Colors.red,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //   ),
            // ),
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
                backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
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
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
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
