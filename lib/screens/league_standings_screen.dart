import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/football_api.dart';

class LeagueStandingsScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueStandingsScreen({super.key, required this.league});

  @override
  State<LeagueStandingsScreen> createState() => _LeagueStandingsScreenState();
}

class _LeagueStandingsScreenState extends State<LeagueStandingsScreen> {
  final FootballApiService _apiService = FootballApiService();
  late Future<List<Map<String, dynamic>>> _standingsFuture;
  late int _selectedSeason;
  late List<int> _seasonsList;

  @override
  void initState() {
    super.initState();
    _selectedSeason = _getCurrentSeason();
    // Generuje 6 ostatnich sezonów (np. 2025, 2024, 2023, 2022, 2021, 2020)
    _seasonsList = List.generate(6, (index) => _selectedSeason - index);
    _loadStandings();
  }

  int _getCurrentSeason() {
    final now = DateTime.now();
    return now.month < 7 ? now.year - 1 : now.year;
  }

  void _loadStandings() {
    setState(() {
      _standingsFuture = _apiService.fetchStandings(
        leagueId: widget.league['id'] as String,
        leagueCode: widget.league['code'] as String,
        season: _selectedSeason,
      );
    });
  }

  // Parse recent form character into badge widget
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
                  _loadStandings();
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? accentColor : const Color(0xFF16161A),
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFF24242A),
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
                    color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
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

  // Show detailed bottom sheet for team details
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

    // Determine zone description
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

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: const Color(0xFF24242A), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
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
                // Team Header
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Miejsce w tabeli (Sezon $_selectedSeason/${(_selectedSeason + 1).toString().substring(2)}): #$rank',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
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
                const Divider(height: 32, thickness: 1, color: Color(0xFF24242A)),
                // Stats Grid
                const Text(
                  'Statystyki sezonu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
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
                        color: goalsDiff > 0 ? Colors.green.shade400 : (goalsDiff < 0 ? Colors.red.shade400 : Colors.white)),
                  ],
                ),
                const Divider(height: 32, thickness: 1, color: Color(0xFF24242A)),
                // Form History
                if (formString.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        'Ostatnia forma: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...formString.split('').map((char) => _buildFormBadge(char)),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
          color: const Color(0xFF0E0E10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF24242A), width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _standingsFuture,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              // Beautiful Gradient App Bar
              SliverAppBar(
                expandedHeight: 140.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0E0E10),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
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
                        errorWidget: (context, url, error) => const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.league['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
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
                          const Color(0xFF0C0C0E),
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
                            color: Colors.white.withOpacity(0.4),
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

              // Season Selector (always visible)
              SliverToBoxAdapter(
                child: _buildSeasonSelector(accentColor),
              ),

              // Status Views
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Błąd pobierania tabeli:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadStandings,
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
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Tabela ligowa jest obecnie niedostępna',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                // Standing Table Header Row
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0E0E10),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 32, child: Text('#', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                        const Expanded(child: Text('Drużyna', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 32, child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 44, child: Text('Bilans', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                        SizedBox(width: 36, child: Text('Pkt', textAlign: TextAlign.right, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),

                // Table Items List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final team = snapshot.data![index];
                        final rank = team['rank'] as int;
                        final goalsDiff = team['goalsDiff'] as int;
                        final totalTeams = snapshot.data!.length;
                        final isLastRow = index == totalTeams - 1;

                        // Visual indicator color depending on qualifications
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
                            color: const Color(0xFF16161A),
                            border: Border(
                              bottom: BorderSide(
                                color: isLastRow ? Colors.transparent : const Color(0xFF24242A),
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
                                  // Position indicator and number
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
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Team Logo and Name
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
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Matches played
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${team['played']}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),

                                  // Goal difference
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      goalsDiff > 0 ? '+$goalsDiff' : '$goalsDiff',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: goalsDiff > 0
                                            ? Colors.green.shade400
                                            : (goalsDiff < 0 ? Colors.red.shade400 : Colors.white38),
                                      ),
                                    ),
                                  ),

                                  // Points
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      '${team['points']}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                ),

                // Table Legend helper note at bottom
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(width: 6),
                            Text(
                              'Stuknij w dowolną drużynę, aby zobaczyć szczegóły i formę.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Legend colors
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
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 104),
                ),
              ],
            ],
          );
        },
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
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
