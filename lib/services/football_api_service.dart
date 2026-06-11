import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FootballApiService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  // Replace this with your API-Football key
  static String get _apiKey =>
    dotenv.env['API_FOOTBALL_KEY'] ?? '';

  Map<String, String> get _headers {
    return {
      'x-apisports-key': _apiKey,
    };
  }

  void testApiKey() {
    print('API Key Loaded: ${_apiKey.isNotEmpty}');
  }

  Future<void> getWorldCupFixtures() async {
    final uri = Uri.parse(
      '$_baseUrl/fixtures?league=1&season=2026',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    print('FIXTURES STATUS: ${response.statusCode}');
    print(response.body);
  }

  Future<void> testConnection() async {
    final uri = Uri.parse('$_baseUrl/status');

    final response = await http.get(
      uri,
      headers: _headers,
    );

    print('API STATUS CODE: ${response.statusCode}');

    final data = jsonDecode(response.body);
    print('API STATUS RESPONSE: $data');
  }

  Future<List<dynamic>> getFixtures({
    required int leagueId,
    required int season,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/fixtures?league=$leagueId&season=$season',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch fixtures: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return data['response'] ?? [];
  }
  
  Future<void> searchWorldCupLeague() async {
    final uri = Uri.parse(
      '$_baseUrl/leagues?search=world cup',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    print('LEAGUES STATUS: ${response.statusCode}');
    print(response.body);
  }
}