import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = Supabase.instance.client.auth.currentUser;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = Supabase.instance.client.auth.currentUser;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wylogowano pomyślnie'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd wylogowywania: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    } catch (_) {
      return 'Brak danych';
    }
  }

  String _getUserInitials(String email) {
    if (email.isEmpty) return 'U';
    final parts = email.split('@');
    if (parts.isEmpty) return 'U';
    final name = parts[0];
    if (name.length < 2) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  void _navigateToAuth({required bool isRegister}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthScreen(initialIsRegister: isRegister),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: user == null ? _buildGuestView() : _buildUserView(user),
    );
  }

  // --- GUEST VIEW (Not Logged In) ---
  Widget _buildGuestView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180.0,
          pinned: true,
          backgroundColor: const Color(0xFF0E0E10),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F1E36),
                    Color(0xFF0C0C0E),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 40,
                      color: Colors.blueAccent.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title & Subtitle
                const Text(
                  'Konto Kibica MatchDay',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Zaloguj się lub utwórz nowe konto, aby zsynchronizować swoje ulubione zespoły, powiadomienia i spersonalizowane ustawienia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Access Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _navigateToAuth(isRegister: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Zaloguj się',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _navigateToAuth(isRegister: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Założ bezpłatne konto',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Benefits Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Co zyskujesz rejestrując się?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitRow(
                        icon: Icons.star_rounded,
                        color: Colors.amberAccent,
                        title: 'Ulubione drużyny i ligi',
                        subtitle: 'Dostęp do spersonalizowanej listy wyników na ekranie głównym.',
                      ),
                      const Divider(color: Color(0xFF24242A), height: 24),
                      _buildBenefitRow(
                        icon: Icons.notifications_active_rounded,
                        color: Colors.greenAccent,
                        title: 'Powiadomienia push (wkrótce)',
                        subtitle: 'Otrzymuj alerty o golach i wynikach meczów na żywo.',
                      ),
                      const Divider(color: Color(0xFF24242A), height: 24),
                      _buildBenefitRow(
                        icon: Icons.cloud_sync_rounded,
                        color: Colors.blueAccent,
                        title: 'Synchronizacja danych',
                        subtitle: 'Twoje ustawienia i ulubione zespoły są zawsze bezpieczne w chmurze.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- USER VIEW (Logged In) ---
  Widget _buildUserView(User user) {
    final email = user.email ?? 'Kibic MatchDay';
    final initials = _getUserInitials(email);

    return CustomScrollView(
      slivers: [
        // App bar with title
        SliverAppBar(
          expandedHeight: 180.0,
          pinned: true,
          backgroundColor: const Color(0xFF0E0E10),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F2618), // Deep Forest/Sports Green
                    Color(0xFF0C0C0E),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Initials Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.tealAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Email
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1),
                        ),
                        child: const Text(
                          'Konto Aktywne',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Settings, Stats & Logout
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Quick Statistics Grid (Mock values)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Zapisane mecze',
                        value: '0',
                        icon: Icons.sports_soccer_rounded,
                        iconColor: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Ulubione ligi',
                        value: '0',
                        icon: Icons.star_rounded,
                        iconColor: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Account Information Card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                        child: Text(
                          'Dane użytkownika',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.mail_outline_rounded, color: Colors.grey, size: 20),
                        title: const Text('Adres e-mail', style: TextStyle(color: Colors.white, fontSize: 13)),
                        trailing: Text(
                          email,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const Divider(color: Color(0xFF24242A), height: 1, indent: 50),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 20),
                        title: const Text('Data rejestracji', style: TextStyle(color: Colors.white, fontSize: 13)),
                        trailing: Text(
                          _formatDateTime(user.createdAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Options List Card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                        child: Text(
                          'Ustawienia aplikacji',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications_none_rounded, color: Colors.grey, size: 20),
                        title: const Text('Ustawienia powiadomień', style: TextStyle(color: Colors.white, fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: () {},
                      ),
                      const Divider(color: Color(0xFF24242A), height: 1, indent: 50),
                      ListTile(
                        leading: const Icon(Icons.dark_mode_outlined, color: Colors.grey, size: 20),
                        title: const Text('Ciemny motyw', style: TextStyle(color: Colors.white, fontSize: 13)),
                        trailing: Switch(
                          value: true,
                          onChanged: (bool value) {},
                          activeColor: Colors.blueAccent,
                        ),
                      ),
                      const Divider(color: Color(0xFF24242A), height: 1, indent: 50),
                      ListTile(
                        leading: const Icon(Icons.help_outline_rounded, color: Colors.grey, size: 20),
                        title: const Text('Pomoc i regulamin', style: TextStyle(color: Colors.white, fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Wyloguj się',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
