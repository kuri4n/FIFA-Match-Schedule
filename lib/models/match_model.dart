class MatchModel {
  final int id;
  final int? homeTeamId;
  final int? awayTeamId;
  final String homeTeam;
  final String awayTeam;

  final String homeFlagCode;
  final String awayFlagCode;

  final DateTime matchDateTime;

  final String status;
  final String stageLabel;

  final int? homeScore;
  final int? awayScore;

  bool isStarred;

  MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeFlagCode,
    required this.awayFlagCode,
    required this.matchDateTime,
    required this.status,
    required this.stageLabel,
    this.homeScore,
    this.awayScore,
    this.isStarred = false,
  });
}