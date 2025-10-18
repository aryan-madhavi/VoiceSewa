import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/core/widgets/coming_soon_widget.dart';
import 'package:voicesewa_client/presentation/home/screens/home_page.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int pageno = 0;

  final List<List<dynamic>> _pages = [
    [ Icon(Icons.home),       StringConstants.homeTitle,       HomePage()        ],
    [ Icon(Icons.search),     StringConstants.searchTitle,     ComingSoon()  ],
    [ SizedBox(),             '',                              SizedBox.shrink() ],
    [ Icon(Icons.history),    StringConstants.historyTitle,    ComingSoon()  ],
    [ Icon(Icons.person),     StringConstants.profileTitle,    ComingSoon()  ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[pageno][2],
      bottomNavigationBar: NavigationBar(
        selectedIndex: pageno,
        onDestinationSelected: (int pageIndex) {
          setState(() {
            pageno = pageIndex != 2 ? pageIndex : pageno;
          });
        },
        destinations: List.generate(_pages.length, (index) {
          return NavigationDestination(
            icon: _pages[index][0],
            label: _pages[index][1],
          );
        }),
      ),
    );
  }
}
