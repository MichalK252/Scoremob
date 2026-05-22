import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import 'league_standings_screen.dart';

class LeaguesListScreen extends StatelessWidget {
  const LeaguesListScreen({super.key});

  static const List<Map<String, dynamic>> leagues = [
    {
      'id': '2',
      'code': 'CL',
      'name': 'UEFA Champions League',
      'country': 'Europa',
      'logo': 'https://media.api-sports.io/football/leagues/2.png',
      'color1': Color(0xFF0A2540),
      'color2': Color(0xFF001020),
      'accent': Colors.blueAccent,
    },
    {
      'id': '39',
      'code': 'PL',
      'name': 'Premier League',
      'country': 'Anglia',
      'logo': 'https://media.api-sports.io/football/leagues/39.png',
      'color1': Color(0xFF3D195A),
      'color2': Color(0xFF280A3D),
      'accent': Colors.purpleAccent,
    },
    {
      'id': '140',
      'code': 'PD',
      'name': 'LaLiga',
      'country': 'Hiszpania',
      'logo': 'https://media.api-sports.io/football/leagues/140.png',
      'color1': Color(0xFF1E293B),
      'color2': Color(0xFF0F172A),
      'accent': Colors.orangeAccent,
    },
    {
      'id': '78',
      'code': 'BL1',
      'name': 'Bundesliga',
      'country': 'Niemcy',
      'logo': 'https://media.api-sports.io/football/leagues/78.png',
      'color1': Color(0xFF800020),
      'color2': Color(0xFF4A0010),
      'accent': Colors.redAccent,
    },
    {
      'id': '135',
      'code': 'SA',
      'name': 'Serie A',
      'country': 'Włochy',
      'logo': 'https://media.api-sports.io/football/leagues/135.png',
      'color1': Color(0xFF0066B2),
      'color2': Color(0xFF003F7A),
      'accent': Colors.lightBlueAccent,
    },
    {
      'id': '61',
      'code': 'FL1',
      'name': 'Ligue 1',
      'country': 'Francja',
      'logo': 'https://media.api-sports.io/football/leagues/61.png',
      'color1': Color(0xFFDAA520),
      'color2': Color(0xFF8B6508),
      'accent': Colors.amberAccent,
    },
    {
      'id': '106',
      'code': 'EKSTR',
      'name': 'Ekstraklasa',
      'country': 'Polska',
      'logo': 'https://media.api-sports.io/football/leagues/106.png',
      'color1': Color(0xFF1B4D3E),
      'color2': Color(0xFF0F2D24),
      'accent': Colors.tealAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.headerBg,
        elevation: 0,
        title: Text(
          'Tabele ligowe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: context.textColor,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 104, left: 16, right: 16),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          final league = leagues[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.border,
                width: 1,
              ),
              gradient: LinearGradient(
                colors: [
                  league['color1'] as Color,
                  league['color2'] as Color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                        builder: (context) => LeagueStandingsScreen(league: league),
                      ),
                    );
                  },
                  splashColor: (league['accent'] as Color).withOpacity(0.15),
                  highlightColor: (league['accent'] as Color).withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                    child: Row(
                      children: [

                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: league['logo'] as String,
                            placeholder: (context, url) => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                league['name'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    size: 11,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    league['country'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: league['accent'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
