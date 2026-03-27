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

  // ✅ UPDATED SCREENS LIST
  final List<Widget> screens = [
    const FeedScreen(),
    const ExploreScreen(),
    const SizedBox(),
    const SessionsScreen(),
    const ProfileScreen(),
  ];

  void onTabTapped(int index) {
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
      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 32),
            label: "Post",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Sessions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}