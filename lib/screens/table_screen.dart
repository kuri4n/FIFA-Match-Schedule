import 'package:flutter/material.dart';

import '../models/group_standing_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/flag_widget.dart';
import '../services/football_data_service.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late Future<List<GroupStandingModel>> standingsFuture;

  @override
  void initState() {
    super.initState();
    standingsFuture = ApiService().getStandings();
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
          'Standings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary2,
        foregroundColor: Colors.white,
        onPressed: () async {
          await FootballDataService().syncWorldCupMatches();

          await ApiService().recalculateStandings();
          await ApiService().populateKnownRoundOf32Slots();

          if (!context.mounted) return;

          setState(() {
            standingsFuture = ApiService().getStandings();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Matches and standings synced'),
            ),
          );
        },
        child: const Icon(Icons.refresh),
      ),
      body: FutureBuilder<List<GroupStandingModel>>(
        future: standingsFuture,
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
                'Unable to load standings',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final standings = snapshot.data ?? [];
          final groupedStandings =
              _groupStandingsByGroup(standings);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedStandings.length,
            itemBuilder: (context, index) {
              final groupName =
                  groupedStandings.keys.elementAt(index);
              final teams = groupedStandings[groupName]!;

              return _groupCard(
                groupName: groupName,
                teams: teams,
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<GroupStandingModel>> _groupStandingsByGroup(
    List<GroupStandingModel> standings,
  ) {
    final Map<String, List<GroupStandingModel>> grouped = {};

    for (final standing in standings) {
      grouped.putIfAbsent(
        standing.groupName,
        () => [],
      );

      grouped[standing.groupName]!.add(standing);
    }

    for (final teams in grouped.values) {
      teams.sort((a, b) {
        final pointsCompare =
            b.points.compareTo(a.points);
        if (pointsCompare != 0) {
          return pointsCompare;
        }

        final gdCompare =
            b.goalDifference.compareTo(a.goalDifference);
        if (gdCompare != 0) {
          return gdCompare;
        }

        return b.goalsFor.compareTo(a.goalsFor);
      });
    }

    return grouped;
  }

  Widget _groupCard({
    required String groupName,
    required List<GroupStandingModel> teams,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondary1,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                groupName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                'Pts',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Team',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              _HeaderText('P'),
              _HeaderText('W'),
              _HeaderText('D'),
              _HeaderText('L'),
              _HeaderText('GD'),
              _HeaderText('Pts'),
            ],
          ),

          const SizedBox(height: 10),

          ...List.generate(teams.length, (index) {
            final team = teams[index];

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          FlagWidget(code: team.flagCode),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              team.teamName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CellText('${team.played}'),
                    _CellText('${team.wins}'),
                    _CellText('${team.draws}'),
                    _CellText('${team.losses}'),
                    _CellText('${team.goalDifference}'),
                    _CellText(
                      '${team.points}',
                      bold: true,
                    ),
                  ],
                ),
                if (index != teams.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: Colors.white12,
                      height: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  final bool bold;

  const _CellText(
    this.text, {
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight:
              bold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}