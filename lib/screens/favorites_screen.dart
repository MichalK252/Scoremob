import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import 'leagues_list_screen.dart';
import 'league_standings_screen.dart';
import 'auth_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _dbService = SupabaseService();
  User? _currentUser;
  late final StreamSubscription<AuthState> _authSubscription;
  late TabController _tabController;

  List<Map<String, dynamic>> _favoriteLeagues = [];
  List<Map<String, dynamic>> _favoriteTeams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUser = Supabase.instance.client.auth.currentUser;
    
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = Supabase.instance.client.auth.currentUser;
        });
        if (_currentUser != null) {
          _loadFavorites();
        }
      }
    });

    if (_currentUser != null) {
      _loadFavorites();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final leagues = await _dbService.fetchFavoriteLeagues();
      final teams = await _dbService.fetchFavoriteTeams();

      if (mounted) {
        setState(() {
          _favoriteLeagues = leagues;
          _favoriteTeams = teams;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _unfavoriteTeam(Map<String, dynamic> team) async {
    try {
      await _dbService.toggleFavoriteTeam({
        'id': team['team_id'],
        'name': team['team_name'],
        'logo': team['team_logo'],
      });
      _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usunięto drużynę z ulubionych'),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(initialIsRegister: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E10),
        elevation: 0,
        title: const Text(
          'Ulubione',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        bottom: user != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.blueAccent,
                indicatorWeight: 3,
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Ligi'),
                  Tab(text: 'Drużyny'),
                ],
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        color: Colors.blueAccent,
        backgroundColor: const Color(0xFF16161A),
        child: user == null ? _buildGuestView() : _buildUserView(),
      ),
    );
  }

  // --- GUEST VIEW ---
  Widget _buildGuestView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.16), width: 1.5),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Ulubione',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Zaloguj się, aby zapisywać ulubione drużyny i ligi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 46,
                child: ElevatedButton(
                  onPressed: _navigateToAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Zaloguj się',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- USER VIEW ---
  Widget _buildUserView() {
    if (_isLoading && _favoriteLeagues.isEmpty && _favoriteTeams.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildLeaguesTab(),
        _buildTeamsTab(),
      ],
    );
  }

  Widget _buildLeaguesTab() {
    if (_favoriteLeagues.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border_rounded,
        title: 'Brak ulubionych lig',
        subtitle: 'Dodaj gwiazdkę w prawym górnym rogu ekranu danej tabeli ligowej, aby zapisać ją tutaj.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteLeagues.length,
      itemBuilder: (context, index) {
        final dbFav = _favoriteLeagues[index];
        final String leagueId = dbFav['league_id'].toString();

        // Find the matched league in LeaguesListScreen to obtain proper color styling
        final matchedLeague = LeaguesListScreen.leagues.firstWhere(
          (l) => l['id'] == leagueId,
          orElse: () => {
            'id': leagueId,
            'code': dbFav['league_code'] ?? '',
            'name': dbFav['league_name'],
            'logo': dbFav['league_logo'] ?? '',
            'color1': const Color(0xFF16161A),
            'color2': const Color(0xFF0C0C0E),
            'accent': Colors.blueAccent,
            'country': 'Międzynarodowe',
          },
        );

        final leagueColor1 = matchedLeague['color1'] as Color;
        final leagueColor2 = matchedLeague['color2'] as Color;
        final accentColor = matchedLeague['accent'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF24242A), width: 1),
            gradient: LinearGradient(
              colors: [leagueColor1, leagueColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeagueStandingsScreen(league: matchedLeague),
                    ),
                  ).then((_) => _loadFavorites()); // Refresh on pop back
                },
                splashColor: accentColor.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: matchedLeague['logo'] as String,
                          errorWidget: (context, url, error) => const Icon(Icons.emoji_events, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              matchedLeague['name'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              matchedLeague['country'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accentColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_favoriteTeams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Brak ulubionych drużyn',
        subtitle: 'Kliknij w dowolny zespół w tabeli i dodaj serduszko w wysuniętym panelu dolnym, aby go tu zapisać.',
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _favoriteTeams.length,
      itemBuilder: (context, index) {
        final team = _favoriteTeams[index];
        final name = team['team_name'] as String;
        final logo = team['team_logo'] as String;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16161A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
          ),
          child: Stack(
            children: [
              // Unfavorite Toggle Button
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _unfavoriteTeam(team),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              // Logo and Name Column
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: logo,
                        width: 50,
                        height: 50,
                        placeholder: (context, url) => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.sports_soccer_rounded,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
