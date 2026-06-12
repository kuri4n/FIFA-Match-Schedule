class MatchEventModel {
  final String playerName;
  final int minute;
  final String team;
  final String eventType;

  MatchEventModel({
    required this.playerName,
    required this.minute,
    required this.team,
    required this.eventType,
  });

  factory MatchEventModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MatchEventModel(
      playerName: json['playerName'],
      minute: json['minute'],
      team: json['team'],
      eventType: json['eventType'],
    );
  }
}