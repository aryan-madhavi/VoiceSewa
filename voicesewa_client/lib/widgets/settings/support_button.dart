import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';

class SupportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SupportButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? ColorConstants.floatingActionButton : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade800),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade900,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
