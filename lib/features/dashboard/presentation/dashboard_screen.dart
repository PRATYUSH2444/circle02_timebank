import 'package:flutter/material.dart';

import '../../feed/presentation/feed_screen.dart';
import '../../explore/presentation/explore_screen.dart';
import '../../sessions/presentation/sessions_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../feed/widgets/create_post_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  /// 🔥 KEEP STATE (IMPORTANT)
  final List<Widget> screens = const [
    FeedScreen(),
    ExploreScreen(),
    SizedBox(), // Post handled separately
    SessionsScreen(),
    ProfileScreen(),
  ];

  void onTabTapped(int index) {
    /// 🔥 HANDLE POST BUTTON
    if (index == 2) {
      showDialog(
        context: context,
        builder: (_) => const CreatePostDialog(),
      );
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      /// 🔥 KEEP SCREENS ALIVE (NO REBUILD)
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      /// 🔥 MODERN NAV BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 10,
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTabTapped,
          type: BottomNavigationBarType.fixed,

          backgroundColor: Colors.black,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.grey,

          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 34),
              label: "Post",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: "Sessions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}