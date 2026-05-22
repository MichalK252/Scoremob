import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/football_api.dart';
import '../theme/app_theme.dart';
import 'match_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FootballApiService _apiService = FootballApiService();
  late Future<List<Map<String, dynamic>>> _matchesFuture;
  late DateTime _selectedDate;
  late ScrollController _scrollController;
  late List<DateTime> _dates;

  static const Map<String, int> _leaguePriority = {

    '2': 1,
    '1': 2,
    '39': 3,
    '140': 4,
    '78': 5,
    '135': 6,
    '61': 7,
    '106': 8,
    '3': 9,
    '13': 10,
    '71': 11,

    'CL': 1,
    'WC': 2,
    'PL': 3,
    'PD': 4,
    'BL1': 5,
    'SA': 6,
    'FL1': 7,
    'ELC': 8,
    'DED': 9,
    'PPL': 10,
    'CLI': 11,
    'BSA': 12,
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
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
      _matchesFuture = _apiService.fetchMatches(date: _selectedDate);
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
      const double itemWidth = 52.0;
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
      _loadMatches();
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade400,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            colorScheme: ColorScheme.dark(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: context.cardBg,
              onSurface: context.textColor,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: context.cardBg,
              headerBackgroundColor: context.headerBg,
              headerForegroundColor: context.textColor,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return context.textColor.withOpacity(0.8);
              }),
              todayForegroundColor: WidgetStateProperty.all(Colors.blue.shade400),
              todayBorder: BorderSide(color: Colors.blue.shade400, width: 1.5),
              dividerColor: context.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.border, width: 1),
              ),
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

    return matches;
  }

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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.headerBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scoremob',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatFullDate(_selectedDate),
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: Colors.blue.shade400,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
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

          Container(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
              color: context.headerBg,
              border: Border(
                bottom: BorderSide(
                  color: context.border,
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
                                  : (isToday ? Colors.blue.shade400 : context.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : context.textColor.withOpacity(0.85),
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
                  ..sort((a, b) {
                    final aMatches = groupedMatches[a]!;
                    final bMatches = groupedMatches[b]!;
                    final aCode = aMatches.isNotEmpty ? aMatches.first['leagueCode'] : '';
                    final bCode = bMatches.isNotEmpty ? bMatches.first['leagueCode'] : '';

                    final aPriority = _leaguePriority[aCode] ?? 999;
                    final bPriority = _leaguePriority[bCode] ?? 999;

                    if (aPriority != bPriority) {
                      return aPriority.compareTo(bPriority);
                    }
                    return a.compareTo(b);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 104.0, left: 12.0, right: 12.0),
                  itemCount: sortedLeagues.length,
                  itemBuilder: (context, leagueIndex) {
                    final league = sortedLeagues[leagueIndex];
                    final leagueMatches = groupedMatches[league]!;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: context.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade500,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatLeagueName(league),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: context.border,
                          ),
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: leagueMatches.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 0.8,
                              color: context.border,
                            ),
                            itemBuilder: (context, matchIndex) {
                              final match = leagueMatches[matchIndex];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MatchDetailScreen(match: match),
                                    ),
                                  );
                                },
                                child: _buildMatchRow(match),
                              );
                            },
                          ),
                        ],
                      ),
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

  String _formatLeagueName(String name) {
    if (name.toLowerCase() == 'primera division') {
      return 'LaLiga';
    }
    return name;
  }

  Widget _buildMatchRow(Map<String, dynamic> match) {
    final status = match['status'] ?? 'SCHEDULED';
    final isLive = status == 'IN_PLAY' || status == 'PAUSED';
    final isFinished = status == 'FINISHED';
    final isScheduled = status == 'SCHEDULED' || status == 'TIMED';

    Widget statusWidget;
    if (isLive) {
      statusWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            status == 'PAUSED' ? 'PRZERWA' : 'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          const _LiveDotIndicator(),
        ],
      );
    } else if (isFinished) {
      statusWidget = Text(
        'KONIEC',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
        ),
      );
    } else if (isScheduled) {
      statusWidget = Text(
        _formatTime(match['utcDate']),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
    } else {
      statusWidget = Text(
        _formatShortStatus(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade400,
        ),
      );
    }

    final scoreHome = match['scoreHome'];
    final scoreAway = match['scoreAway'];
    final hasScore = scoreHome != null && scoreAway != null;

    bool isHomeWinner = false;
    bool isAwayWinner = false;
    if (isFinished && hasScore) {
      if (scoreHome > scoreAway) {
        isHomeWinner = true;
      } else if (scoreAway > scoreHome) {
        isAwayWinner = true;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Align(
              alignment: Alignment.centerLeft,
              child: statusWidget,
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: context.border,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTeamCrestMini(match['homeTeamCrest']),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match['homeTeam'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isHomeWinner ? FontWeight.bold : FontWeight.w500,
                          color: isHomeWinner ? context.textColor : context.textColor.withOpacity(0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTeamCrestMini(match['awayTeamCrest']),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        match['awayTeam'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isAwayWinner ? FontWeight.bold : FontWeight.w500,
                          color: isAwayWinner ? context.textColor : context.textColor.withOpacity(0.85),
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasScore ? scoreHome.toString() : '-',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasScore
                      ? (isLive ? Colors.green.shade400 : (isHomeWinner ? context.textColor : context.textColor.withOpacity(0.7)))
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasScore ? scoreAway.toString() : '-',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasScore
                      ? (isLive ? Colors.green.shade400 : (isAwayWinner ? context.textColor : context.textColor.withOpacity(0.7)))
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCrestMini(String crestUrl) {
    Widget imageWidget = const Icon(Icons.sports_soccer, size: 18, color: Colors.grey);

    if (crestUrl.isNotEmpty) {
      if (crestUrl.endsWith('.svg')) {
        imageWidget = SvgPicture.network(
          crestUrl,
          width: 18,
          height: 18,
          placeholderBuilder: (context) => const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 1),
          ),
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: crestUrl,
          width: 18,
          height: 18,
          placeholder: (context, url) => const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 1),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.sports_soccer, size: 18, color: Colors.grey),
        );
      }
    }

    return SizedBox(
      width: 18,
      height: 18,
      child: Center(child: imageWidget),
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

  String _formatShortStatus(String status) {
    switch (status) {
      case 'POSTPONED':
        return 'PRZEŁ.';
      case 'SUSPENDED':
        return 'ZAW.';
      case 'CANCELED':
        return 'ODWOŁ.';
      default:
        return status;
    }
  }

  String _getDayName(DateTime date) {
    final days = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];
    return days[date.weekday - 1];
  }
}

class _LiveDotIndicator extends StatefulWidget {
  const _LiveDotIndicator();

  @override
  State<_LiveDotIndicator> createState() => _LiveDotIndicatorState();
}

class _LiveDotIndicatorState extends State<_LiveDotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

