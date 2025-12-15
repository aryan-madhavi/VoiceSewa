import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Preferences", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSwitchTile("Push Notifications", "Receive job alerts", _notificationsEnabled, (val) {
            setState(() => _notificationsEnabled = val);
          }),
          _buildSwitchTile("Dark Mode", "Reduce eye strain", _darkMode, (val) {
            setState(() => _darkMode = val);
          }),

          const SizedBox(height: 30),
          const Text("Account", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildActionTile("Change Password", Icons.lock_outline, () {}),
          _buildActionTile("Language", Icons.language, () {}),
          _buildActionTile("Privacy Policy", Icons.privacy_tip_outlined, () {}),

          const SizedBox(height: 30),
          _buildActionTile("Delete Account", Icons.delete_outline, () {}, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
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

  Widget _buildActionTile(
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
}