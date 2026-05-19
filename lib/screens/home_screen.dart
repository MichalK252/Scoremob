import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/football_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FootballApiService _apiService = FootballApiService();
  late Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _apiService.fetchTodayMatches();
  }

  // Grupowanie meczów po ligach
  Map<String, List<Map<String, dynamic>>> _groupMatchesByLeague(
      List<Map<String, dynamic>> matches) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var match in matches) {
      final league = match['league'] ?? 'Inne';
      if (!grouped.containsKey(league)) {
        grouped[league] = [];
      }
      grouped[league]!.add(match);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dzisiejsze Mecze'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Błąd:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak meczów na dziś'));
          }

          final matches = snapshot.data!;
          final groupedMatches = _groupMatchesByLeague(matches);
          final sortedLeagues = groupedMatches.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0),
            itemCount: sortedLeagues.length,
            itemBuilder: (context, leagueIndex) {
              final league = sortedLeagues[leagueIndex];
              final leagueMatches = groupedMatches[league]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek ligi
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          league,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mecze z danej ligi
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: leagueMatches.length,
                    itemBuilder: (context, matchIndex) {
                      final match = leagueMatches[matchIndex];
                      return _buildMatchCard(match);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Czas meczu
              Text(
                _formatTime(match['utcDate']),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade300,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              // Drużyny i wynik
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTeamColumn(match['homeTeam'], match['homeTeamCrest']),
                  _buildScoreColumn(
                    match['scoreHome'],
                    match['scoreAway'],
                    match['status'],
                  ),
                  _buildTeamColumn(match['awayTeam'], match['awayTeamCrest']),
                ],
              ),
              const SizedBox(height: 10),
              // Linia separatora
              Container(
                height: 0.5,
                color: Colors.grey.shade700,
              ),
              const SizedBox(height: 10),
              // Status meczu
              Text(
                _formatStatus(match['status']),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(match['status']),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String teamName, String crestUrl) {
    Widget imageWidget =
        const Icon(Icons.sports_soccer, size: 48, color: Colors.grey);

    if (crestUrl.isNotEmpty) {
      if (crestUrl.endsWith('.svg')) {
        imageWidget = SvgPicture.network(
          crestUrl,
          width: 48,
          height: 48,
          placeholderBuilder: (context) => const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: crestUrl,
          width: 48,
          height: 48,
          placeholder: (context, url) => const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
        );
      }
    }

    return Expanded(
      child: Column(
        children: [
          imageWidget,
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(int? scoreHome, int? scoreAway, String status) {
    return Column(
      children: [
        Text(
          scoreHome != null && scoreAway != null ? '$scoreHome - $scoreAway' : 'vs',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
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

  String _formatStatus(String status) {
    switch (status) {
      case 'SCHEDULED':
        return 'ZAPLANOWANY';
      case 'TIMED':
        return 'OCZEKUJE';
      case 'IN_PLAY':
        return 'TRWA';
      case 'PAUSED':
        return 'PRZERWA';
      case 'FINISHED':
        return 'ZAKOŃCZONY';
      case 'POSTPONED':
        return 'PRZEŁOŻONY';
      case 'SUSPENDED':
        return 'ZAWIESZONY';
      case 'CANCELED':
        return 'ANULOWANY';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_PLAY':
      case 'PAUSED':
        return Colors.green.shade400;
      case 'FINISHED':
        return Colors.blue.shade300;
      case 'SCHEDULED':
      case 'TIMED':
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade400;
    }
  }
}

class _HomeScreenStates extends State<HomeScreen> {
  final FootballApiService _apiService = FootballApiService();
  late Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _apiService.fetchTodayMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dzisiejsze Mecze'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Błąd:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak meczów na dziś'));
          }

          final matches = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(match['utcDate']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTeamColumn(match['homeTeam'], match['homeTeamCrest']),
                          _buildScoreColumn(match['scoreHome'], match['scoreAway'], match['status']),
                          _buildTeamColumn(match['awayTeam'], match['awayTeamCrest']),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamColumn(String teamName, String crestUrl) {
    Widget imageWidget = const Icon(Icons.sports_soccer, size: 48, color: Colors.grey);
    
    if (crestUrl.isNotEmpty) {
      if (crestUrl.endsWith('.svg')) {
        imageWidget = SvgPicture.network(
          crestUrl,
          width: 48,
          height: 48,
          placeholderBuilder: (context) => const SizedBox(
            width: 48, height: 48, 
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: crestUrl,
          width: 48,
          height: 48,
          placeholder: (context, url) => const SizedBox(
            width: 48, height: 48, 
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
        );
      }
    }

    return Expanded(
      child: Column(
        children: [
          imageWidget,
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(int? scoreHome, int? scoreAway, String status) {
    return Column(
      children: [
        Text(
          scoreHome != null && scoreAway != null
              ? '$scoreHome - $scoreAway'
              : 'vs',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatStatus(status),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: status == 'IN_PLAY' || status == 'PAUSED' ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
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

  String _formatStatus(String status) {
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
}
