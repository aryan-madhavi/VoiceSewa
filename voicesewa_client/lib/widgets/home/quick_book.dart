import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:voicesewa_client/data/home/services.dart';
import 'package:voicesewa_client/routes/navigation_routes.dart';

class QuickBookCard extends StatelessWidget {
  const QuickBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.only(top: 12, bottom: 16),
              child: Text(
                'Quick Book Services',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            QuickBookGrid(),
          ],
        ),
      ),
    );
  }
}

class QuickBookGrid extends StatelessWidget {
  const QuickBookGrid({super.key});
  @override
  Widget build(BuildContext context) {
    final quickServices = ServiceData.quickServices;
    final routeName = '/book';
    return GridView.builder(
      itemCount: quickServices.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 2.7,
      ),
      itemBuilder: (context, index) {
        final service = quickServices[index];
        final List<dynamic> data = ServiceData.services[service]!;

        final Color color = data[0] as Color;
        final IconData icon = data[1] as IconData;
        final String label = data[2] as String;

        return _QuickBookCard(
          color: color,
          icon: icon,
          label: label,
          onTap: () => context.pushNamedTransition(
            routeName: AppRoutes.routes.containsKey(routeName)
                ? routeName
                : '/comingSoonPage',
            type: PageTransitionType.rightToLeft,
          ),
        );
      },
    );
  }
}

class _QuickBookCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickBookCard({
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
