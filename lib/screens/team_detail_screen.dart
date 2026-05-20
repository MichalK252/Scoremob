import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/football_api.dart';
import '../services/supabase_service.dart';
import 'match_detail_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  final String teamName;
  final String teamLogo;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> with SingleTickerProviderStateMixin {
  final FootballApiService _apiService = FootballApiService();
  final SupabaseService _dbService = SupabaseService();

  late TabController _tabController;
  Map<String, dynamic>? _teamDetails;
  List<Map<String, dynamic>> _lastMatches = [];
  List<Map<String, dynamic>> _upcomingMatches = [];
  
  bool _isLoadingDetails = true;
  bool _isLoadingLastMatches = true;
  bool _isLoadingUpcomingMatches = true;
  bool _isFavorite = false;
  bool _isDbActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamData();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      final isFav = await _dbService.isTeamFavorite(widget.teamId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _loadTeamData() async {
    _fetchDetails();
    _fetchLastMatches();
    _fetchUpcomingMatches();
  }

  Future<void> _fetchDetails() async {
    try {
      final details = await _apiService.fetchTeamDetails(widget.teamId);
      if (mounted) {
        setState(() {
          _teamDetails = details;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print('Error fetching team details: $e');
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _fetchLastMatches() async {
    try {
      final matches = await _apiService.fetchTeamFixtures(
        teamId: widget.teamId,
        upcoming: false,
        limit: 15,
      );
      if (mounted) {
        setState(() {
          _lastMatches = matches;
          _isLoadingLastMatches = false;
        });
      }
    } catch (e) {
      print('Error fetching team last fixtures: $e');
      if (mounted) {
        setState(() {
          _isLoadingLastMatches = false;
        });
      }
    }
  }

  Future<void> _fetchUpcomingMatches() async {
    try {
      final matches = await _apiService.fetchTeamFixtures(
        teamId: widget.teamId,
        upcoming: true,
        limit: 15,
      );
      if (mounted) {
        setState(() {
          _upcomingMatches = matches;
          _isLoadingUpcomingMatches = false;
        });
      }
    } catch (e) {
      print('Error fetching team upcoming fixtures: $e');
      if (mounted) {
        setState(() {
          _isLoadingUpcomingMatches = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zaloguj się, aby dodawać drużyny do ulubionych.'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_isDbActionInProgress) return;

    setState(() {
      _isDbActionInProgress = true;
    });

    try {
      final payload = {
        'id': widget.teamId,
        'name': widget.teamName,
        'logo': widget.teamLogo,
      };
      await _dbService.toggleFavoriteTeam(payload);
      final isFav = await _dbService.isTeamFavorite(widget.teamId);
      
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _isDbActionInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFav ? 'Dodano drużynę do ulubionych!' : 'Usunięto drużynę z ulubionych'),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDbActionInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd bazy danych: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatTime(String utcDate) {
    if (utcDate.isEmpty) return '';
    try {
      final date = DateTime.parse(utcDate).toLocal();
      final hours = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      return '$hours:$minutes';
    } catch (e) {
      return '';
    }
  }

  String _formatDate(String utcDate) {
    if (utcDate.isEmpty) return '';
    try {
      final date = DateTime.parse(utcDate).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day.$month.$year';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeAccentColor = Colors.blueAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E10),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.teamName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.redAccent : Colors.white70,
              size: 22,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Header
          _buildTeamHeader(),
          
          // Tab bar
          Container(
            color: const Color(0xFF0E0E10),
            child: TabBar(
              controller: _tabController,
              indicatorColor: themeAccentColor,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'OSTATNIE MECZE'),
                Tab(text: 'TERMINARZ'),
              ],
            ),
          ),
          
          // Tab view body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLastMatchesTab(),
                _buildUpcomingMatchesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader() {
    final name = _teamDetails?['teamName'] ?? widget.teamName;
    final country = _teamDetails?['country'] ?? '';
    final founded = _teamDetails?['founded'] ?? '';
    final venueName = _teamDetails?['venueName'] ?? '';
    final venueCity = _teamDetails?['venueCity'] ?? '';
    final venueCapacity = _teamDetails?['venueCapacity'] ?? '';
    final venueImage = _teamDetails?['venueImage'] ?? '';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E24), width: 1),
        ),
      ),
      child: Column(
        children: [
          if (venueImage.isNotEmpty)
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: venueImage,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox(height: 0),
                ),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        const Color(0xFF0E0E10),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.teamLogo,
                    width: 60,
                    height: 60,
                    placeholder: (context, url) => const SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.sports_soccer,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingDetails)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      else ...[
                        Row(
                          children: [
                            if (country.isNotEmpty) ...[
                              Icon(Icons.flag_outlined, size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                country,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ],
                            if (founded.isNotEmpty && founded != 'Brak danych') ...[
                              if (country.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Text('|', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                const SizedBox(width: 12),
                              ],
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                'Założono: $founded',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        if (venueName.isNotEmpty && venueName != 'Brak danych') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.stadium_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$venueName, $venueCity${venueCapacity != 'Brak danych' ? ' (pojemność: $venueCapacity)' : ''}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastMatchesTab() {
    if (_isLoadingLastMatches) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_lastMatches.isEmpty) {
      return _buildEmptyState('Brak niedawnych spotkań.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _lastMatches.length,
      itemBuilder: (context, index) {
        final match = _lastMatches[index];
        return _buildMatchItem(match);
      },
    );
  }

  Widget _buildUpcomingMatchesTab() {
    if (_isLoadingUpcomingMatches) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_upcomingMatches.isEmpty) {
      return _buildEmptyState('Brak zaplanowanych spotkań.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _upcomingMatches.length,
      itemBuilder: (context, index) {
        final match = _upcomingMatches[index];
        return _buildMatchItem(match);
      },
    );
  }

  Widget _buildMatchItem(Map<String, dynamic> match) {
    final homeTeam = match['homeTeam'] as String;
    final homeCrest = match['homeTeamCrest'] as String;
    final awayTeam = match['awayTeam'] as String;
    final awayCrest = match['awayTeamCrest'] as String;
    final scoreHome = match['scoreHome'];
    final scoreAway = match['scoreAway'];
    final status = match['status'] as String;
    final dateStr = _formatDate(match['utcDate']);
    final timeStr = _formatTime(match['utcDate']);
    final league = match['league'] as String;

    final isHomeThisTeam = match['homeTeamId']?.toString() == widget.teamId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1),
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
                  builder: (context) => MatchDetailScreen(match: match),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          league.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$dateStr o $timeStr',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Home Team
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                homeTeam,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: isHomeThisTeam ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CachedNetworkImage(
                              imageUrl: homeCrest,
                              width: 22,
                              height: 22,
                              errorWidget: (context, url, error) => const Icon(Icons.sports_soccer, size: 22, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      
                      // Score/Time middle box
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: status == 'FINISHED'
                            ? Text(
                                '$scoreHome : $scoreAway',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status == 'IN_PLAY' ? 'LIVE' : timeStr,
                                  style: TextStyle(
                                    color: status == 'IN_PLAY' ? Colors.redAccent : Colors.blueAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      
                      // Away Team
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: awayCrest,
                              width: 22,
                              height: 22,
                              errorWidget: (context, url, error) => const Icon(Icons.sports_soccer, size: 22, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                awayTeam,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: !isHomeThisTeam ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 40, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
