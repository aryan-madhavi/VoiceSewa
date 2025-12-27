import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final void Function(BuildContext context, WidgetRef ref)? onTap;
  final Color? iconColor;
  final Widget? leadingWidget;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.leadingWidget
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ListTile(
      leading: (leadingWidget == null)
                  ? Icon(icon, color: iconColor ?? Colors.black87)
                  : leadingWidget,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 13))
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap != null ? () => onTap!(context, ref) : null,
    );
  }
}
