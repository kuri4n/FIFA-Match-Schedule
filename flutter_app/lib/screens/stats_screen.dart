import 'package:flutter/material.dart';

import '../models/player_stat_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/flag_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool showAllScorers = false;
  bool showAllAssists = false;

  late Future<List<PlayerStatModel>> topScorersFuture;
  late Future<List<PlayerStatModel>> topAssistsFuture;

  @override
  void initState() {
    super.initState();

    final apiService = ApiService();

    topScorersFuture = apiService.getTopScorers();
    topAssistsFuture = apiService.getTopAssists();
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
          'Statistics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<List<PlayerStatModel>>>(
        future: Future.wait([
          topScorersFuture,
          topAssistsFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load statistics',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            );
          }

          final topScorers = snapshot.data![0];
          final topAssists = snapshot.data![1];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatCard(
                  title: 'Top Scorers',
                  statName: 'Goals',
                  data: topScorers,
                  expanded: showAllScorers,
                  onToggle: () {
                    setState(() {
                      showAllScorers =
                          !showAllScorers;
                    });
                  },
                ),

                const SizedBox(height: 20),

                _buildStatCard(
                  title: 'Top Assists',
                  statName: 'Assists',
                  data: topAssists,
                  expanded: showAllAssists,
                  onToggle: () {
                    setState(() {
                      showAllAssists =
                          !showAllAssists;
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String statName,
    required List<PlayerStatModel> data,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final displayedPlayers =
        expanded ? data : data.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary1,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              Text(
                statName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ...List.generate(
            displayedPlayers.length,
            (index) {
              final player = displayedPlayers[index];

              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(4),
                        child: SizedBox(
                          width: 32,
                          height: 22,
                          child: FlagWidget(
                            code: player.flagCode,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          player.playerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      Text(
                        '${player.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  if (index !=
                      displayedPlayers.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      child: Divider(
                        color: Colors.white12,
                        height: 1,
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.secondary2,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              onPressed: onToggle,
              child: Text(
                expanded
                    ? 'Show Top 5'
                    : 'View Top 10',
              ),
            ),
          ),
        ],
      ),
    );
  }
}