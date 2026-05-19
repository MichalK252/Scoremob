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
  late DateTime _selectedDate;
  late DateTime _currentMonthStart;
  late ScrollController _scrollController;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonthStart = DateTime.now();
    _scrollController = ScrollController();
    _updateDatesList(_selectedDate);
    _loadMatches();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(_selectedDate, animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMatches() {
    setState(() {
      _matchesFuture = _apiService.fetchMatches(date: _currentMonthStart);
    });
  }

  void _updateDatesList(DateTime centerDate) {
    _dates = List.generate(61, (index) {
      return DateTime(centerDate.year, centerDate.month, centerDate.day)
          .add(Duration(days: index - 30));
    });
  }

  void _scrollToDate(DateTime date, {bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final index = _dates.indexWhere((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);

    if (index != -1) {
      const double itemWidth = 52.0; // 46 width + 6 horizontal margin (3 on each side)
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      final clampedOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

      if (animate) {
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpTo(clampedOffset);
      }
    }
  }

  void _onDateSelected(DateTime date) {
    if (date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day) {
      return;
    }

    setState(() {
      _selectedDate = date;

      // Jeśli wybrana data jest poza zakresem, pobieramy nową paczkę (10 dni)
      final daysDifference = _selectedDate.difference(_currentMonthStart).inDays;
      if (daysDifference < 0 || daysDifference > 9) {
        _currentMonthStart = _selectedDate;
        _loadMatches();
      }
    });

    _scrollToDate(date);
  }

  String _getShortDayName(DateTime date) {
    final days = ['PON', 'WT', 'ŚR', 'CZW', 'PT', 'SOB', 'NDZ'];
    return days[date.weekday - 1];
  }

  String _getMonthNamePlGenitive(int month) {
    final months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
    ];
    return months[month - 1];
  }

  String _formatFullDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    String prefix = '';
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      prefix = 'Dziś, ';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      prefix = 'Wczoraj, ';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      prefix = 'Jutro, ';
    }

    final dayName = _getDayName(date);
    final day = date.day;
    final monthName = _getMonthNamePlGenitive(date.month);
    final year = date.year;

    return '$prefix$dayName, $day $monthName $year';
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue.shade500,
              onPrimary: Colors.white,
              surface: Colors.grey.shade900,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final index = _dates.indexWhere((d) =>
          d.year == picked.year && d.month == picked.month && d.day == picked.day);
      if (index == -1) {
        setState(() {
          _updateDatesList(picked);
        });
      }
      _onDateSelected(picked);

      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToDate(picked, animate: true);
      });
    }
  }

  List<Map<String, dynamic>> _filterMatchesByDate(
    List<Map<String, dynamic>> matches,
    DateTime date,
  ) {
    return matches.where((match) {
      final matchDate = DateTime.parse(match['utcDate']).toLocal();
      return matchDate.year == date.year &&
          matchDate.month == date.month &&
          matchDate.day == date.day;
    }).toList();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Mecze',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              _formatFullDate(_selectedDate),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: Colors.blue.shade400,
              size: 20,
            ),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selektor dat (pasek przesuwny)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E10),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade900,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

                  return GestureDetector(
                    onTap: () => _onDateSelected(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 46,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday && !isSelected
                              ? Colors.blue.shade800.withOpacity(0.4)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getShortDayName(date),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isToday ? Colors.blue.shade400 : Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          if (isToday && !isSelected) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Lista meczów
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
                }

                final allMatches = snapshot.data ?? [];
                final filteredMatches = _filterMatchesByDate(allMatches, _selectedDate);

                if (filteredMatches.isEmpty) {
                  return const Center(child: Text('Brak meczów na wybrany dzień'));
                }

                final groupedMatches = _groupMatchesByLeague(filteredMatches);
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
          ),
        ],
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



  String _getDayName(DateTime date) {
    final days = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];
    return days[date.weekday - 1];
  }
}


