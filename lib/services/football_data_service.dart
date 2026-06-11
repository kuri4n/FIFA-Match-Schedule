import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FootballDataService {
  static const String _baseUrl = 'https://api.football-data.org/v4';

  static String get _apiKey =>
      dotenv.env['FOOTBALL_DATA_KEY'] ?? '';

  Map<String, String> get _headers {
    return {
      'X-Auth-Token': _apiKey,
    };
  }
  Future<void> syncWorldCupMatches() async {
    final uri = Uri.parse(
      '$_baseUrl/competitions/WC/matches',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch World Cup matches: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final matches = data['matches'] as List;

    for (final match in matches) {
      final matchId = match['id'];
      final status = match['status'];

      final score = match['score'];
      final fullTime = score?['fullTime'];

      final homeScore = fullTime?['home'];
      final awayScore = fullTime?['away'];

      await Supabase.instance.client
          .from('matches')
          .update({
            'football_data_status': status,
            'status': _mapStatus(status),
            'home_score': homeScore,
            'away_score': awayScore,
            'kickoff_time': match['utcDate'],
            'last_synced_at': DateTime.now().toIso8601String(),
          })
          .eq('football_data_match_id', matchId);
    }

    print('World Cup matches synced successfully');
  }

  String _mapStatus(String? status) {
    switch (status) {
      case 'TIMED':
      case 'SCHEDULED':
        return 'Scheduled';
      case 'IN_PLAY':
      case 'PAUSED':
        return 'Live';
      case 'FINISHED':
        return 'Finished';
      case 'POSTPONED':
        return 'Postponed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  Future<void> printKnockoutMatchMappingSql() async {
    final uri = Uri.parse(
      '$_baseUrl/competitions/WC/matches',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    final matches = data['matches'] as List;

    final knockoutMatches = matches
        .where((match) => match['stage'] != 'GROUP_STAGE')
        .toList();

    for (int i = 0; i < knockoutMatches.length; i++) {
      final match = knockoutMatches[i];

      final matchNo = 'M${73 + i}';
      final matchId = match['id'];
      final status = match['status'];
      final utcDate = match['utcDate'];
      final stage = match['stage'];

      if (matchId == null || status == null || utcDate == null) {
        continue;
      }

      print(
        "UPDATE knockout_matches "
        "SET football_data_match_id = $matchId, "
        "football_data_status = '$status', "
        "kickoff_time = '$utcDate' "
        "WHERE match_no = '$matchNo'; "
        "-- stage=$stage",
      );
    }
  }

  
}