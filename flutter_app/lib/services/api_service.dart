import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_standing_model.dart';
import '../models/knockout_match_model.dart';
import '../models/match_event_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/player_stat_model.dart';
import '../models/team_model.dart';

class ApiService {
  final SupabaseClient _client =
      Supabase.instance.client;

  Future<List<TeamModel>> getTeams() async {
    return [
      TeamModel(name: 'Argentina', flagCode: 'ar', groupName: 'Group A'),
      TeamModel(name: 'Brazil', flagCode: 'br', groupName: 'Group A'),
      TeamModel(name: 'France', flagCode: 'fr', groupName: 'Group B'),
      TeamModel(name: 'Germany', flagCode: 'de', groupName: 'Group B'),
      TeamModel(name: 'Spain', flagCode: 'es', groupName: 'Group C'),
      TeamModel(name: 'Portugal', flagCode: 'pt', groupName: 'Group C'),
    ];
  }

  Future<String> _getLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('local_user_id');

    if (userId == null) {
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('local_user_id', userId);
    }

    return userId;
  }

  Future<void> starMatch(int matchId) async {
    final userId = await _getLocalUserId();

    await _client.from('starred_matches').insert({
      'user_id': userId,
      'match_id': matchId,
    });
  }

  Future<void> unstarMatch(int matchId) async {
    final userId = await _getLocalUserId();

    await _client
        .from('starred_matches')
        .delete()
        .eq('user_id', userId)
        .eq('match_id', matchId);
  }

  Future<void> addReminder(int matchId, int minutesBefore) async {
    final userId = await _getLocalUserId();

    await _client.from('reminders').insert({
      'user_id': userId,
      'match_id': matchId,
      'minutes_before': minutesBefore,
    });
  }

  Future<void> removeReminder(int matchId) async {
    final userId = await _getLocalUserId();

    await _client
        .from('reminders')
        .delete()
        .eq('user_id', userId)
        .eq('match_id', matchId);
  }

  Future<List<MatchModel>> getMatches() async {
    try {
      print('DEBUG: Fetching matches from Supabase...');
      
      final response = await _client
          .from('matches')
          .select('''
            id,
            home_team_id,
            away_team_id,
            venue,
            kickoff_time,
            status,
            home_score,
            away_score,
            round,
            is_hot,
            home_team:home_team_id (
              name,
              fifa_code,
              code
            ),
            away_team:away_team_id (
              name,
              fifa_code,
              code
            )
          ''')
          .order('kickoff_time', ascending: true);

      print('DEBUG: Got ${response.length} matches from API');

      final prefs = await SharedPreferences.getInstance();
      final favoriteTeamCode = prefs.getString('favorite_team_code');
      final favoriteTeamName = prefs.getString('favorite_team_name');

      final userId = await _getLocalUserId();

      final starredRows = await _client
          .from('starred_matches')
          .select('match_id')
          .eq('user_id', userId);

      final starredMatchIds = starredRows
          .map((row) => row['match_id'] as int)
          .toSet();

      return response.map((row) {
        try {
          final homeTeam = row['home_team'];
          final awayTeam = row['away_team'];

          return MatchModel(
            id: row['id'],
            homeTeamId: row['home_team_id'],
            awayTeamId: row['away_team_id'],
            homeTeam: homeTeam?['name'] ?? 'TBD',
            awayTeam: awayTeam?['name'] ?? 'TBD',
            homeFlagCode: homeTeam?['code'] ?? 'un',
            awayFlagCode: awayTeam?['code'] ?? 'un',
            matchDateTime: DateTime.parse(row['kickoff_time']),
            status: row['status'] ?? 'Scheduled',
            stageLabel: row['round'] ?? 'Group Stage',
            homeScore: row['home_score'],
            awayScore: row['away_score'],
            isStarred:
                starredMatchIds.contains(row['id']) ||
                (row['is_hot'] ?? false) ||
                homeTeam?['code'] == favoriteTeamCode ||
                awayTeam?['code'] == favoriteTeamCode ||
                homeTeam?['name'] == favoriteTeamName ||
                awayTeam?['name'] == favoriteTeamName,
          );
        } catch (e) {
          print('DEBUG: Error parsing match row: $e');
          print('DEBUG: Row data: $row');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('DEBUG: Error in getMatches: $e');
      rethrow;
    }
  }

  Future<List<GroupStandingModel>> getStandings() async {
    final response = await _client
        .from('standings')
        .select('''
          group_name,
          played,
          won,
          drawn,
          lost,
          goals_for,
          goals_against,
          goal_difference,
          points,
          teams (
            name,
            fifa_code
          )
        ''')
        .order('group_name', ascending: true)
        .order('points', ascending: false);

    return response.map<GroupStandingModel>((row) {
      final team = row['teams'];

      return GroupStandingModel(
        groupName: row['group_name'] ?? '',
        teamName: team?['name'] ?? 'Unknown Team',
        flagCode: _mapFifaCodeToFlagCode(
          team?['fifa_code'] ?? '',
        ),
        played: row['played'] ?? 0,
        wins: row['won'] ?? 0,
        draws: row['drawn'] ?? 0,
        losses: row['lost'] ?? 0,
        goalsFor: row['goals_for'] ?? 0,
        goalsAgainst: row['goals_against'] ?? 0,
        goalDifference: row['goal_difference'] ?? 0,
        points: row['points'] ?? 0,
      );
    }).toList();
  }

  String _mapFifaCodeToFlagCode(String fifaCode) {
    final code = fifaCode.toUpperCase();

    const map = {
      'ARG': 'ar',
      'BRA': 'br',
      'FRA': 'fr',
      'GER': 'de',
      'ESP': 'es',
      'POR': 'pt',
      'NED': 'nl',
      'URU': 'uy',
      'ENG': 'gb',
      'BEL': 'be',
    };

    return map[code] ?? fifaCode.toLowerCase();
  }

  Future<List<PlayerStatModel>> getTopScorers() async {
    final response = await _client
        .from('players')
        .select('''
          name,
          goals,
          team:team_id (
            name,
            fifa_code,
            code
          )
        ''')
        .order('goals', ascending: false)
        .limit(10);

    return response.map<PlayerStatModel>((row) {
      final team = row['team'];

      return PlayerStatModel(
        playerName: row['name'] ?? 'Unknown',
        teamName: team?['name'] ?? 'Unknown Team',
        flagCode: _mapFifaCodeToFlagCode(
          team?['fifa_code'] ?? '',
        ),
        value: row['goals'] ?? 0,
      );
    }).toList();
  }

  Future<List<PlayerStatModel>> getTopAssists() async {
    final response = await _client
        .from('players')
        .select('''
          name,
          assists,
          team:team_id (
            name,
            fifa_code,
            code
          )
        ''')
        .order('assists', ascending: false)
        .limit(10);

    return response.map<PlayerStatModel>((row) {
      final team = row['team'];

      return PlayerStatModel(
        playerName: row['name'] ?? 'Unknown',
        teamName: team?['name'] ?? 'Unknown Team',
        flagCode: _mapFifaCodeToFlagCode(
          team?['fifa_code'] ?? '',
        ),
        value: row['assists'] ?? 0,
      );
    }).toList();
  }

  Future<List<KnockoutMatchModel>> getKnockoutMatches() async {
    return [
      KnockoutMatchModel(
        matchNo: 'M73',
        roundName: 'Round of 32',
        team1: 'Winner Group A',
        team2: '3rd Group C/E/F/H/I',
        team1FlagCode: 'un',
        team2FlagCode: 'un',
        status: 'Scheduled',
      ),
      KnockoutMatchModel(
        matchNo: 'M74',
        roundName: 'Round of 32',
        team1: 'Runner-up Group A',
        team2: 'Runner-up Group B',
        team1FlagCode: 'un',
        team2FlagCode: 'un',
        status: 'Scheduled',
      ),
      KnockoutMatchModel(
        matchNo: 'M104',
        roundName: 'Final',
        team1: 'Winner M101',
        team2: 'Winner M102',
        team1FlagCode: 'un',
        team2FlagCode: 'un',
        status: 'Scheduled',
      ),
    ];
  }

  Future<List<PlayerModel>> getSquadByTeamId(int teamId) async {
    final response = await _client
        .from('players')
        .select('name, position')
        .eq('team_id', teamId)
        .order('jersey_number', ascending: true);

    return response.map((row) {
      return PlayerModel(
        name: row['name'] ?? '',
        position: row['position'] ?? '',
      );
    }).toList();
  }

  Future<List<MatchEventModel>> getMatchEvents(int matchId) async {
    final response = await _client
        .from('match_events')
        .select('''
          event_type,
          minute,
          players (
            name,
            teams (
              name
            )
          )
        ''')
        .eq('match_id', matchId)
        .order('minute', ascending: true);

    return response.map((row) {
      final player = row['players'];
      final team = player?['teams'];

      return MatchEventModel(
        playerName: player?['name'] ?? 'Unknown Player',
        minute: row['minute'] ?? 0,
        team: team?['name'] ?? '',
        eventType: row['event_type'] ?? '',
      );
    }).toList();
  }
}