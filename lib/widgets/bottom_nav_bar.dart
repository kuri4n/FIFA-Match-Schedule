import 'package:flutter/material.dart';

import '../screens/matches_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/knockout_screen.dart';
import '../screens/table_screen.dart';
import '../theme/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    final screens = [
      const MatchesScreen(),
      const StatsScreen(),
      const KnockoutScreen(),
      const TableScreen(),
    ];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screens[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: AppColors.primary,
      selectedItemColor: Colors.greenAccent,
      unselectedItemColor: Colors.white60,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => _navigate(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_soccer),
          label: 'Matches',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Knockout',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.table_chart),
          label: 'Table',
        ),
      ],
    );
  }
}