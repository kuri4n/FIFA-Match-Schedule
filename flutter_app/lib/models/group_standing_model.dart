class GroupStandingModel {
  final String groupName;
  final String teamName;
  final String flagCode;

  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  GroupStandingModel({
    required this.groupName,
    required this.teamName,
    required this.flagCode,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });
}