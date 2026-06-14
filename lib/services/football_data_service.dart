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
  Future<void> syncKnockoutMatches() async {
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
      final stage = match['stage'];

      if (stage == 'GROUP_STAGE') continue;

      final matchId = match['id'];
      final status = match['status'];
      final utcDate = match['utcDate'];

      final home = match['homeTeam'];
      final away = match['awayTeam'];

      final score = match['score'];
      final fullTime = score?['fullTime'];

      final homeScore = fullTime?['home'];
      final awayScore = fullTime?['away'];

      final updateData = <String, dynamic>{
        'football_data_status': status,
        'status': _mapStatus(status),
        'team1_score': homeScore,
        'team2_score': awayScore,
        'kickoff_time': utcDate,
        'last_synced_at': DateTime.now().toIso8601String(),
      };

      if (home != null && home['name'] != null && home['tla'] != null) {
        updateData['team1'] = home['name'];
        updateData['team1_flag_code'] = home['tla'].toString().toLowerCase();
      }

      if (away != null && away['name'] != null && away['tla'] != null) {
        updateData['team2'] = away['name'];
        updateData['team2_flag_code'] = away['tla'].toString().toLowerCase();
      }

      await Supabase.instance.client
          .from('knockout_matches')
          .update(updateData)
          .eq('football_data_match_id', matchId);
    }

  }
  Future<void> syncWorldCupScorers() async {
    final uri = Uri.parse(
      '$_baseUrl/competitions/WC/scorers?season=2026&limit=100',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch World Cup scorers: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final scorers = data['scorers'] as List;

    final client = Supabase.instance.client;

    for (final scorer in scorers) {
      final player = scorer['player'];
      final team = scorer['team'];

      final footballDataPlayerId = player['id'];
      final playerName = player['name'];
      final footballDataTeamId = team['id'];

      final goals = scorer['goals'] ?? 0;
      final assists = scorer['assists'] ?? 0;

      final teamRows = await client
          .from('teams')
          .select('id')
          .eq('football_data_team_id', footballDataTeamId)
          .limit(1);

      if (teamRows.isEmpty) {
        continue;
      }

      final teamId = teamRows.first['id'];

      final existingPlayerRows = await client
          .from('players')
          .select('id')
          .eq('football_data_player_id', footballDataPlayerId)
          .limit(1);

      if (existingPlayerRows.isNotEmpty) {
        await client
            .from('players')
            .update({
              'goals': goals,
              'assists': assists,
            })
            .eq('football_data_player_id', footballDataPlayerId);
      } else {
        final nameMatchRows = await client
            .from('players')
            .select('id')
            .eq('team_id', teamId)
            .eq('name', playerName)
            .limit(1);

        if (nameMatchRows.isNotEmpty) {
          await client
              .from('players')
              .update({
                'football_data_player_id': footballDataPlayerId,
                'goals': goals,
                'assists': assists,
              })
              .eq('id', nameMatchRows.first['id']);
        } else {
          await client.from('players').insert({
            'team_id': teamId,
            'name': playerName,
            'position': player['section'],
            'jersey_number': player['shirtNumber'],
            'goals': goals,
            'assists': assists,
            'football_data_player_id': footballDataPlayerId,
          });
        }
      }
    }
  }
  
}