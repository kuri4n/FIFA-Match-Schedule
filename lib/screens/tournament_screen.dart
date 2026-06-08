import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import 'matches_screen.dart';
import 'stats_screen.dart';
import 'table_screen.dart';
import 'knockout_screen.dart';

class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'FIFA World Cup 2026',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            const Text(
              'Tournament Center',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 25),

            _menuCard(
              context,
              'Matches',
              Icons.sports_soccer,
              const MatchesScreen(),
            ),

            _menuCard(
              context,
              'Stats',
              Icons.bar_chart,
              const StatsScreen(),
            ),

            _menuCard(
              context,
              'Table',
              Icons.table_chart,
              const TableScreen(),
            ),

            _menuCard(
              context,
              'Knockout',
              Icons.emoji_events,
              const KnockoutScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.fadeSlide(page),
          );
        },
        child: Container(
          width: double.infinity,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.secondary1,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}