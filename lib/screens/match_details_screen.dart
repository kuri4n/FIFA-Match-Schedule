import 'package:flutter/material.dart';

import '../models/match_event_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/flag_widget.dart';
import '../services/notification_service.dart';

class MatchDetailsScreen extends StatefulWidget {
  final MatchModel match;

  const MatchDetailsScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchDetailsScreen> createState() =>
      _MatchDetailsScreenState();
}

class _MatchDetailsScreenState
    extends State<MatchDetailsScreen> {
  late Future<List<PlayerModel>> homeSquadFuture;
  late Future<List<PlayerModel>> awaySquadFuture;
  late Future<List<MatchEventModel>> eventsFuture;

  @override
  void initState() {
    super.initState();

    homeSquadFuture = ApiService().getSquadByTeamId(widget.match.homeTeamId);
    awaySquadFuture = ApiService().getSquadByTeamId(widget.match.awayTeamId);
    eventsFuture = ApiService().getMatchEvents(widget.match.id);
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
          'Match Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.match.status != 'Finished')
            IconButton(
              onPressed: () {
                setState(() {
                  widget.match.isStarred =
                      !widget.match.isStarred;
                });
              },
              icon: Icon(
                widget.match.isStarred
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary1,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    widget.match.stageLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            FlagWidget(
                              code: widget.match.homeFlagCode,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.match.homeTeam,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: _centerSection(),
                      ),

                      Expanded(
                        child: Column(
                          children: [
                            FlagWidget(
                              code: widget.match.awayFlagCode,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.match.awayTeam,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Goals',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  FutureBuilder<List<MatchEventModel>>(
                    future: eventsFuture,
                    builder: (context, snapshot) {
                      final events = snapshot.data ?? [];

                      final homeGoals = events.where((event) {
                        return event.team == widget.match.homeTeam &&
                            event.eventType == 'goal';
                      }).toList();

                      final awayGoals = events.where((event) {
                        return event.team == widget.match.awayTeam &&
                            event.eventType == 'goal';
                      }).toList();

                      if (homeGoals.isEmpty && awayGoals.isEmpty) {
                        return const Text(
                          'No goals recorded',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _goalColumn(homeGoals),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _goalColumn(awayGoals),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (widget.match.status != 'Finished')
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary2,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      backgroundColor: AppColors.secondary1,
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Set Reminder',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                ),
                                title: const Text(
                                  '1 hour before kickoff',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);

                                  await ApiService().addReminder(
                                    widget.match.id,
                                    60,
                                  );

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reminder set for 1 hour before kickoff'),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                ),
                                title: const Text(
                                  '15 minutes before kickoff',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);

                                  await ApiService().addReminder(
                                    widget.match.id,
                                    15,
                                  );

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reminder set for 15 minutes before kickoff'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('Set Reminder'),
                ),
              ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary1,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        FlagWidget(
                          code: widget.match.homeFlagCode,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.match.homeTeam} Squad',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<PlayerModel>>(
                          future: homeSquadFuture,
                          builder: (context, snapshot) {
                            final players = snapshot.data ?? [];

                            return Column(
                              children: players.map((player) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    player.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  Expanded(
                    child: Column(
                      children: [
                        FlagWidget(
                          code: widget.match.awayFlagCode,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.match.awayTeam} Squad',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<PlayerModel>>(
                          future: awaySquadFuture,
                          builder: (context, snapshot) {
                            final players = snapshot.data ?? [];

                            return Column(
                              children: players.map((player) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    player.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerSection() {
    if (widget.match.status == 'Finished') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${widget.match.homeScore ?? 0} - ${widget.match.awayScore ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'FT',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${widget.match.matchDateTime.day}/${widget.match.matchDateTime.month}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          TimeOfDay.fromDateTime(
            widget.match.matchDateTime,
          ).format(context),
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _goalColumn(List<MatchEventModel> goals) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: goals.map((goal) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_soccer,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  "${goal.playerName} ${goal.minute}'",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}