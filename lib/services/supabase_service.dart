import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  // --- LEAGUES ---

  Future<List<Map<String, dynamic>>> fetchFavoriteLeagues() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final List<dynamic> response = await _client
          .from('favorite_leagues')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching favorite leagues: $e');
      return [];
    }
  }

  Future<bool> isLeagueFavorite(String leagueId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('favorite_leagues')
          .select('id')
          .eq('user_id', userId)
          .eq('league_id', leagueId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking league favorite status: $e');
      return false;
    }
  }

  Future<void> toggleFavoriteLeague(Map<String, dynamic> league) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Musisz być zalogowany, aby zarządzać ulubionymi.');
    }

    final leagueId = league['id'].toString();
    final isFav = await isLeagueFavorite(leagueId);

    try {
      if (isFav) {
        await _client
            .from('favorite_leagues')
            .delete()
            .eq('user_id', userId)
            .eq('league_id', leagueId);
      } else {
        await _client.from('favorite_leagues').insert({
          'user_id': userId,
          'league_id': leagueId,
          'league_name': league['name'],
          'league_logo': league['logo'],
          'league_code': league['code'],
        });
      }
    } catch (e) {
      print('Error toggling favorite league: $e');
      throw Exception('Błąd zapisu w bazie Supabase.');
    }
  }

  // --- TEAMS ---

  Future<List<Map<String, dynamic>>> fetchFavoriteTeams() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final List<dynamic> response = await _client
          .from('favorite_teams')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching favorite teams: $e');
      return [];
    }
  }

  Future<bool> isTeamFavorite(String teamId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('favorite_teams')
          .select('id')
          .eq('user_id', userId)
          .eq('team_id', teamId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking team favorite status: $e');
      return false;
    }
  }

  Future<void> toggleFavoriteTeam(Map<String, dynamic> team) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Musisz być zalogowany, aby zarządzać ulubionymi.');
    }

    final teamId = team['id'].toString();
    final isFav = await isTeamFavorite(teamId);

    try {
      if (isFav) {
        await _client
            .from('favorite_teams')
            .delete()
            .eq('user_id', userId)
            .eq('team_id', teamId);
      } else {
        await _client.from('favorite_teams').insert({
          'user_id': userId,
          'team_id': teamId,
          'team_name': team['name'],
          'team_logo': team['logo'],
        });
      }
    } catch (e) {
      print('Error toggling favorite team: $e');
      throw Exception('Błąd zapisu w bazie Supabase.');
    }
  }
}
