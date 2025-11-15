import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:voicesewa_client/features/home/data/services_data.dart';
import 'package:voicesewa_client/features/home/providers/quick_book_services_provider.dart';
import 'package:voicesewa_client/core/routes/navigation_routes.dart';

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
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Text(
                'Quick Book Services',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const QuickBookGrid(),
          ],
        ),
      ),
    );
  }
}

class QuickBookGrid extends ConsumerWidget {
  const QuickBookGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickServices = ref.watch(quickBookServicesProvider);

    const String routeName = RoutePaths.book;

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
        final data = ServicesData.services[service]!;

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
                : RoutePaths.comingSoon,
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
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
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
