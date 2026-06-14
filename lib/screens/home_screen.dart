import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../widgets/flag_widget.dart';
import '../utils/page_transitions.dart';
import 'tournament_screen.dart';
import 'team_screen.dart';
import '../services/api_service.dart';
import '../services/football_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String teamName = '';
  String teamCode = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _autoSync());
    loadTeam();
  }
  Future<void> _autoSync() async {
    final prefs = await SharedPreferences.getInstance();

    final lastSyncMillis = prefs.getInt('last_auto_sync');

    if (lastSyncMillis != null) {
      final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);

      if (DateTime.now().difference(lastSync).inMinutes < 15) {
        return;
      }
    }

    try {
      await FootballDataService().syncWorldCupMatches();
      await FootballDataService().syncKnockoutMatches();
      await FootballDataService().syncWorldCupScorers();

      await ApiService().recalculateStandings();
      await ApiService().populateKnownRoundOf32Slots();
      await ApiService().populateThirdPlaceSlots();
      await ApiService().advanceKnockoutWinners();

      await prefs.setInt(
        'last_auto_sync',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Auto sync failed: $e');
    }
  }
  Future<void> loadTeam() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      teamName =
          prefs.getString('favorite_team_name') ?? 'No Team Selected';

      teamCode =
          prefs.getString('favorite_team_code') ?? '';
    });
  }

  Future<void> changeTeam() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('favorite_team_id');
    await prefs.remove('favorite_team_name');
    await prefs.remove('favorite_team_code');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageTransitions.fadeSlide(const TeamScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'FIFA Schedule App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Text(
              'YOUR TEAM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary1,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  if (teamCode.isNotEmpty)
                    FlagWidget(code: teamCode),

                  const SizedBox(height: 12),

                  Text(
                    teamName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransitions.fadeSlide(
                    const TournamentScreen(),
                  ),
                );
              },
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.secondary1,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/fifa_wc_2026.png',
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Text(
                          'FIFA WC 2026',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: changeTeam,
                child: const Text(
                  'Change Team',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}