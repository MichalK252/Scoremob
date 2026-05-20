import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FootballApiService {
  // Pamięć podręczna na mecze pobrane według dat (np. "2026-05-20" -> lista meczów)
  final Map<String, List<Map<String, dynamic>>> _dateMatchesCache = {};

  String get _baseUrl {
    final provider = dotenv.env['FOOTBALL_API_PROVIDER']?.toLowerCase() ?? 'api-sports';
    if (provider == 'rapidapi') {
      return 'https://api-football-v1.p.rapidapi.com/v3';
    }
    return 'https://v3.football.api-sports.io';
  }

  Map<String, String> _getHeaders() {
    final apiKey = dotenv.env['FOOTBALL_API_KEY']?.trim();
    if (apiKey == null) {
      throw Exception('Brak klucza FOOTBALL_API_KEY w pliku .env');
    }
    final provider = dotenv.env['FOOTBALL_API_PROVIDER']?.toLowerCase() ?? 'api-sports';
    if (provider == 'rapidapi') {
      return {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
      };
    }
    return {
      'x-apisports-key': apiKey,
    };
  }

  String? _getFootballDataKey() {
    return dotenv.env['FOOTBALL_DATA_KEY']?.trim() ?? dotenv.env['FOOTBALL_API_KEY']?.trim();
  }

  void _checkResponseErrors(Map<String, dynamic> decoded) {
    final errors = decoded['errors'];
    if (errors != null) {
      if (errors is Map && errors.isNotEmpty) {
        throw Exception(errors.values.join(', '));
      } else if (errors is List && errors.isNotEmpty) {
        throw Exception(errors.join(', '));
      }
    }
  }

  String _mapStatus(String? shortStatus) {
    switch (shortStatus) {
      case 'NS':
      case 'TBD':
        return 'SCHEDULED';
      case '1H':
      case '2H':
      case 'ET':
      case 'BT':
        return 'IN_PLAY';
      case 'HT':
        return 'PAUSED';
      case 'FT':
      case 'AET':
      case 'PEN':
        return 'FINISHED';
      case 'PST':
        return 'POSTPONED';
      case 'CANC':
        return 'CANCELED';
      case 'SUSP':
        return 'SUSPENDED';
      default:
        return 'SCHEDULED';
    }
  }

  Future<List<Map<String, dynamic>>> fetchMatches({DateTime? date}) async {
    date ??= DateTime.now();
    final dateStr = date.toIso8601String().split('T')[0];

    // Sprawdź cache
    if (_dateMatchesCache.containsKey(dateStr)) {
      print('Zwracanie meczów z pamięci podręcznej dla daty: $dateStr');
      return _dateMatchesCache[dateStr]!;
    }

    try {
      // 1. Spróbuj pobrać z API-Football
      final matches = await _fetchMatchesApiFootball(date);
      _dateMatchesCache[dateStr] = matches;
      return matches;
    } catch (e) {
      print('API-Football nie powiodło się, przełączanie na Football-Data.org (Fallback): $e');
      try {
        // 2. Fallback na Football-Data.org
        final matches = await _fetchMatchesFootballData(date);
        _dateMatchesCache[dateStr] = matches;
        return matches;
      } catch (fallbackError) {
        print('Zapasowe API również nie powiodło się: $fallbackError');
        throw Exception('Błąd API głównych i zapasowych.\nAPI-Football: $e\nFootball-Data: $fallbackError');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMatchesApiFootball(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final url = Uri.parse('$_baseUrl/fixtures?date=$dateStr');
    print('Pobieranie meczów z API-Football: $url');

    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      _checkResponseErrors(decoded);
      final List list = decoded['response'] ?? [];

      return list.map((item) {
        final fixture = item['fixture'] ?? {};
        final league = item['league'] ?? {};
        final teams = item['teams'] ?? {};
        final goals = item['goals'] ?? {};
        final score = item['score'] ?? {};

        return {
          'id': fixture['id'],
          'homeTeam': teams['home']?['name'] ?? 'Nieznany',
          'homeTeamCrest': teams['home']?['logo'] ?? '',
          'homeTeamId': teams['home']?['id'],
          'awayTeam': teams['away']?['name'] ?? 'Nieznany',
          'awayTeamCrest': teams['away']?['logo'] ?? '',
          'awayTeamId': teams['away']?['id'],
          'scoreHome': goals['home'],
          'scoreAway': goals['away'],
          'status': _mapStatus(fixture['status']?['short']),
          'utcDate': fixture['date'] ?? '',
          'league': league['name'] ?? 'Nieznana liga',
          'leagueCode': (league['id'] ?? '').toString(),
          'referee': fixture['referee'] ?? 'Brak danych',
          'venue': fixture['venue']?['name'] ?? 'Brak danych',
          'round': league['round'] ?? '',
          'halfTimeHome': score['halftime']?['home'],
          'halfTimeAway': score['halftime']?['away'],
          'source': 'api-football',
        };
      }).toList();
    } else {
      throw Exception('Błąd HTTP ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMatchesFootballData(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final nextDateStr = date.add(const Duration(days: 1)).toIso8601String().split('T')[0];
    final apiKey = _getFootballDataKey();
    if (apiKey == null) {
      throw Exception('Brak klucza dla planu zapasowego (FOOTBALL_DATA_KEY) w .env');
    }

    // W darmowej wersji Football-Data.org zapytania o pojedynczy dzień w przyszłości (dateFrom == dateTo) 
    // zwracają pustą listę. Aby to obejść, pytamy o zakres 2 dni (dateFrom do dateFrom + 1 dzień) i filtrujemy wyniki w aplikacji.
    final url = Uri.parse('https://api.football-data.org/v4/matches?dateFrom=$dateStr&dateTo=$nextDateStr');
    print('Pobieranie meczów z Football-Data.org (Fallback): $url');

    final response = await http.get(
      url,
      headers: {
        'X-Auth-Token': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['matches'] ?? [];

      // Filtrujemy, aby zachować tylko mecze z wybranej daty
      final filteredList = list.where((item) {
        final matchUtcDate = item['utcDate'] as String?;
        if (matchUtcDate == null) return false;
        return matchUtcDate.startsWith(dateStr);
      }).toList();

      return filteredList.map((item) {
        final homeTeam = item['homeTeam'] ?? {};
        final awayTeam = item['awayTeam'] ?? {};
        final score = item['score'] ?? {};
        final competition = item['competition'] ?? {};
        final referees = item['referees'] as List? ?? [];
        
        final refereeName = referees.isNotEmpty 
            ? referees.map((r) => r['name']).join(', ') 
            : 'Brak danych';

        return {
          'id': item['id'],
          'homeTeam': homeTeam['name'] ?? 'Nieznany',
          'homeTeamCrest': homeTeam['crest'] ?? '',
          'homeTeamId': homeTeam['id'],
          'awayTeam': awayTeam['name'] ?? 'Nieznany',
          'awayTeamCrest': awayTeam['crest'] ?? '',
          'awayTeamId': awayTeam['id'],
          'scoreHome': score['fullTime']?['home'],
          'scoreAway': score['fullTime']?['away'],
          'status': item['status'] ?? 'SCHEDULED',
          'utcDate': item['utcDate'] ?? '',
          'league': competition['name'] ?? 'Nieznana liga',
          'leagueCode': competition['code'] ?? '',
          'referee': refereeName,
          'venue': item['venue'] ?? 'Brak danych',
          'round': item['matchday'] != null ? 'Kolejka ${item['matchday']}' : '',
          'halfTimeHome': score['halfTime']?['home'],
          'halfTimeAway': score['halfTime']?['away'],
          'source': 'football-data',
        };
      }).toList();
    } else {
      throw Exception('Błąd zapasowego API HTTP ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFixtureEvents(int fixtureId, {required String source}) async {
    if (source == 'football-data') {
      return [];
    }

    final url = Uri.parse('$_baseUrl/fixtures/events?fixture=$fixtureId');
    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      _checkResponseErrors(decoded);
      final List list = decoded['response'] ?? [];
      return list.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Błąd podczas pobierania zdarzeń: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFixtureLineups(int fixtureId, {required String source}) async {
    if (source == 'football-data') {
      return [];
    }

    final url = Uri.parse('$_baseUrl/fixtures/lineups?fixture=$fixtureId');
    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      _checkResponseErrors(decoded);
      final List list = decoded['response'] ?? [];
      return list.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Błąd podczas pobierania składów: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFixtureStatistics(int fixtureId, {required String source}) async {
    if (source == 'football-data') {
      return [];
    }

    final url = Uri.parse('$_baseUrl/fixtures/statistics?fixture=$fixtureId');
    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      _checkResponseErrors(decoded);
      final List list = decoded['response'] ?? [];
      return list.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Błąd podczas pobierania statystyk: ${response.statusCode}');
    }
  }

  int _getSeasonYear() {
    final now = DateTime.now();
    return now.month < 7 ? now.year - 1 : now.year;
  }

  Future<List<Map<String, dynamic>>> fetchStandings({
    required String leagueId,
    required String leagueCode,
    int? season,
  }) async {
    try {
      // 1. Spróbuj pobrać z API-Football
      return await _fetchStandingsApiFootball(leagueId, season);
    } catch (e) {
      print('API-Football standings failed, switching to Football-Data.org: $e');
      try {
        // 2. Fallback na Football-Data.org
        return await _fetchStandingsFootballData(leagueCode, season);
      } catch (fallbackError) {
        print('Fallback standings failed: $fallbackError');
        throw Exception('Błąd pobierania tabeli ligowej z obu API.\nAPI-Football: $e\nFootball-Data: $fallbackError');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStandingsApiFootball(String leagueId, int? season) async {
    final seasonYear = season ?? _getSeasonYear();
    final url = Uri.parse('$_baseUrl/standings?league=$leagueId&season=$seasonYear');
    print('Pobieranie tabeli z API-Football: $url');

    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      _checkResponseErrors(decoded);
      
      final List results = decoded['response'] ?? [];
      if (results.isEmpty) return [];

      final leagueData = results[0]['league'] ?? {};
      final List standingsGroups = leagueData['standings'] ?? [];
      if (standingsGroups.isEmpty) return [];

      final List standingsList = standingsGroups[0] ?? [];

      return standingsList.map((item) {
        final team = item['team'] ?? {};
        final all = item['all'] ?? {};
        return {
          'teamId': team['id']?.toString() ?? '',
          'rank': item['rank'] ?? 0,
          'teamName': team['name'] ?? 'Nieznana',
          'teamLogo': team['logo'] ?? '',
          'points': item['points'] ?? 0,
          'played': all['played'] ?? 0,
          'won': all['win'] ?? 0,
          'draw': all['draw'] ?? 0,
          'lost': all['lose'] ?? 0,
          'goalsFor': all['goals']?['for'] ?? 0,
          'goalsAgainst': all['goals']?['against'] ?? 0,
          'goalsDiff': item['goalsDiff'] ?? 0,
          'form': item['form'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Błąd HTTP ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStandingsFootballData(String leagueCode, int? season) async {
    final apiKey = _getFootballDataKey();
    if (apiKey == null) {
      throw Exception('Brak klucza dla planu zapasowego (FOOTBALL_DATA_KEY) w .env');
    }

    final seasonParam = season != null ? '?season=$season' : '';
    final url = Uri.parse('https://api.football-data.org/v4/competitions/$leagueCode/standings$seasonParam');
    print('Pobieranie tabeli z Football-Data.org: $url');

    final response = await http.get(
      url,
      headers: {
        'X-Auth-Token': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List standings = decoded['standings'] ?? [];
      if (standings.isEmpty) return [];

      final List table = standings[0]['table'] ?? [];
      return table.map((item) {
        final team = item['team'] ?? {};
        return {
          'teamId': team['id']?.toString() ?? '',
          'rank': item['position'] ?? 0,
          'teamName': team['name'] ?? 'Nieznana',
          'teamLogo': team['crest'] ?? '',
          'points': item['points'] ?? 0,
          'played': item['playedGames'] ?? 0,
          'won': item['won'] ?? 0,
          'draw': item['draw'] ?? 0,
          'lost': item['lost'] ?? 0,
          'goalsFor': item['goalsFor'] ?? 0,
          'goalsAgainst': item['goalsAgainst'] ?? 0,
          'goalsDiff': item['goalDifference'] ?? 0,
          'form': item['form'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Błąd HTTP ${response.statusCode}');
    }
  }
}
