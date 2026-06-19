import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/match_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/page_transitions.dart';
import '../widgets/match_card.dart';
import 'match_details_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/flag_widget.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

bool showFavoriteOnly = false;
String? favoriteTeamCode;
String? favoriteTeamName;

String _formatDateHeader(DateTime date) {
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MatchesScreenState extends State<MatchesScreen> {
  int? expandedIndex;

  late Future<List<MatchModel>> matchesFuture;

  String selectedTeam = 'All';
  bool showStarredOnly = false;

  final ScrollController _scrollController = ScrollController();
  
  // This key acts like a tracker to find the exact match on the screen
  final GlobalKey _targetMatchKey = GlobalKey(); 
  bool hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    matchesFuture = ApiService().getMatches();
    _loadFavoriteTeam();
  }

  Future<void> _loadFavoriteTeam() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      favoriteTeamCode = prefs.getString('favorite_team_code');
      favoriteTeamName = prefs.getString('favorite_team_name');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<MatchModel> _sortMatches(List<MatchModel> matches) {
    final sortedMatches = [...matches];

    sortedMatches.sort((a, b) {
      return a.matchDateTime.compareTo(b.matchDateTime);
    });

    return sortedMatches;
  }

  List<String> _buildTeamFilterList(List<MatchModel> matches) {
    final teams = matches
        .expand((match) => [match.homeTeam, match.awayTeam])
        .where((team) =>
            !team.startsWith('Winner') &&
            !team.startsWith('Runner-up') &&
            !team.startsWith('Loser') &&
            !team.startsWith('3rd'))
        .toSet()
        .toList()
      ..sort();

    return ['All', ...teams];
  }

  List<MatchModel> _filterMatches(List<MatchModel> matches) {
    return matches.where((match) {
      final matchesTeam = selectedTeam == 'All' ||
          match.homeTeam == selectedTeam ||
          match.awayTeam == selectedTeam;

      final matchesStarFilter = !showStarredOnly || match.isStarred;

      final matchesFavoriteTeam = !showFavoriteOnly ||
          match.homeFlagCode == favoriteTeamCode ||
          match.awayFlagCode == favoriteTeamCode ||
          match.homeTeam == favoriteTeamName ||
          match.awayTeam == favoriteTeamName;

      return matchesTeam && matchesStarFilter && matchesFavoriteTeam;
    }).toList();
  }

  void _scrollToLastFinishedMatch(List<MatchModel> matches) {
    if (hasAutoScrolled || matches.isEmpty) return;

    final index = matches.lastIndexWhere(
      (match) => match.status.toLowerCase() == 'finished',
    );

    if (index == -1) return;

    hasAutoScrolled = true;

    // IMPORTANT FIX: Wait for 300ms so Flutter fully draws the UI first.
    // Without this delay, the scroll command is ignored because the list doesn't exist yet.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_targetMatchKey.currentContext != null) {
        Scrollable.ensureVisible(
          _targetMatchKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          alignment: 0.0, // 0.0 forces the specific MatchCard flush to the top edge
        );
      }
    });
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
            if (snapshot.connectionState == ConnectionState.waiting) {
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
                      const Text(
                        'Unable to load matches',
                        style: TextStyle(
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

            final matches = _sortMatches(snapshot.data ?? []);
            final teams = _buildTeamFilterList(matches);
            final filteredMatches = _filterMatches(matches);
            
            // Find the index of the exact match we want to jump to
            final lastFinishedIndex = filteredMatches.lastIndexWhere(
              (match) => match.status.toLowerCase() == 'finished',
            );

            // Trigger the delay & scroll
            _scrollToLastFinishedMatch(filteredMatches);

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary1,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTeam,
                            dropdownColor: AppColors.secondary1,
                            iconEnabledColor: Colors.white,
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
                            showStarredOnly = !showStarredOnly;
                            expandedIndex = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: showStarredOnly
                                ? Colors.amber
                                : AppColors.secondary1,
                            borderRadius: BorderRadius.circular(16),
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (favoriteTeamCode != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showFavoriteOnly = !showFavoriteOnly;
                              expandedIndex = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: showFavoriteOnly
                                  ? Colors.green
                                  : AppColors.secondary1,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: FlagWidget(
                              code: favoriteTeamCode!,
                              width: 28,
                              height: 20,
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
                      : SingleChildScrollView(
                          controller: _scrollController,
                          // IMPORTANT FIX: Added 400 bottom padding. 
                          // If there are only 1 or 2 upcoming matches left, the screen wouldn't 
                          // physically be able to scroll far enough down to put the target match at the top.
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                            bottom: 400, 
                          ),
                          child: Column(
                            children: List.generate(filteredMatches.length, (index) {
                              final match = filteredMatches[index];

                              final showDateHeader = index == 0 ||
                                  !_isSameDay(
                                    filteredMatches[index - 1].matchDateTime,
                                    match.matchDateTime,
                                  );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showDateHeader)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        top: 18,
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        _formatDateHeader(match.matchDateTime),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  MatchCard(
                                    // THIS assigns the tracker key specifically to the target match card
                                    key: index == lastFinishedIndex ? _targetMatchKey : null,
                                    match: match,
                                    isExpanded: expandedIndex == index,
                                    onLongPress: () {
                                      setState(() {
                                        expandedIndex = index;
                                      });
                                    },
                                    onStarToggle: () async {
                                      final newValue = !match.isStarred;

                                      setState(() {
                                        match.isStarred = newValue;
                                      });

                                      if (newValue) {
                                        await ApiService().starMatch(match.id);
                                      } else {
                                        await ApiService().unstarMatch(match.id);
                                      }
                                    },
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        PageTransitions.fadeSlide(
                                          MatchDetailsScreen(match: match),
                                        ),
                                      );

                                      if (mounted) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: const AppBottomNavBar(
          currentIndex: 0,
        ),
      ),
    );
  }
}