// import 'dart:ui';

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import '../../extensions/context_extensions.dart';
import 'color_constants.dart';

// Withdraw
Widget withdrawBuildStatCard (String title, String amount, Color color){
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ColorConstants.textGrey,
              fontSize: 12,
            ),
          ),

          SizedBox(height: 6,),

          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// find_work
Widget findWorkBuildIconText(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: ColorConstants.textGrey),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(color: ColorConstants.textGrey, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
Widget findWorkBuildTag(String tag) {
  Color bgColor = Colors.grey.shade100;
  Color textColor = ColorConstants.textGrey;
  if (tag == 'Urgent') {
    bgColor = ColorConstants.urgentRed.withOpacity(0.1);
    textColor = ColorConstants.urgentRed;
  } else if (tag == 'New') {
    bgColor = ColorConstants.newBlue.withOpacity(0.1);
    textColor = ColorConstants.newBlue;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
    child: Text(
      tag,
      style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

// my_job
Widget myJobBuildIconText(IconData icon, String text, {bool isBold = false} ){
  return Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: ColorConstants.textGrey,
      ),
      const SizedBox(width: 8,),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: isBold ? ColorConstants.primaryBlue : ColorConstants.textGrey,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ],
  );
}

// profile_page
Widget profilePageBuildStatsRow(cl) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      profilePageBuildStatItem(
          "4.8",
          cl.rating,
          // "Rating",
          Icons.star, Colors.orange),
      Container(width: 1, height: 40, color: Colors.grey.shade300),
      profilePageBuildStatItem(
          "125",
          cl.jobs,
          // "Jobs",
          Icons.work, Colors.blue),
      Container(width: 1, height: 40, color: Colors.grey.shade300),
      profilePageBuildStatItem(
          "2 yrs",
          cl.experience, // "Experience",
          Icons.timeline, Colors.green),
    ],
  );
}
Widget profilePageBuildStatItem(String value, String label, IconData icon, Color color) {
  return Column(
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    ],
  );
}
Widget profilePageBuildMenuCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    ),
  );
}

// settings_page
Widget settingsPageBuildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    ),
  );
}
Widget settingsPageBuildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap,
    {bool isDestructive = false}){
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12)
    ),
    child: ListTile(
      onTap: onTap,
      leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.blue
      ),
      title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDestructive ? Colors.red : Colors.black
          )
      ),
      trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey
      ),
    ),
  );
}

// support_and_help_page
Widget snhPageBuildFaqTile(String question, String answer) {
  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
    child: ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(answer, style: TextStyle(color: Colors.grey[700])),
        )
      ],
    ),
  );
}

//
Widget workHistoryPageBuildJobCard(int index) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4)
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "Plumbing Repair",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                    )
                ),
                const SizedBox(height: 4),
                Text(
                    "24 Oct, 2023 • 10:30 AM",
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12
                    )
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                  "Completed",
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                "Earned",
                style: TextStyle(color: Colors.grey)),
            Text("₹ 450.00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    ),
  );
}