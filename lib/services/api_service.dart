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
    final response = await _client
        .from('teams')
        .select('name, code')
        .order('name', ascending: true);

    return response.map<TeamModel>((row) {
      return TeamModel(
        name: row['name'] ?? '',
        flagCode: row['code'] ?? 'un',
        groupName: '',
      );
    }).toList();
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

    await _client.from('starred_matches').upsert({
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

  Future<void> addReminder(
    int matchId,
    int minutesBefore,
  ) async {
    await _client.from('reminders').upsert({
      'match_id': matchId,
      'minutes_before': minutesBefore,
    });
  }

  Future<void> removeReminder(
    int matchId,
    int minutesBefore,
  ) async {
    await _client
        .from('reminders')
        .delete()
        .eq('match_id', matchId)
        .eq('minutes_before', minutesBefore);
  }

  Future<List<MatchModel>> getMatches() async {
    try {
      
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
            matchDateTime: DateTime.parse(row['kickoff_time']).toLocal(),
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
            fifa_code,
            code
          )
        ''')
        .order('group_name', ascending: true)
        .order('points', ascending: false);

    return response.map<GroupStandingModel>((row) {
      final team = row['teams'];

      return GroupStandingModel(
        groupName: row['group_name'] ?? '',
        teamName: team?['name'] ?? 'Unknown Team',
        flagCode: team?['code'] ?? 'un',
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
        flagCode: team?['code'] ?? 'un',
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
        flagCode: team?['code'] ?? 'un',
        value: row['assists'] ?? 0,
      );
    }).toList();
  }

  Future<List<KnockoutMatchModel>> getKnockoutMatches() async {
    final response = await _client
        .from('knockout_matches')
        .select('''
          match_no,
          round_name,
          team1,
          team2,
          team1_flag_code,
          team2_flag_code,
          status,
          team1_score,
          team2_score,
          bracket_position
        ''')
        .order('bracket_position', ascending: true);

    return response.map<KnockoutMatchModel>((row) {
      return KnockoutMatchModel(
        matchNo: row['match_no'] ?? '',
        roundName: row['round_name'] ?? 'Knockout',
        team1: row['team1'] ?? 'TBD',
        team2: row['team2'] ?? 'TBD',
        team1FlagCode: row['team1_flag_code'] ?? 'un',
        team2FlagCode: row['team2_flag_code'] ?? 'un',
        status: row['status'] ?? 'Scheduled',
        team1Score: row['team1_score'],
        team2Score: row['team2_score'],
      );
    }).toList();
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

  Future<void> recalculateStandings() async {
    final standingsRows = await _client
        .from('standings')
        .select('id, group_name, team_id');

    final Map<int, Map<String, dynamic>> table = {};

    for (final row in standingsRows) {
      table[row['team_id']] = {
        'id': row['id'],
        'played': 0,
        'won': 0,
        'drawn': 0,
        'lost': 0,
        'goals_for': 0,
        'goals_against': 0,
        'goal_difference': 0,
        'points': 0,
      };
    }

    final finishedMatches = await _client
        .from('matches')
        .select('home_team_id, away_team_id, home_score, away_score')
        .eq('status', 'Finished')
        .like('round', 'Group %');

    for (final match in finishedMatches) {
      final homeId = match['home_team_id'];
      final awayId = match['away_team_id'];
      final homeScore = match['home_score'];
      final awayScore = match['away_score'];

      if (homeId == null ||
          awayId == null ||
          homeScore == null ||
          awayScore == null ||
          !table.containsKey(homeId) ||
          !table.containsKey(awayId)) {
        continue;
      }

      final home = table[homeId]!;
      final away = table[awayId]!;

      home['played'] += 1;
      away['played'] += 1;

      home['goals_for'] += homeScore;
      home['goals_against'] += awayScore;

      away['goals_for'] += awayScore;
      away['goals_against'] += homeScore;

      if (homeScore > awayScore) {
        home['won'] += 1;
        home['points'] += 3;
        away['lost'] += 1;
      } else if (homeScore < awayScore) {
        away['won'] += 1;
        away['points'] += 3;
        home['lost'] += 1;
      } else {
        home['drawn'] += 1;
        away['drawn'] += 1;
        home['points'] += 1;
        away['points'] += 1;
      }
    }

    for (final entry in table.entries) {
      final stats = entry.value;

      final goalsFor = stats['goals_for'];
      final goalsAgainst = stats['goals_against'];

      await _client
          .from('standings')
          .update({
            'played': stats['played'],
            'won': stats['won'],
            'drawn': stats['drawn'],
            'lost': stats['lost'],
            'goals_for': goalsFor,
            'goals_against': goalsAgainst,
            'goal_difference': goalsFor - goalsAgainst,
            'points': stats['points'],
          })
          .eq('id', stats['id']);
    }
  }
}