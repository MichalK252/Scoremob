import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FootballApiService {
  static const String _baseUrl = 'https://api.football-data.org/v4';

  Future<List<Map<String, dynamic>>> fetchTodayMatches() async {
    final apiKey = dotenv.env['FOOTBALL_API_KEY'];
    if (apiKey == null) {
      throw Exception('Brak klucza FOOTBALL_API_KEY w pliku .env');
    }

    final url = Uri.parse('$_baseUrl/matches');
    final response = await http.get(
      url,
      headers: {
        'X-Auth-Token': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List matches = data['matches'] ?? [];
      
      return matches.map((match) {
        return {
          'homeTeam': match['homeTeam']['shortName'] ?? match['homeTeam']['name'] ?? 'Nieznany',
          'homeTeamCrest': match['homeTeam']['crest'] ?? '',
          'awayTeam': match['awayTeam']['shortName'] ?? match['awayTeam']['name'] ?? 'Nieznany',
          'awayTeamCrest': match['awayTeam']['crest'] ?? '',
          'scoreHome': match['score']['fullTime']['home'],
          'scoreAway': match['score']['fullTime']['away'],
          'status': match['status'] ?? 'SCHEDULED',
          'utcDate': match['utcDate'] ?? '',
          'league': match['competition']['name'] ?? 'Nieznana liga',
          'leagueCode': match['competition']['code'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Nie udało się pobrać meczów: ${response.statusCode}');
    }
  }
}
