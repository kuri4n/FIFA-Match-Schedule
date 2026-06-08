import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import '../widgets/match_card.dart';
import 'match_details_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() =>
      _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int? expandedIndex;

  late Future<List<MatchModel>> matchesFuture;

  String selectedTeam = 'All';
  bool showStarredOnly = false;

  @override
  void initState() {
    super.initState();
    matchesFuture = ApiService().getMatches();
  }

  List<MatchModel> _sortMatches(List<MatchModel> matches) {
    final sortedMatches = [...matches];

    sortedMatches.sort((a, b) {
      final aFinished = a.status == 'Finished';
      final bFinished = b.status == 'Finished';

      if (aFinished && !bFinished) return -1;
      if (!aFinished && bFinished) return 1;

      return a.matchDateTime.compareTo(
        b.matchDateTime,
      );
    });

    return sortedMatches;
  }

  List<String> _buildTeamFilterList(
    List<MatchModel> matches,
  ) {
    final teams = matches
        .expand(
          (match) => [
            match.homeTeam,
            match.awayTeam,
          ],
        )
        .where(
          (team) =>
              !team.startsWith('Winner') &&
              !team.startsWith('Runner-up') &&
              !team.startsWith('Loser') &&
              !team.startsWith('3rd'),
        )
        .toSet()
        .toList()
      ..sort();

    return ['All', ...teams];
  }

  List<MatchModel> _filterMatches(
    List<MatchModel> matches,
  ) {
    return matches.where((match) {
      final matchesTeam =
          selectedTeam == 'All' ||
          match.homeTeam == selectedTeam ||
          match.awayTeam == selectedTeam;

      final matchesStarFilter =
          !showStarredOnly || match.isStarred;

      return matchesTeam && matchesStarFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          expandedIndex = null;
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Matches',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: FutureBuilder<List<MatchModel>>(
          future: matchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Unable to load matches',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            matchesFuture = ApiService().getMatches();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final matches =
                _sortMatches(snapshot.data ?? []);
            final teams =
                _buildTeamFilterList(matches);
            final filteredMatches =
                _filterMatches(matches);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary1,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child:
                            DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTeam,
                            dropdownColor:
                                AppColors.secondary1,
                            iconEnabledColor:
                                Colors.white,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            items: teams.map((team) {
                              return DropdownMenuItem(
                                value: team,
                                child: Text(team),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedTeam = value!;
                                expandedIndex = null;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showStarredOnly =
                                !showStarredOnly;
                            expandedIndex = null;
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: showStarredOnly
                                ? Colors.amber
                                : AppColors.secondary1,
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 18,
                                color: showStarredOnly
                                    ? Colors.black
                                    : Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Starred',
                                style: TextStyle(
                                  color: showStarredOnly
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filteredMatches.isEmpty
                      ? const Center(
                          child: Text(
                            'No matches found',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(16),
                          itemCount:
                              filteredMatches.length,
                          itemBuilder: (context, index) {
                            final match =
                                filteredMatches[index];

                            return MatchCard(
                              match: match,
                              isExpanded:
                                  expandedIndex ==
                                      index,
                              onLongPress: () {
                                setState(() {
                                  expandedIndex = index;
                                });
                              },
                              onStarToggle: () async {
                                final newValue =
                                    !match.isStarred;

                                setState(() {
                                  match.isStarred =
                                      newValue;
                                });

                                if (newValue) {
                                  await ApiService()
                                      .starMatch(match.id);
                                } else {
                                  await ApiService()
                                      .unstarMatch(match.id);
                                }
                              },
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  PageTransitions
                                      .fadeSlide(
                                    MatchDetailsScreen(
                                      match: match,
                                    ),
                                  ),
                                );

                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}