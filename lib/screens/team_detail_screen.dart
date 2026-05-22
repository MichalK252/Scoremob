import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/football_api.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'match_detail_screen.dart';
import 'player_detail_screen.dart';
import 'leagues_list_screen.dart';

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
  List<Map<String, dynamic>> _standings = [];
  String? _standingsLeagueName;
  List<Map<String, dynamic>> _squad = [];

  bool _isLoadingDetails = true;
  bool _isLoadingLastMatches = true;
  bool _isLoadingUpcomingMatches = true;
  bool _isLoadingStandings = true;
  bool _isLoadingSquad = true;
  bool _isFavorite = false;
  bool _isDbActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    _fetchStandings();
    _fetchSquad();
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
        teamName: widget.teamName,
      );
      if (mounted) {
        setState(() {
          _lastMatches = matches.reversed.toList();
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
        teamName: widget.teamName,
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

  Future<void> _fetchStandings() async {

    for (int i = 0; i < 20; i++) {
      if (!_isLoadingLastMatches && !_isLoadingUpcomingMatches) break;
      await Future.delayed(const Duration(milliseconds: 300));
    }

    String? leagueName;
    final allMatches = [..._lastMatches, ..._upcomingMatches];
    for (final m in allMatches) {
      final league = m['league'] as String? ?? '';
      if (league.isNotEmpty && league != 'Nieznana liga') {
        leagueName = league;
        break;
      }
    }

    if (leagueName == null || leagueName.isEmpty) {
      if (mounted) setState(() => _isLoadingStandings = false);
      return;
    }

    final leagues = LeaguesListScreen.leagues;
    Map<String, dynamic>? matchedLeague;
    final lowerName = leagueName.toLowerCase();
    for (final l in leagues) {
      final ln = (l['name'] as String).toLowerCase();
      if (ln == lowerName || lowerName.contains(ln) || ln.contains(lowerName)) {
        matchedLeague = l;
        break;
      }
    }

    if (matchedLeague == null) {
      if (mounted) setState(() => _isLoadingStandings = false);
      return;
    }

    try {
      final standings = await _apiService.fetchStandings(
        leagueId: matchedLeague['id'] as String,
        leagueCode: matchedLeague['code'] as String,
      );
      if (mounted) {
        setState(() {
          _standings = standings;
          _standingsLeagueName = matchedLeague!['name'] as String;
          _isLoadingStandings = false;
        });
      }
    } catch (e) {
      print('Error fetching standings for team: $e');
      if (mounted) setState(() => _isLoadingStandings = false);
    }
  }

  Future<void> _fetchSquad() async {
    try {
      final squad = await _apiService.fetchTeamSquad(widget.teamId);
      if (mounted) {
        setState(() {
          _squad = squad;
          _isLoadingSquad = false;
        });
      }
    } catch (e) {
      print('Error fetching team squad: $e');
      if (mounted) {
        setState(() {
          _isLoadingSquad = false;
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.headerBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.teamName,
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.redAccent : context.textSecondary,
              size: 22,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [

          _buildTeamHeader(),

          Container(
            color: context.headerBg,
            child: TabBar(
              controller: _tabController,
              indicatorColor: themeAccentColor,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: context.textColor,
              unselectedLabelColor: context.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'OSTATNIE'),
                Tab(text: 'TERMINARZ'),
                Tab(text: 'TABELA'),
                Tab(text: 'SKŁAD'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLastMatchesTab(),
                _buildUpcomingMatchesTab(),
                _buildStandingsTab(),
                _buildSquadTab(),
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
      decoration: BoxDecoration(
        color: context.headerBg,
        border: Border(
          bottom: BorderSide(color: context.border, width: 1),
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
                        context.headerBg,
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
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border, width: 1),
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
                    errorWidget: (context, url, error) => Icon(
                      Icons.sports_soccer,
                      size: 60,
                      color: context.textSecondary,
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
                        style: TextStyle(
                          color: context.textColor,
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
                              Icon(Icons.flag_outlined, size: 13, color: context.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                country,
                                style: TextStyle(color: context.textSecondary, fontSize: 12),
                              ),
                            ],
                            if (founded.isNotEmpty && founded != 'Brak danych') ...[
                              if (country.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Text('|', style: TextStyle(color: context.border, fontSize: 12)),
                                const SizedBox(width: 12),
                              ],
                              Icon(Icons.calendar_today_outlined, size: 12, color: context.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Założono: $founded',
                                style: TextStyle(color: context.textSecondary, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        if (venueName.isNotEmpty && venueName != 'Brak danych') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.stadium_outlined, size: 13, color: context.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$venueName, $venueCity${venueCapacity != 'Brak danych' ? ' (pojemność: $venueCapacity)' : ''}',
                                  style: TextStyle(color: context.textSecondary, fontSize: 11),
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 1),
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
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                homeTeam,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: context.textColor,
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
                              errorWidget: (context, url, error) => Icon(Icons.sports_soccer, size: 22, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: status == 'FINISHED'
                            ? Text(
                                '$scoreHome : $scoreAway',
                                style: TextStyle(
                                  color: context.textColor,
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

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: awayCrest,
                              width: 22,
                              height: 22,
                              errorWidget: (context, url, error) => Icon(Icons.sports_soccer, size: 22, color: context.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                awayTeam,
                                style: TextStyle(
                                  color: context.textColor,
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

  Widget _buildStandingsTab() {
    if (_isLoadingStandings) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_standings.isEmpty) {
      return _buildEmptyState('Brak danych o tabeli ligowej.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (_standingsLeagueName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _standingsLeagueName!,
              style: TextStyle(
                color: Colors.blueAccent.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.border, width: 1)),
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text('#', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              Expanded(child: Text('Drużyna', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
              _headerCell('M'),
              _headerCell('W'),
              _headerCell('R'),
              _headerCell('P'),
              _headerCell('Br'),
              _headerCell('Pkt'),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _standings.length,
            itemBuilder: (context, index) {
              final row = _standings[index];
              final teamName = row['teamName'] as String;
              final teamLogo = row['teamLogo'] as String;
              final isCurrentTeam = teamName.toLowerCase().contains(widget.teamName.toLowerCase()) ||
                  widget.teamName.toLowerCase().contains(teamName.toLowerCase());

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentTeam ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border(
                    left: isCurrentTeam
                        ? const BorderSide(color: Colors.blueAccent, width: 3)
                        : BorderSide.none,
                    bottom: BorderSide(color: context.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${row['rank']}',
                        style: TextStyle(
                          color: isCurrentTeam ? Colors.blueAccent : context.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CachedNetworkImage(
                      imageUrl: teamLogo,
                      width: 18,
                      height: 18,
                      errorWidget: (context, url, error) => Icon(Icons.sports_soccer, size: 18, color: context.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        teamName,
                        style: TextStyle(
                          color: isCurrentTeam ? context.textColor : context.textSecondary,
                          fontSize: 12,
                          fontWeight: isCurrentTeam ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _dataCell('${row['played']}', isCurrentTeam),
                    _dataCell('${row['won']}', isCurrentTeam),
                    _dataCell('${row['draw']}', isCurrentTeam),
                    _dataCell('${row['lost']}', isCurrentTeam),
                    _dataCell('${row['goalsFor']}:${row['goalsAgainst']}', isCurrentTeam, width: 36),
                    _dataCell('${row['points']}', isCurrentTeam, bold: true, color: isCurrentTeam ? Colors.blueAccent : context.textColor),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dataCell(String value, bool highlight, {bool bold = false, Color? color, double width = 28}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: TextStyle(
          color: color ?? (highlight ? context.textColor : context.textSecondary),
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 40, color: context.textSecondary),
          const SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadTab() {
    if (_isLoadingSquad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_squad.isEmpty) {
      return _buildEmptyState('Brak danych o składzie.');
    }

    final positionOrder = ['Goalkeeper', 'Defender', 'Midfielder', 'Attacker'];
    final positionLabels = {
      'Goalkeeper': 'Bramkarze',
      'Defender': 'Obrońcy',
      'Midfielder': 'Pomocnicy',
      'Attacker': 'Napastnicy',
    };
    final positionColors = {
      'Goalkeeper': Colors.amber,
      'Defender': Colors.blueAccent,
      'Midfielder': Colors.greenAccent,
      'Attacker': Colors.redAccent,
    };

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final pos in positionOrder) {
      grouped[pos] = [];
    }
    for (final player in _squad) {
      final pos = player['position'] as String? ?? '';
      if (grouped.containsKey(pos)) {
        grouped[pos]!.add(player);
      } else {
        grouped.putIfAbsent('Attacker', () => []).add(player);
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      physics: const BouncingScrollPhysics(),
      children: [
        for (final pos in positionOrder)
          if (grouped[pos] != null && grouped[pos]!.isNotEmpty) ...[

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: positionColors[pos] ?? Colors.blueAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    positionLabels[pos] ?? pos,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${grouped[pos]!.length}',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ...grouped[pos]!.map((player) => _buildPlayerRow(player, positionColors[pos] ?? Colors.blueAccent)),
          ],
      ],
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player, Color posColor) {
    final name = player['playerName'] as String? ?? '';
    final photo = player['photo'] as String? ?? '';
    final age = player['age'];
    final number = player['number'] as int?;
    final position = player['position'] as String? ?? '';
    final playerId = player['playerId'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailScreen(
                    playerId: playerId,
                    playerName: name,
                    playerPhoto: photo,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [

                  CircleAvatar(
                    radius: 18,
                    backgroundColor: context.scaffoldBg,
                    child: ClipOval(
                      child: photo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photo,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
                                  ),
                                ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 20,
                                color: context.textSecondary,
                              ),
                            )
                          : Icon(Icons.person, size: 20, color: context.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (age != null && age != 0) ...[
                              Text(
                                '$age lat',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: posColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _translatePositionShort(position),
                      style: TextStyle(
                        color: posColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  if (number != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.border,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _translatePositionShort(String position) {
    switch (position) {
      case 'Goalkeeper':
        return 'BR';
      case 'Defender':
        return 'OBR';
      case 'Midfielder':
        return 'POM';
      case 'Attacker':
        return 'NAP';
      default:
        return position.length > 3 ? position.substring(0, 3).toUpperCase() : position.toUpperCase();
    }
  }
}
