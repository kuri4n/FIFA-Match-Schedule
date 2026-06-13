import 'package:flutter/material.dart';
import '../widgets/flag_widget.dart';
import '../models/knockout_match_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class KnockoutScreen extends StatefulWidget {
  const KnockoutScreen({super.key});

  @override
  State<KnockoutScreen> createState() => _KnockoutScreenState();
}

class _KnockoutScreenState extends State<KnockoutScreen> {
  late Future<List<KnockoutMatchModel>> knockoutMatchesFuture;

  final List<String> knockoutRounds = [
    'Round of 32',
    'Round of 16',
    'Quarter-final',
    'Semi-final',
    'Third Place',
    'Final',
  ];

  String selectedRound = 'Round of 32';

  @override
  void initState() {
    super.initState();
    knockoutMatchesFuture = ApiService().getKnockoutMatches();
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
          'Knockout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<KnockoutMatchModel>>(
        future: knockoutMatchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load knockout matches',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final matches = snapshot.data ?? [];

          final filteredMatches = matches
              .where((match) => match.roundName == selectedRound)
              .toList();

          final groupedMatches = _groupMatchesByRound(filteredMatches);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRound,
                    dropdownColor: AppColors.secondary1,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    items: knockoutRounds.map((round) {
                      return DropdownMenuItem(
                        value: round,
                        child: Text(round),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedRound = value;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedMatches.length,
                  itemBuilder: (context, index) {
                    final roundName = groupedMatches.keys.elementAt(index);
                    final roundMatches = groupedMatches[roundName]!;

                    return _RoundSection(
                      roundName: roundName,
                      matches: roundMatches,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(
        currentIndex: 2,
      ),
    );
  }

  Map<String, List<KnockoutMatchModel>> _groupMatchesByRound(
    List<KnockoutMatchModel> matches,
  ) {
    final Map<String, List<KnockoutMatchModel>> grouped = {};

    for (final match in matches) {
      grouped.putIfAbsent(match.roundName, () => []);
      grouped[match.roundName]!.add(match);
    }

    return grouped;
  }
}

class _RoundSection extends StatelessWidget {
  final String roundName;
  final List<KnockoutMatchModel> matches;

  const _RoundSection({
    required this.roundName,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondary1,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roundName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(matches.length, (index) {
            final match = matches[index];

            return Column(
              children: [
                _KnockoutMatchCard(match: match),
                if (index != matches.length - 1)
                  const _ConnectorLine(),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _KnockoutMatchCard extends StatelessWidget {
  final KnockoutMatchModel match;

  const _KnockoutMatchCard({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore =
        match.team1Score != null && match.team2Score != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                match.matchNo,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                match.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TeamSlot(
            name: match.team1,
            flagCode: match.team1FlagCode,
            score: hasScore ? match.team1Score : null,
          ),
          const SizedBox(height: 10),
          const Text(
            'vs',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _TeamSlot(
            name: match.team2,
            flagCode: match.team2FlagCode,
            score: hasScore ? match.team2Score : null,
          ),
        ],
      ),
    );
  }
}

class _TeamSlot extends StatelessWidget {
  final String name;
  final String? flagCode;
  final int? score;

  const _TeamSlot({
    required this.name,
    this.flagCode,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder =
        name.startsWith('Winner') ||
        name.startsWith('Runner-up') ||
        name.startsWith('Loser') ||
        name.startsWith('3rd');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (!isPlaceholder && flagCode != null && flagCode!.isNotEmpty)
            FlagWidget(code: flagCode!)
          else
            const Icon(
              Icons.help_outline,
              color: Colors.white70,
              size: 18,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isPlaceholder ? Colors.white70 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (score != null)
            Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 2,
        height: 22,
        color: Colors.white24,
      ),
    );
  }
}