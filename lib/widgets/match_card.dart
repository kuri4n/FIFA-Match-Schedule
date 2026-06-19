import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../theme/app_colors.dart';
import 'flag_widget.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onStarToggle;
  final bool isExpanded;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    required this.onLongPress,
    required this.onStarToggle,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final status = match.status.toLowerCase();
    final isFinished = status == 'finished';
    final isLive = status == 'live';


    return AnimatedScale(
      duration: const Duration(milliseconds: 250),
      scale: isExpanded ? 1.08 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: isExpanded ? 185 : 140,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary1,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: isExpanded ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    match.stageLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              if (match.isStarred && !isExpanded)
                const Positioned(
                  left: 12,
                  top: 12,
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),

              if (isExpanded && !isFinished)
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: onStarToggle,
                    icon: Icon(
                      match.isStarred
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: isExpanded ? 52 : 42,
                  bottom: 20,
                ),
                child: Row(
                  children: [
                    _teamSection(
                      match.homeTeam,
                      match.homeFlagCode,
                    ),
                    _centerSection(context, match, isFinished,isLive),
                    _teamSection(
                      match.awayTeam,
                      match.awayFlagCode,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamSection(String teamName, String flagCode) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FlagWidget(code: flagCode),
          const SizedBox(height: 10),
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerSection(
    BuildContext context,
    MatchModel match,
    bool isFinished,
    bool isLive,
  ) {
    final shouldShowScore =
        (isFinished || isLive) &&
        match.homeScore != null &&
        match.awayScore != null;

    if (shouldShowScore) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${match.homeScore} - ${match.awayScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLive ? 'LIVE' : 'FT',
            style: TextStyle(
              color: isLive ? Colors.greenAccent : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${match.matchDateTime.day}/${match.matchDateTime.month}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          TimeOfDay.fromDateTime(match.matchDateTime).format(context),
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}