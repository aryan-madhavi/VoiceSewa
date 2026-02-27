import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'settings_section_header.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: context.loc.account),
        const SizedBox(height: 10),
        settingsPageBuildActionTile(
          context.loc.changePassword,
          Icons.lock_outline,
          () {
            // TODO: Implement change password
          },
        ),
        settingsPageBuildActionTile(
          context.loc.privacyPolicy,
          Icons.privacy_tip_outlined,
          () {
            // TODO: Implement privacy policy viewer
          },
        ),
      ],
    );
  }
}
