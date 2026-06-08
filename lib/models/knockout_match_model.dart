class KnockoutMatchModel {
  final String matchNo;
  final String roundName;

  final String team1;
  final String team2;

  final String? team1FlagCode;
  final String? team2FlagCode;

  final String status;

  final int? team1Score;
  final int? team2Score;

  KnockoutMatchModel({
    required this.matchNo,
    required this.roundName,
    required this.team1,
    required this.team2,
    this.team1FlagCode,
    this.team2FlagCode,
    required this.status,
    this.team1Score,
    this.team2Score,
  });
}