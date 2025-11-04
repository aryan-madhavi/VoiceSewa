import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:voicesewa_client/constants/home/home_constants.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final quickActionsList = HomeConstants.actions.keys.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8.0),
      child: GridView.builder(
        itemCount: 4,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (context, index) {
          final action = quickActionsList[index];
          final actionIcon = HomeConstants.actions[action]![0] as IconData;
          final actionLabel = HomeConstants.actions[action]![1] as String;
          final actionRoute = HomeConstants.actions[action]![2] as String;
          return Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 2, vertical: 1.5),
            child: GestureDetector(
              onTap: () => context.pushNamedTransition(
                routeName: actionRoute,
                type: PageTransitionType.rightToLeft,
              ),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(actionIcon, size: 32),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          actionLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
