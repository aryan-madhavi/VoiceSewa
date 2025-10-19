import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';

class QuickActions extends StatefulWidget {
  const QuickActions({super.key});

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  final List<List<dynamic>> _actions = [
    [ Icons.add_box_outlined,       StringConstants.bookCTA,           '/comingSoonPage' ],
    [ Icons.shopping_cart_outlined, StringConstants.activeBookingsCTA, '/comingSoonPage' ],
    [ Icons.local_offer_outlined,   StringConstants.offersCTA,         '/comingSoonPage' ],
    [ Icons.help_outline_outlined,  StringConstants.helpCTA,           '/comingSoonPage' ],
  ];

  @override
  Widget build(BuildContext context) {
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
          return Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 2, vertical: 1.5),
            child: GestureDetector(
              onTap: () {
                context.pushNamedTransition(
                  routeName: _actions[index][2], 
                  type: PageTransitionType.rightToLeft,
                );
              },
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
                        Icon(
                          _actions[index][0],
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            _actions[index][1],
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
