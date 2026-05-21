import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/football_api.dart';
import '../theme/app_theme.dart';

class MatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> match;

  const MatchDetailScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  final FootballApiService _apiService = FootballApiService();
  late Future<List<dynamic>> _matchDataFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final matchId = widget.match['id'];
    final source = widget.match['source'] ?? 'api-football';
    if (matchId != null) {
      _matchDataFuture = Future.wait([
        _apiService.fetchFixtureEvents(matchId, source: source),
        _apiService.fetchFixtureLineups(matchId, source: source),
        _apiService.fetchFixtureStatistics(matchId, source: source),
      ]);
    } else {
      _matchDataFuture = Future.value([[], [], []]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCrest(String crestUrl, double size) {
    Widget imageWidget = Icon(Icons.sports_soccer, size: size, color: Colors.grey);

    if (crestUrl.isNotEmpty) {
      if (crestUrl.endsWith('.svg')) {
        imageWidget = SvgPicture.network(
          crestUrl,
          width: size,
          height: size,
          placeholderBuilder: (context) => SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: crestUrl,
          width: size,
          height: size,
          placeholder: (context, url) => SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) =>
              Icon(Icons.sports_soccer, size: size, color: Colors.grey),
        );
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: imageWidget),
    );
  }

  String _formatDateTime(String utcDate) {
    if (utcDate.isEmpty) return '';
    try {
      final date = DateTime.parse(utcDate).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hours = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      return '$day.$month.${date.year} o $hours:$minutes';
    } catch (e) {
      return '';
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'SCHEDULED':
        return 'Zaplanowany';
      case 'TIMED':
        return 'Oczekuje';
      case 'IN_PLAY':
        return 'Trwa';
      case 'PAUSED':
        return 'Przerwa';
      case 'FINISHED':
        return 'Zakończony';
      case 'POSTPONED':
        return 'Przełożony';
      case 'SUSPENDED':
        return 'Zawieszony';
      case 'CANCELED':
        return 'Anulowany';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final status = match['status'] ?? 'SCHEDULED';
    final isLive = status == 'IN_PLAY' || status == 'PAUSED';
    final isFinished = status == 'FINISHED';

    final scoreHome = match['scoreHome'];
    final scoreAway = match['scoreAway'];
    final hasScore = scoreHome != null && scoreAway != null;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.headerBg,
        elevation: 0,
        title: Text(
          match['league'] ?? 'Szczegóły meczu',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _matchDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Błąd pobierania szczegółów:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final data = snapshot.data ?? [[], [], []];
          final events = data[0] as List<dynamic>;
          final lineups = data[1] as List<dynamic>;
          final statistics = data[2] as List<dynamic>;

          return Column(
            children: [
              // 1. Scoreboard (Główna tablica)
              _buildScoreboardHeader(match, isLive, isFinished, scoreHome, scoreAway, hasScore, status),
              
              // 2. Tab Bar
              Container(
                color: context.headerBg,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue.shade500,
                  labelColor: context.textColor,
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'SZCZEGÓŁY'),
                    Tab(text: 'SKŁADY'),
                    Tab(text: 'STATYSTYKI'),
                  ],
                ),
              ),
              
              // 3. Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Szczegóły + Wydarzenia (Timeline)
                    _buildDetailsAndTimelineTab(match, events),
                    
                    // Tab 2: Składy (Lineups)
                    _buildLineupsTab(lineups),
                    
                    // Tab 3: Statystyki (Statistics)
                    _buildStatisticsTab(statistics),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScoreboardHeader(
    Map<String, dynamic> match,
    bool isLive,
    bool isFinished,
    dynamic scoreHome,
    dynamic scoreAway,
    bool hasScore,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      color: context.headerBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gospodarze
          Expanded(
            child: Column(
              children: [
                _buildCrest(match['homeTeamCrest'] ?? '', 56),
                const SizedBox(height: 12),
                Text(
                  match['homeTeam'] ?? 'Gospodarze',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
          // Wynik / Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                if (hasScore) ...[
                  Text(
                    '$scoreHome - $scoreAway',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isLive ? Colors.green.shade400 : context.textColor,
                      letterSpacing: 2,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'vs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: isLive 
                        ? (context.isDarkMode ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50) 
                        : (isFinished 
                            ? (context.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100) 
                            : (context.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isLive 
                          ? (context.isDarkMode ? Colors.green.shade700 : Colors.green.shade300) 
                          : (isFinished 
                              ? (context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300) 
                              : (context.isDarkMode ? Colors.blue.shade700.withOpacity(0.5) : Colors.blue.shade200)),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _translateStatus(status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isLive 
                          ? (context.isDarkMode ? Colors.green.shade300 : Colors.green.shade700) 
                          : (isFinished 
                              ? (context.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600) 
                              : (context.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700)),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Goście
          Expanded(
            child: Column(
              children: [
                _buildCrest(match['awayTeamCrest'] ?? '', 56),
                const SizedBox(height: 12),
                Text(
                  match['awayTeam'] ?? 'Goście',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsAndTimelineTab(Map<String, dynamic> match, List<dynamic> events) {
    final halfTimeHome = match['halfTimeHome'];
    final halfTimeAway = match['halfTimeAway'];
    final hasHalfTime = halfTimeHome != null && halfTimeAway != null;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Podstawowe informacje meczowe
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Column(
            children: [
              _buildInfoRow(context, Icons.calendar_month, 'Czas rozpoczęcia', _formatDateTime(match['utcDate'] ?? '')),
              Divider(height: 24, thickness: 1, color: context.border),
              _buildInfoRow(context, Icons.stadium, 'Stadion / Obiekt', match['venue'] ?? 'Brak danych'),
              Divider(height: 24, thickness: 1, color: context.border),
              _buildInfoRow(context, Icons.person, 'Sędzia główny', match['referee'] ?? 'Brak danych'),
              if (match['round'] != null && match['round'].toString().isNotEmpty) ...[
                Divider(height: 24, thickness: 1, color: context.border),
                _buildInfoRow(context, Icons.emoji_events, 'Runda', match['round'].toString()),
              ],
              if (hasHalfTime) ...[
                Divider(height: 24, thickness: 1, color: context.border),
                _buildInfoRow(context, Icons.timelapse, 'Do przerwy', '$halfTimeHome - $halfTimeAway'),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Zdarzenia (Timeline)
        Text(
          'Przebieg meczu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Center(
              child: Text(
                'Brak zdarzeń dla tego meczu',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border, width: 1),
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: events.length,
              separatorBuilder: (context, index) => Divider(
                height: 16,
                thickness: 0.5,
                color: context.border,
              ),
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventItem(event, match);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade400, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 13, color: context.textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event, Map<String, dynamic> match) {
    final teamId = event['team']?['id'];
    final homeTeamId = match['homeTeamId'];
    final isHomeEvent = teamId == homeTeamId;

    final type = event['type']?.toString().toLowerCase() ?? '';
    final detail = event['detail']?.toString().toLowerCase() ?? '';
    final time = event['time']?['elapsed']?.toString() ?? '';
    final extra = event['time']?['extra'];
    final displayTime = extra != null ? "$time+$extra'" : "$time'";

    final playerName = event['player']?['name'] ?? 'Zawodnik';
    final assistName = event['assist']?['name'];

    Widget iconWidget;
    String eventText = playerName;
    Color iconColor = Colors.white;

    if (type == 'goal') {
      iconWidget = const Icon(Icons.sports_soccer, size: 16, color: Colors.green);
      if (detail.contains('own goal')) {
        eventText += ' (samobój)';
        iconColor = Colors.red;
      } else if (detail.contains('penalty')) {
        eventText += ' (karne)';
      }
      if (assistName != null) {
        eventText += '\nasysta: $assistName';
      }
    } else if (type == 'card') {
      iconColor = detail.contains('red') ? Colors.red : Colors.yellow.shade700;
      iconWidget = Icon(Icons.square, size: 14, color: iconColor);
    } else if (type == 'subst') {
      iconWidget = const Icon(Icons.swap_horiz, size: 16, color: Colors.grey);
      if (assistName != null) {
        eventText = 'Schodzi: $playerName\nWchodzi: $assistName';
      } else {
        eventText = 'Zmiana: $playerName';
      }
    } else {
      iconWidget = const Icon(Icons.info_outline, size: 16, color: Colors.grey);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isHomeEvent ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isHomeEvent) ...[
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                displayTime,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                eventText,
                style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                eventText,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 12),
            iconWidget,
            const SizedBox(width: 8),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                displayTime,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineupsTab(List<dynamic> lineups) {
    final isFallback = widget.match['source'] == 'football-data';
    if (isFallback) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Składy zespołów są niedostępne w planie zapasowym aplikacji (Football-Data.org).',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    if (lineups.isEmpty) {
      return Center(
        child: Text(
          'Składy będą dostępne przed meczem',
          style: TextStyle(color: context.textSecondary),
        ),
      );
    }

    final homeLineup = lineups[0];
    final awayLineup = lineups.length > 1 ? lineups[1] : null;

    final homeXI = homeLineup['startXI'] as List? ?? [];
    final awayXI = awayLineup?['startXI'] as List? ?? [];

    final homeSubs = homeLineup['substitutes'] as List? ?? [];
    final awaySubs = awayLineup?['substitutes'] as List? ?? [];

    final homeCoach = homeLineup['coach']?['name'] ?? 'Brak danych';
    final awayCoach = awayLineup?['coach']?['name'] ?? 'Brak danych';

    final homeFormation = homeLineup['formation'] ?? '';
    final awayFormation = awayLineup?['formation'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Formacje i Trenerzy
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Formacja', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                    const SizedBox(height: 2),
                    Text(homeFormation.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
                    const SizedBox(height: 8),
                    Text('Trener', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                    const SizedBox(height: 2),
                    Text(homeCoach.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textSecondary)),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: context.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Formacja', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                    const SizedBox(height: 2),
                    Text(awayFormation.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
                    const SizedBox(height: 8),
                    Text('Trener', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                    const SizedBox(height: 2),
                    Text(awayCoach.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Nagłówek Składów wyjściowych
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Skład wyjściowy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
              Text('Skład wyjściowy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tabela wyjściowych XI side-by-side
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: homeXI.length > awayXI.length ? homeXI.length : awayXI.length,
            separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, color: context.border),
            itemBuilder: (context, index) {
              final homePlayer = index < homeXI.length ? homeXI[index]['player'] : null;
              final awayPlayer = index < awayXI.length ? awayXI[index]['player'] : null;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Home Player
                    Expanded(
                      child: homePlayer != null
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    homePlayer['number']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade400),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    homePlayer['name'] ?? '',
                                    style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(width: 16),
                    // Away Player
                    Expanded(
                      child: awayPlayer != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    awayPlayer['name'] ?? '',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    awayPlayer['number']?.toString() ?? '',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textSecondary),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Nagłówek Rezerwowych
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rezerwowi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
              Text('Rezerwowi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tabela rezerwowych side-by-side
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: homeSubs.length > awaySubs.length ? homeSubs.length : awaySubs.length,
            separatorBuilder: (context, index) => Divider(height: 1, thickness: 0.5, color: context.border),
            itemBuilder: (context, index) {
              final homePlayer = index < homeSubs.length ? homeSubs[index]['player'] : null;
              final awayPlayer = index < awaySubs.length ? awaySubs[index]['player'] : null;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Home Player
                    Expanded(
                      child: homePlayer != null
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    homePlayer['number']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade400),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    homePlayer['name'] ?? '',
                                    style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w400),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(width: 16),
                    // Away Player
                    Expanded(
                      child: awayPlayer != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    awayPlayer['name'] ?? '',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w400),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    awayPlayer['number']?.toString() ?? '',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textTertiary),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(List<dynamic> statistics) {
    final isFallback = widget.match['source'] == 'football-data';
    if (isFallback) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Statystyki meczowe są niedostępne w planie zapasowym aplikacji (Football-Data.org).',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    if (statistics.isEmpty) {
      return Center(
        child: Text(
          'Statystyki będą dostępne w trakcie meczu',
          style: TextStyle(color: context.textSecondary),
        ),
      );
    }

    final homeStatsList = statistics[0]['statistics'] as List? ?? [];
    final awayStatsList = statistics.length > 1 ? statistics[1]['statistics'] as List? ?? [] : [];

    // Helper do wyciągania statystyk
    Map<String, dynamic>? getStat(String type) {
      final homeItem = homeStatsList.firstWhere((s) => s['type'] == type, orElse: () => null);
      final awayItem = awayStatsList.firstWhere((s) => s['type'] == type, orElse: () => null);

      if (homeItem == null && awayItem == null) return null;

      dynamic homeVal = homeItem?['value'];
      dynamic awayVal = awayItem?['value'];

      int parseVal(dynamic val) {
        if (val == null) return 0;
        final str = val.toString().replaceAll('%', '').trim();
        return int.tryParse(str) ?? 0;
      }

      return {
        'homeStr': homeVal?.toString() ?? '0',
        'awayStr': awayVal?.toString() ?? '0',
        'homeInt': parseVal(homeVal),
        'awayInt': parseVal(awayVal),
      };
    }

    final statsToDraw = [
      {'title': 'Posiadanie piłki', 'type': 'Ball Possession', 'isPercent': true},
      {'title': 'Strzały ogółem', 'type': 'Total Shots', 'isPercent': false},
      {'title': 'Strzały celne', 'type': 'Shots on Goal', 'isPercent': false},
      {'title': 'Rzuty rożne', 'type': 'Corner Kicks', 'isPercent': false},
      {'title': 'Faule', 'type': 'Fouls', 'isPercent': false},
      {'title': 'Żółte kartki', 'type': 'Yellow Cards', 'isPercent': false},
      {'title': 'Czerwone kartki', 'type': 'Red Cards', 'isPercent': false},
    ];

    final children = <Widget>[];

    for (final s in statsToDraw) {
      final parsed = getStat(s['type'] as String);
      if (parsed != null) {
        children.add(
          _buildComparisonBar(
            statName: s['title'] as String,
            homeStr: parsed['homeStr'] as String,
            awayStr: parsed['awayStr'] as String,
            homeValue: parsed['homeInt'] as int,
            awayValue: parsed['awayInt'] as int,
            isPercentage: s['isPercent'] as bool,
          ),
        );
      }
    }

    if (children.isEmpty) {
      return Center(
        child: Text(
          'Brak statystyk dla tego meczu',
          style: TextStyle(color: context.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: children,
    );
  }

  Widget _buildComparisonBar({
    required String statName,
    required String homeStr,
    required String awayStr,
    required int homeValue,
    required int awayValue,
    bool isPercentage = false,
  }) {
    final total = homeValue + awayValue;
    final homeRatio = total > 0 ? homeValue / total : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeStr,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor),
              ),
              Text(
                statName,
                style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
              ),
              Text(
                awayStr,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              color: context.border,
              child: Row(
                children: [
                  Expanded(
                    flex: (homeRatio * 100).toInt(),
                    child: Container(color: Colors.blue.shade600),
                  ),
                  Expanded(
                    flex: ((1 - homeRatio) * 100).toInt(),
                    child: Container(color: context.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
