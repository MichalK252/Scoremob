import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/football_api.dart';
import '../services/supabase_service.dart';
import 'team_detail_screen.dart';
import 'player_detail_screen.dart';
import '../theme/app_theme.dart';

class LeagueStandingsScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueStandingsScreen({super.key, required this.league});

  @override
  State<LeagueStandingsScreen> createState() => _LeagueStandingsScreenState();
}

class _LeagueStandingsScreenState extends State<LeagueStandingsScreen> {
  final FootballApiService _apiService = FootballApiService();
  final SupabaseService _dbService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _standingsFuture;
  late Future<List<Map<String, dynamic>>> _topScorersFuture;
  late Future<List<Map<String, dynamic>>> _topAssistsFuture;
  late int _selectedSeason;
  late List<int> _seasonsList;
  bool _isLeagueFav = false;
  int _statsToggleIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedSeason = _getCurrentSeason();

    _seasonsList = List.generate(6, (index) => _selectedSeason - index);
    _loadData();
    _checkLeagueFavoriteStatus();
  }

  void _checkLeagueFavoriteStatus() async {
    final isFav = await _dbService.isLeagueFavorite(widget.league['id'].toString());
    if (mounted) {
      setState(() {
        _isLeagueFav = isFav;
      });
    }
  }

  void _toggleLeagueFavorite() async {
    try {
      await _dbService.toggleFavoriteLeague(widget.league);
      _checkLeagueFavoriteStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!_isLeagueFav ? 'Dodano ligę do ulubionych!' : 'Usunięto ligę z ulubionych'),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  int _getCurrentSeason() {
    final now = DateTime.now();
    return now.month < 7 ? now.year - 1 : now.year;
  }

  void _loadData() {
    setState(() {
      final leagueId = widget.league['id'].toString();
      final leagueCode = widget.league['code'] as String;
      _standingsFuture = _apiService.fetchStandings(
        leagueId: leagueId,
        leagueCode: leagueCode,
        season: _selectedSeason,
      );
      _topScorersFuture = _apiService.fetchTopScorers(leagueId, _selectedSeason);
      _topAssistsFuture = _apiService.fetchTopAssists(leagueId, _selectedSeason);
    });
  }

  Widget _buildFormBadge(String result) {
    Color color;
    String letter;
    switch (result.toUpperCase()) {
      case 'W':
        color = Colors.green.shade600;
        letter = 'Z';
        break;
      case 'D':
        color = Colors.grey.shade600;
        letter = 'R';
        break;
      case 'L':
        color = Colors.red.shade600;
        letter = 'P';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonSelector(Color accentColor) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _seasonsList.length,
        itemBuilder: (context, index) {
          final season = _seasonsList[index];
          final isSelected = _selectedSeason == season;
          final label = '$season/${(season + 1).toString().substring(2)}';

          return GestureDetector(
            onTap: () {
              if (_selectedSeason != season) {
                setState(() {
                  _selectedSeason = season;
                  _loadData();
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? accentColor : context.cardBg,
                border: Border.all(
                  color: isSelected ? accentColor : context.border,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTeamDetails(Map<String, dynamic> teamData, int totalTeams) {
    final rank = teamData['rank'] as int;
    final name = teamData['teamName'] as String;
    final logo = teamData['teamLogo'] as String;
    final points = teamData['points'] as int;
    final played = teamData['played'] as int;
    final won = teamData['won'] as int;
    final draw = teamData['draw'] as int;
    final lost = teamData['lost'] as int;
    final goalsFor = teamData['goalsFor'] as int;
    final goalsAgainst = teamData['goalsAgainst'] as int;
    final goalsDiff = teamData['goalsDiff'] as int;
    final formString = teamData['form'] as String? ?? '';

    String zoneText = '';
    Color zoneColor = Colors.transparent;
    if (widget.league['code'] == 'CL') {
      if (rank <= 8) {
        zoneText = 'Awans bezpośredni do 1/8 finału';
        zoneColor = Colors.blue.shade400;
      } else if (rank <= 24) {
        zoneText = 'Play-offs (1/16 finału)';
        zoneColor = Colors.orange.shade400;
      }
    } else {
      if (rank <= 4) {
        zoneText = 'UEFA Champions League';
        zoneColor = Colors.blue.shade400;
      } else if (rank <= 6) {
        zoneText = 'UEFA Europa League / Conference League';
        zoneColor = Colors.orange.shade400;
      } else if (rank > totalTeams - 3) {
        zoneText = 'Spadek z ligi';
        zoneColor = Colors.red.shade400;
      }
    }

    final teamId = teamData['teamId']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool? isFav;
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isFav == null) {
              isFav = false;
              if (teamId.isNotEmpty) {
                _dbService.isTeamFavorite(teamId).then((val) {
                  setModalState(() {
                    isFav = val;
                  });
                });
              }
            }

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: context.border, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: logo,
                      width: 54,
                      height: 54,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.sports_soccer,
                        size: 54,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Miejsce w tabeli (Sezon $_selectedSeason/${(_selectedSeason + 1).toString().substring(2)}): #$rank',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (widget.league['accent'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (widget.league['accent'] as Color).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$points PKT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: widget.league['accent'] as Color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isFav == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav == true ? Colors.redAccent : Colors.grey,
                        size: 24,
                      ),
                      onPressed: () async {
                        if (teamId.isEmpty) return;
                        try {
                          final teamPayload = {
                            'id': teamId,
                            'name': name,
                            'logo': logo,
                          };
                          await _dbService.toggleFavoriteTeam(teamPayload);
                          final newVal = await _dbService.isTeamFavorite(teamId);
                          setModalState(() {
                            isFav = newVal;
                          });
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(newVal ? 'Dodano drużynę do ulubionych!' : 'Usunięto drużynę z ulubionych'),
                              backgroundColor: Colors.blueAccent,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                if (zoneText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: zoneColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        zoneText,
                        style: TextStyle(
                          fontSize: 12,
                          color: zoneColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                Divider(height: 32, thickness: 1, color: context.border),

                Text(
                  'Statystyki sezonu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox('Mecze', '$played'),
                    _buildStatBox('Wygrane', '$won', color: Colors.green.shade400),
                    _buildStatBox('Remisy', '$draw', color: Colors.grey.shade400),
                    _buildStatBox('Przegrane', '$lost', color: Colors.red.shade400),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox('Gole strzelone', '$goalsFor'),
                    _buildStatBox('Gole stracone', '$goalsAgainst'),
                    _buildStatBox('Bilans bramkowy', goalsDiff > 0 ? '+$goalsDiff' : '$goalsDiff',
                        color: goalsDiff > 0 ? Colors.green.shade400 : (goalsDiff < 0 ? Colors.red.shade400 : context.textColor)),
                  ],
                ),
                Divider(height: 32, thickness: 1, color: context.border),

                if (formString.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Ostatnia forma: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...formString.split('').map((char) => _buildFormBadge(char)),
                    ],
                  ),
                ],
                Divider(height: 32, thickness: 1, color: context.border),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamDetailScreen(
                            teamId: teamId,
                            teamName: name,
                            teamLogo: logo,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Szczegóły Drużyny',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
);
  }

  Widget _buildStatBox(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.headerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border, width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: context.textTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color ?? context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leagueColor1 = widget.league['color1'] as Color;
    final leagueColor2 = widget.league['color2'] as Color;
    final accentColor = widget.league['accent'] as Color;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[

              SliverAppBar(
                expandedHeight: 140.0,
                floating: false,
                pinned: true,
                backgroundColor: context.scaffoldBg,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, size: 18, color: context.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isLeagueFav ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _isLeagueFav ? Colors.amber : context.textColor,
                      size: 22,
                    ),
                    onPressed: _toggleLeagueFavorite,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.league['logo'] as String,
                        width: 22,
                        height: 22,
                        errorWidget: (context, url, error) => Icon(
                          Icons.emoji_events,
                          color: context.textColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.league['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: context.textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          leagueColor1,
                          leagueColor2.withOpacity(0.8),
                          context.scaffoldBg,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 36.0),
                        child: Text(
                          widget.league['country'] as String,
                          style: TextStyle(
                            color: context.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _buildSeasonSelector(accentColor),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: accentColor,
                    labelColor: accentColor,
                    unselectedLabelColor: context.textSecondary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'TABELA'),
                      Tab(text: 'STATYSTYKI'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildStandingsTab(accentColor),
              _buildTopStatsTab(accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsTab(Color accentColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _standingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Błąd pobierania tabeli:\n${snapshot.error}',
            accentColor,
            _loadData,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Tabela ligowa jest obecnie niedostępna',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final standings = snapshot.data!;
        final totalTeams = standings.length;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: context.headerBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 32, child: Text('#', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Drużyna', style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 32, child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 44, child: Text('Bilans', textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 36, child: Text('Pkt', textAlign: TextAlign.right, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            ...List.generate(totalTeams, (index) {
              final team = standings[index];
              final rank = team['rank'] as int;
              final goalsDiff = team['goalsDiff'] as int;
              final isLastRow = index == totalTeams - 1;

              Color qualifierColor = Colors.transparent;
              if (widget.league['code'] == 'CL') {
                if (rank <= 8) {
                  qualifierColor = Colors.blue.shade500;
                } else if (rank <= 24) {
                  qualifierColor = Colors.orange.shade500;
                }
              } else {
                if (rank <= 4) {
                  qualifierColor = Colors.blue.shade500;
                } else if (rank <= 6) {
                  qualifierColor = Colors.orange.shade500;
                } else if (rank > totalTeams - 3) {
                  qualifierColor = Colors.red.shade500;
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  border: Border(
                    bottom: BorderSide(
                      color: isLastRow ? Colors.transparent : context.border,
                      width: 0.5,
                    ),
                  ),
                  borderRadius: isLastRow
                      ? const BorderRadius.vertical(bottom: Radius.circular(12))
                      : BorderRadius.zero,
                ),
                child: InkWell(
                  onTap: () => _showTeamDetails(team, totalTeams),
                  borderRadius: isLastRow
                      ? const BorderRadius.vertical(bottom: Radius.circular(12))
                      : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Row(
                      children: [

                        SizedBox(
                          width: 32,
                          child: Row(
                            children: [
                              if (qualifierColor != Colors.transparent) ...[
                                Container(
                                  width: 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: qualifierColor,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ] else ...[
                                const SizedBox(width: 7),
                              ],
                              Text(
                                '$rank',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Row(
                            children: [
                              CachedNetworkImage(
                                imageUrl: team['teamLogo'] as String,
                                width: 20,
                                height: 20,
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.sports_soccer,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  team['teamName'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          width: 32,
                          child: Text(
                            '${team['played']}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 44,
                          child: Text(
                            goalsDiff > 0 ? '+$goalsDiff' : '$goalsDiff',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: goalsDiff > 0
                                  ? Colors.green.shade400
                                  : (goalsDiff < 0 ? Colors.red.shade400 : context.textTertiary),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 36,
                          child: Text(
                            '${team['points']}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 12, color: context.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'Stuknij w dowolną drużynę, aby zobaczyć szczegóły i formę.',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildLegendItem(Colors.blue.shade500, widget.league['code'] == 'CL' ? '1-8 finału' : 'Liga Mistrzów'),
                      _buildLegendItem(Colors.orange.shade500, widget.league['code'] == 'CL' ? 'Play-offs' : 'Liga Europy / Konferencji'),
                      if (widget.league['code'] != 'CL')
                        _buildLegendItem(Colors.red.shade500, 'Spadek'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 104),
          ],
        );
      },
    );
  }

  Widget _buildTopStatsTab(Color accentColor) {
    final targetFuture = _statsToggleIndex == 0 ? _topScorersFuture : _topAssistsFuture;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: targetFuture,
      builder: (context, snapshot) {
        return Column(
          children: [
            _buildToggleSelector(accentColor),
            Expanded(
              child: _buildStatsListContent(snapshot, accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleSelector(Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_statsToggleIndex != 0) {
                  setState(() {
                    _statsToggleIndex = 0;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _statsToggleIndex == 0 ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Strzelcy',
                    style: TextStyle(
                      color: _statsToggleIndex == 0 ? Colors.black : context.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_statsToggleIndex != 1) {
                  setState(() {
                    _statsToggleIndex = 1;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _statsToggleIndex == 1 ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Asystenci',
                    style: TextStyle(
                      color: _statsToggleIndex == 1 ? Colors.black : context.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsListContent(AsyncSnapshot<List<Map<String, dynamic>>> snapshot, Color accentColor) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final errorStr = snapshot.error.toString();
      if (errorStr.contains('Free plans do not have access to this season') || errorStr.contains('plan')) {
        return _buildPlanLimitState(accentColor);
      }
      return _buildErrorState(
        _statsToggleIndex == 0 ? 'Błąd pobierania strzelców:\n${snapshot.error}' : 'Błąd pobierania asystentów:\n${snapshot.error}',
        accentColor,
        _loadData,
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Text(
          _statsToggleIndex == 0 ? 'Brak danych o strzelcach' : 'Brak danych o asystentach',
          style: TextStyle(color: context.textTertiary),
        ),
      );
    }

    final dataList = snapshot.data!;

    int? returnedSeason;
    if (dataList.isNotEmpty) {
      final item = dataList.first;
      final statsList = item['statistics'] as List? ?? [];
      final stats = statsList.isNotEmpty ? statsList.first : {};
      final league = stats['league'] ?? {};
      returnedSeason = league['season'] as int?;
    }

    final showFallbackBanner = returnedSeason != null && returnedSeason != _selectedSeason;

    final contentList = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 104),
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        final item = dataList[index];
        final player = item['player'] ?? {};
        final playerId = (player['id'] ?? '').toString();
        final playerName = player['name'] ?? '';
        final playerPhoto = player['photo'] ?? '';

        final statsList = item['statistics'] as List? ?? [];
        final stats = statsList.isNotEmpty ? statsList.first : {};
        final team = stats['team'] ?? {};
        final teamName = team['name'] ?? '';
        final teamLogo = team['logo'] ?? '';

        final games = stats['games'] ?? {};
        final appearances = games['appearences'] ?? 0;
        final ratingString = games['rating'] as String? ?? '0.0';
        final double rating = double.tryParse(ratingString) ?? 0.0;

        final goals = stats['goals'] ?? {};
        final goalsCount = goals['total'] ?? 0;
        final assistsCount = goals['assists'] ?? 0;

        final int statValue = _statsToggleIndex == 0 ? goalsCount : assistsCount;
        final String statLabel = _statsToggleIndex == 0 ? _getGoalsLabel(statValue) : _getAssistsLabel(statValue);

        return _buildPlayerRow(
          rank: index + 1,
          playerId: playerId,
          playerName: playerName,
          playerPhoto: playerPhoto,
          teamName: teamName,
          teamLogo: teamLogo,
          statValue: statValue,
          statLabel: statLabel,
          appearances: appearances,
          rating: rating,
          accentColor: accentColor,
        );
      },
    );

    if (showFallbackBanner) {
      return Column(
        children: [
          _buildFallbackBanner(returnedSeason!, accentColor),
          Expanded(child: contentList),
        ],
      );
    }

    return contentList;
  }

  Widget _buildPlayerRow({
    required int rank,
    required String playerId,
    required String playerName,
    required String playerPhoto,
    required String teamName,
    required String teamLogo,
    required int statValue,
    required String statLabel,
    required int appearances,
    required double rating,
    required Color accentColor,
  }) {
    Color rankColor = context.textSecondary;
    if (rank == 1) rankColor = Colors.amber;
    else if (rank == 2) rankColor = Colors.grey.shade400;
    else if (rank == 3) rankColor = Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.8),
      ),
      child: InkWell(
        onTap: () {
          if (playerId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerDetailScreen(
                  playerId: playerId,
                  playerName: playerName,
                  playerPhoto: playerPhoto,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [

              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rank <= 3 ? rankColor.withOpacity(0.5) : context.border,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: playerPhoto,
                    placeholder: (context, url) => Container(
                      color: context.headerBg,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: context.headerBg,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (teamLogo.isNotEmpty) ...[
                          CachedNetworkImage(
                            imageUrl: teamLogo,
                            width: 14,
                            height: 14,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.sports_soccer,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            teamName,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (rating > 0.0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '$appearances m.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    '$statValue $statLabel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, Color accentColor, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Spróbuj ponownie', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlanLimitState(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_outlined, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              Text(
                'Ograniczenie darmowego planu API',
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Darmowa wersja API nie obsługuje statystyk zawodników (strzelców/asystentów) dla wybranego sezonu.\n\nWybierz sezon 2024/25 lub wcześniejszy, aby zobaczyć statystyki.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_seasonsList.contains(2024)) {
                    setState(() {
                      _selectedSeason = 2024;
                      _loadData();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Przełącz na sezon 2024/25',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(int returnedSeason, Color accentColor) {
    final selectedSeasonLabel = '$_selectedSeason/${(_selectedSeason + 1).toString().substring(2)}';
    final returnedSeasonLabel = '$returnedSeason/${(returnedSeason + 1).toString().substring(2)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Plan darmowy API nie obsługuje statystyk dla sezonu $selectedSeasonLabel. Wyświetlamy dane z sezonu $returnedSeasonLabel.',
              style: TextStyle(
                color: context.textColor,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalsLabel(int count) {
    if (count == 1) return 'gol';
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'gole';
    }
    return 'goli';
  }

  String _getAssistsLabel(int count) {
    if (count == 1) return 'asysta';
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'asysty';
    }
    return 'asyst';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.scaffoldBg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
