class PlayerModel {
  final String name;
  final String position;

  PlayerModel({
    required this.name,
    required this.position,
  });

  factory PlayerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PlayerModel(
      name: json['name'],
      position: json['position'] ?? '',
    );
  }
}