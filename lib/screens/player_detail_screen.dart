import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/football_api.dart';
import '../theme/app_theme.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String playerPhoto;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerPhoto,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final FootballApiService _apiService = FootballApiService();

  Map<String, dynamic>? _playerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerDetails();
  }

  Future<void> _loadPlayerDetails() async {
    try {
      final data = await _apiService.fetchPlayerDetails(widget.playerId);
      if (mounted) {
        setState(() {
          _playerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading player details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.headerBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.playerName,
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: context.accent),
            )
          : _playerData == null
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded,
              size: 48, color: context.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Brak danych o zawodniku',
            style: TextStyle(
              color: context.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final data = _playerData!;
    final stats = (data['statistics'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final fullName = data['fullName'] ?? '$firstName $lastName';
    final photo = data['photo'] ?? widget.playerPhoto;
    final nationality = data['nationality'] ?? '';
    final age = data['age']?.toString() ?? '';
    final height = data['height'] ?? '';
    final weight = data['weight'] ?? '';
    final birthDate = data['birthDate'] ?? '';
    final birthPlace = data['birthPlace'] ?? '';
    final birthCountry = data['birthCountry'] ?? '';

    String position = '';
    if (stats.isNotEmpty) {
      position = stats[0]['position'] ?? '';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [

          _buildPlayerHeader(
            photo: photo,
            fullName: fullName,
            nationality: nationality,
            position: position,
          ),
          const SizedBox(height: 20),

          _buildBioSection(
            age: age,
            height: height,
            weight: weight,
            birthDate: birthDate,
            birthPlace: birthPlace,
            birthCountry: birthCountry,
            nationality: nationality,
          ),
          const SizedBox(height: 20),

          if (stats.isNotEmpty) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statystyki sezonu',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...stats.map((stat) => _buildLeagueStatCard(stat)),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerHeader({
    required String photo,
    required String fullName,
    required String nationality,
    required String position,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: context.headerBg,
        border: Border(
          bottom: BorderSide(
              color: context.border, width: 1),
        ),
      ),
      child: Column(
        children: [

          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.accent.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.accent.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: context.cardBg,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: photo,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: 40,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          if (nationality.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined,
                    size: 14, color: context.textSecondary),
                const SizedBox(width: 5),
                Text(
                  nationality,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),

          if (position.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: context.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _translatePosition(position),
                style: TextStyle(
                  color: context.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBioSection({
    required String age,
    required String height,
    required String weight,
    required String birthDate,
    required String birthPlace,
    required String birthCountry,
    required String nationality,
  }) {
    final birthLocationParts = <String>[];
    if (birthPlace.isNotEmpty) birthLocationParts.add(birthPlace);
    if (birthCountry.isNotEmpty) birthLocationParts.add(birthCountry);
    final birthLocation = birthLocationParts.join(', ');

    final bioItems = <_BioEntry>[
      if (age.isNotEmpty && age != '0')
        _BioEntry('Wiek', '$age lat'),
      if (height.isNotEmpty && height != '')
        _BioEntry('Wzrost', height),
      if (weight.isNotEmpty && weight != '')
        _BioEntry('Waga', weight),
      if (birthDate.isNotEmpty)
        _BioEntry('Data urodzenia', _formatBirthDate(birthDate)),
      if (birthLocation.isNotEmpty)
        _BioEntry('Miejsce urodzenia', birthLocation),
      if (nationality.isNotEmpty)
        _BioEntry('Narodowość', nationality),
    ];

    if (bioItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: context.accent.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  'Informacje',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 0,
              runSpacing: 0,
              children: bioItems
                  .map((entry) => _buildBioTile(entry.label, entry.value,
                      bioItems.length))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioTile(String label, String value, int totalCount) {

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 32 - 36) / 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: context.textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueStatCard(Map<String, dynamic> stat) {
    final leagueName = stat['leagueName'] ?? '';
    final leagueLogo = stat['leagueLogo'] ?? '';
    final teamName = stat['teamName'] ?? '';
    final teamLogo = stat['teamLogo'] ?? '';

    final appearances = stat['appearances']?.toString() ?? '0';
    final minutes = stat['minutes']?.toString() ?? '0';
    final goals = stat['goals']?.toString() ?? '0';
    final assists = stat['assists']?.toString() ?? '0';
    final yellowCards = stat['yellowCards']?.toString() ?? '0';
    final redCards = stat['redCards']?.toString() ?? '0';
    final shots = stat['shots']?.toString() ?? '0';
    final shotsOnTarget = stat['shotsOnTarget']?.toString() ?? '0';
    final passAccuracy = stat['passAccuracy']?.toString() ?? '0';
    final keyPasses = stat['keyPasses']?.toString() ?? '0';
    final tacklesTotal = stat['tacklesTotal']?.toString() ?? '0';
    final rating = stat['rating']?.toString() ?? '-';

    String formattedRating = '-';
    if (rating.isNotEmpty && rating != '-' && rating != 'null') {
      try {
        formattedRating = double.parse(rating).toStringAsFixed(1);
      } catch (_) {
        formattedRating = rating;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.border,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (leagueLogo.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: leagueLogo,
                      width: 22,
                      height: 22,
                      errorWidget: (context, url, error) => Icon(
                          Icons.emoji_events_outlined,
                          size: 22,
                          color: context.textTertiary),
                    ),
                  if (leagueLogo.isNotEmpty) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      leagueName,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (teamName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    if (teamLogo.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: teamLogo,
                        width: 18,
                        height: 18,
                        errorWidget: (context, url, error) =>
                            Icon(Icons.sports_soccer,
                                size: 18, color: context.textTertiary),
                      ),
                    if (teamLogo.isNotEmpty) const SizedBox(width: 8),
                    Text(
                      teamName,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildStatTile(
                    icon: Icons.sports_soccer,
                    value: appearances,
                    label: 'Mecze',
                  ),
                  _buildStatTile(
                    icon: Icons.timer_outlined,
                    value: minutes,
                    label: 'Minuty',
                  ),
                  _buildStatTile(
                    icon: Icons.gps_fixed_rounded,
                    value: goals,
                    label: 'Gole',
                    valueColor: int.tryParse(goals) != null &&
                            int.tryParse(goals)! > 0
                        ? Colors.greenAccent
                        : null,
                  ),
                  _buildStatTile(
                    icon: Icons.handshake_outlined,
                    value: assists,
                    label: 'Asysty',
                  ),
                  _buildStatTile(
                    icon: Icons.square_rounded,
                    iconColor: Colors.amber,
                    value: yellowCards,
                    label: 'Żółte kartki',
                  ),
                  _buildStatTile(
                    icon: Icons.square_rounded,
                    iconColor: Colors.redAccent,
                    value: redCards,
                    label: 'Czerwone kartki',
                  ),
                  _buildStatTile(
                    icon: Icons.track_changes_rounded,
                    value: shots,
                    label: 'Strzały',
                  ),
                  _buildStatTile(
                    icon: Icons.crisis_alert_rounded,
                    value: shotsOnTarget,
                    label: 'Celne strzały',
                  ),
                  _buildStatTile(
                    icon: Icons.swap_horiz_rounded,
                    value: '$passAccuracy%',
                    label: 'Dok. podań',
                  ),
                  _buildStatTile(
                    icon: Icons.assistant_rounded,
                    value: keyPasses,
                    label: 'Kluczowe pod.',
                  ),
                  _buildStatTile(
                    icon: Icons.shield_outlined,
                    value: tacklesTotal,
                    label: 'Odbiory',
                  ),
                  _buildStatTile(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    value: formattedRating,
                    label: 'Ocena',
                    valueColor: formattedRating != '-'
                        ? Colors.amber
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.border,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ?? context.textTertiary,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? context.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _translatePosition(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return 'BRAMKARZ';
      case 'defender':
        return 'OBROŃCA';
      case 'midfielder':
        return 'POMOCNIK';
      case 'attacker':
        return 'NAPASTNIK';
      default:
        return position.toUpperCase();
    }
  }

  String _formatBirthDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    } catch (_) {}
    return date;
  }
}

class _BioEntry {
  final String label;
  final String value;
  const _BioEntry(this.label, this.value);
}
