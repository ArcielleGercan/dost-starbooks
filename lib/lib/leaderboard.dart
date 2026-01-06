import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';

class Leaderboard extends StatefulWidget {
  final String currentUserId;
  final String userAvatar;
  final String username;

  const Leaderboard({
    super.key,
    required this.currentUserId,
    required this.userAvatar,
    required this.username,
  });

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final String baseUrl = "http://localhost:8000";

  String selectedGame = "whiz_challenge";
  bool isLoading = true;

  List<Map<String, dynamic>> leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => isLoading = true);

    try {
      await _loadQuizLeaderboard();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading leaderboard: $e');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadQuizLeaderboard() async {
    final mode = selectedGame == "whiz_challenge" ? "challenge" : "battle";

    String url = "$baseUrl/api/leaderboard?mode=$mode";
    url += "&limit=20";

    try {
      if (kDebugMode) {
        debugPrint('=================================');
        debugPrint('🔍 MODE: $mode');
        debugPrint('🔍 URL: $url');
        debugPrint('=================================');
      }

      final response = await http.get(Uri.parse(url));

      if (kDebugMode) {
        debugPrint('📡 Response Status: ${response.statusCode}');
        debugPrint('📦 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint('✅ Success: ${data['success']}');
          debugPrint('📊 Users count: ${data['users']?.length ?? 0}');
        }

        if (data['success'] == true) {
          final List<dynamic> users = data['users'] ?? [];

          if (kDebugMode && users.isNotEmpty) {
            debugPrint('👤 First user data:');
            debugPrint('   Username: ${users[0]['username']}');
            debugPrint('   Easy: ${users[0]['easy_count']}');
            debugPrint('   Average: ${users[0]['average_count']}');
            debugPrint('   Difficult: ${users[0]['difficult_count']}');
            debugPrint('   Total: ${users[0]['total_badges']}');
          }

          setState(() {
            leaderboardData = List<Map<String, dynamic>>.from(users).take(20).toList();
          });
        } else {
          if (kDebugMode) {
            debugPrint('❌ API returned success: false');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Non-200 status code: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in _loadQuizLeaderboard: $e');
      }
    }
  }

  String _extractId(dynamic idValue) {
    if (idValue is Map) {
      if (idValue.containsKey('\$oid')) {
        return idValue['\$oid'].toString();
      } else if (idValue.containsKey('oid')) {
        return idValue['oid'].toString();
      }
    }
    return idValue?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF046EB8),
      child: _buildLeaderboardPanel(),
    );
  }

  Widget _buildLeaderboardPanel() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          "LEADERBOARD",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(70, 0, 70, 40),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Game mode tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGameButton("Whiz Challenge", "whiz_challenge"),
                        const SizedBox(width: 20),
                        _buildGameButton("Whiz Battle", "whiz_battle"),
                      ],
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          await FlameAudio.play('click1.wav');
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        _loadLeaderboard();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Refreshing leaderboard...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 28),
                      tooltip: 'Refresh Leaderboard',
                      color: const Color(0xFF046EB8),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildTableHeader(),
                const SizedBox(height: 15),
                Expanded(
                  child: isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF046EB8),
                    ),
                  )
                      : leaderboardData.isEmpty
                      ? const Center(
                    child: Text(
                      "No rankings available",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    itemCount: leaderboardData.length,
                    itemBuilder: (context, index) {
                      final player = leaderboardData[index];
                      final rank = index + 1;
                      final playerId = _extractId(
                        player['player_id'] ?? player['id'] ?? player['_id'],
                      );
                      final isCurrentUser = playerId == widget.currentUserId;

                      return _buildRankingRow(player, rank, isCurrentUser);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameButton(String label, String gameId) {
    final isSelected = selectedGame == gameId;
    final gameColor = gameId == "whiz_challenge"
        ? const Color(0xFFFDD000)
        : const Color(0xFFC571E2);

    return ElevatedButton(
      onPressed: () async {
        try {
          await FlameAudio.play('click1.wav');
        } catch (e) {
          debugPrint('Click sound not found: $e');
        }
        setState(() => selectedGame = gameId);
        _loadLeaderboard();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? gameColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected ? gameColor : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90BE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 50,
            child: Text(
              "RANK",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            flex: 3,
            child: Text(
              "USERNAME",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "TOTAL\nBADGES",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "EASY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "AVERAGE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "DIFFICULT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingRow(Map<String, dynamic> player, int rank, bool isCurrentUser) {
    Color cardColor = isCurrentUser
        ? const Color(0xFFFDD000).withValues(alpha: 0.15)
        : (rank % 2 == 0 ? Colors.grey.withValues(alpha: 0.05) : Colors.white);

    Color borderColor = isCurrentUser ? const Color(0xFFFDD000) : Colors.transparent;

    final easyCount = player['easy_count'] ?? 0;
    final averageCount = player['average_count'] ?? 0;
    final difficultCount = player['difficult_count'] ?? 0;
    final totalBadges = player['total_badges'] ?? (easyCount + averageCount + difficultCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isCurrentUser ? 2 : 0),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: _buildRankBadge(rank)),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: _getRankColor(rank), width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      player['avatar'] ?? "assets/images-avatars/Adventurer.png",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Color(0xFF046EB8));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['username'] ?? player['player_username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCurrentUser)
                        const Text(
                          "YOU",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDD000),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildStatCell(
              "$totalBadges",
              const Color(0xFF046EB8),
              bold: true,
            ),
          ),
          Expanded(
            child: _buildStatCell("$easyCount", const Color(0xFF1D9358)),
          ),
          Expanded(
            child: _buildStatCell("$averageCount", const Color(0xFF046EB8)),
          ),
          Expanded(
            child: _buildStatCell("$difficultCount", const Color(0xFFBD442E)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(String value, Color color, {bool bold = false}) {
    return Center(
      child: Text(
        value,
        style: TextStyle(
          fontSize: bold ? 18 : 16,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor = _getRankColor(rank);
    IconData? medalIcon;

    if (rank <= 3) {
      medalIcon = Icons.emoji_events;
    }

    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: medalIcon != null
            ? Icon(medalIcon, color: Colors.white, size: 24)
            : Text(
          "$rank",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF046EB8);
    }
  }
}