import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'leagues_list_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LeaguesListScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
    const SearchScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(context.isDarkMode ? 0.35 : 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: context.isDarkMode
                              ? context.cardBg.withOpacity(0.85)
                              : context.cardBg.withOpacity(0.9),
                          border: Border.all(
                            color: context.border.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: _currentIndex < 4 ? 1.0 : 0.0,
                              child: AnimatedAlign(
                                alignment: Alignment(
                                    -1.0 + ((_currentIndex < 4 ? _currentIndex : 0) * (2.0 / 3.0)),
                                    0.0),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutBack,
                                child: FractionallySizedBox(
                                  widthFactor: 1 / 4,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        color: context.accent.withOpacity(0.12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _buildNavItem(0, Icons.sports_soccer_rounded, 'Mecze'),
                                _buildNavItem(1, Icons.leaderboard_rounded, 'Tabele'),
                                _buildNavItem(2, Icons.star_rounded, 'Ulubione'),
                                _buildNavItem(3, Icons.person_rounded, 'Profil'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildSearchButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    final isSelected = _currentIndex == 4;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(4),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: context.isDarkMode
                    ? context.cardBg.withOpacity(0.85)
                    : context.cardBg.withOpacity(0.9),
                border: Border.all(
                  color: isSelected
                      ? context.accent.withOpacity(0.5)
                      : context.border.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.accent.withOpacity(0.12),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    transform: isSelected
                        ? Matrix4.translationValues(0.0, -1.0, 0.0)
                        : Matrix4.identity(),
                    child: Icon(
                      Icons.search_rounded,
                      size: isSelected ? 26 : 24,
                      color: isSelected ? context.accent : context.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                transform: isSelected
                    ? Matrix4.translationValues(0.0, -2.0, 0.0)
                    : Matrix4.identity(),
                child: Icon(
                  icon,
                  size: isSelected ? 24 : 22,
                  color: isSelected ? context.accent : context.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? context.accent : context.textTertiary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
