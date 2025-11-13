import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:voicesewa_client/features/home/data/actions.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = ActionData.quickActions.entries.toList();

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final entry = actions[index];
        final List<dynamic> data = entry.value;
    
        final Color color = data[0] as Color;
        final IconData icon = data[1] as IconData;
        final String label = data[2] as String;
        final String route = data[3] as String;
    
        return _QuickActionCard(
          color: color,
          icon: icon,
          label: label,
          onTap: () => context.pushNamedTransition(
            routeName: route,
            type: PageTransitionType.rightToLeft,
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
