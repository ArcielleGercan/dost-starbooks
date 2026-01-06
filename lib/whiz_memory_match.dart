import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_music_manager.dart';
import 'package:flame_audio/flame_audio.dart';

class WhizMemoryMatch extends StatefulWidget {
  final String userAvatar;
  final String playerId;
  final String username;

  const WhizMemoryMatch({
    super.key,
    this.userAvatar = "assets/images-avatars/Adventurer.png",
    required this.playerId,
    required this.username,
  });

  @override
  State<WhizMemoryMatch> createState() => _WhizMemoryMatchState();
}

class _WhizMemoryMatchState extends State<WhizMemoryMatch>
    with TickerProviderStateMixin {
  String _difficulty = "EASY";
  bool _gameStarted = false;
  int _timer = 0;
  int _moves = 0;
  Timer? _gameTimer;  // ✅ ADD THIS LINE

  int? _globalFastestTime;
  int? _fastestTime;
  final String baseUrl = "http://localhost:8000";

  List<CardItem> _cards = [];
  List<int> _flippedIndices = [];
  bool _isChecking = false;

  late final ConfettiController _confettiController;

  // NEW: Track win state
  bool _isNewPersonalRecord = false;
  bool _isNewBestTime = false;
  int _starsEarned = 0;
  int _totalStars = 0;
  Map<String, dynamic>? _newMilestone;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    GlobalMusicManager().stopMusic();
    setState(() {
      _gameStarted = true;
      _timer = 0;
      _isNewPersonalRecord = false;
      _isNewBestTime = false;
      _starsEarned = 0;
      _totalStars = 0;
      _moves = 0;
      _newMilestone = null;
      _generateCards();
    });

    _loadFastestTime();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _timer++);
      }
    });
  }

  Future<void> _saveFastestTime() async {
    try {
      debugPrint('Saving fastest time: $_timer seconds for difficulty: $_difficulty');

      final response = await http.post(
        Uri.parse('$baseUrl/api/game/fastest-time'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'player_id': widget.playerId,
          'game_type': 'memory_match',
          'difficulty': _difficulty,
          'time_seconds': _timer,
          'moves': 0, // Required by backend
        }),
      );

      debugPrint('Save fastest time response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Determine if it's a new personal record
        bool isNewRecord = data['is_new_record'] ?? false;

        // Determine if it's a new best time (beating global)
        bool isNewBest = _globalFastestTime != null && _timer < _globalFastestTime!;

        setState(() {
          _isNewPersonalRecord = isNewRecord;
          _isNewBestTime = isNewBest;
        });

        debugPrint('Is new personal record: $isNewRecord');
        debugPrint('Is new best time: $isNewBest');

        // Reload to get updated times
        await _loadFastestTime();
      }
    } catch (e) {
      debugPrint('Error saving fastest time: $e');
    }
  }

  Future<void> _awardStars() async {
    try {
      int starsEarned = _calculateStars();

      debugPrint('Awarding $starsEarned stars for difficulty: $_difficulty');

      final response = await http.post(
        Uri.parse('$baseUrl/api/players/${widget.playerId}/stars'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stars': starsEarned,
          'game_type': 'memory_match',
          'difficulty': _difficulty,
        }),
      );

      debugPrint('Stars API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _starsEarned = starsEarned;
          _totalStars = data['total_stars'];
          _newMilestone = data['new_milestone'];
        });
      } else {
        debugPrint('Failed to award stars: ${response.statusCode}');
        setState(() {
          _starsEarned = starsEarned;
        });
      }
    } catch (e) {
      debugPrint('Error awarding stars: $e');
      setState(() {
        _starsEarned = _calculateStars();
      });
    }
  }

  int _calculateStars() {
    final baseStars = _difficulty == "EASY" ? 1 : (_difficulty == "AVERAGE" ? 2 : 3);

    if (_globalFastestTime == null) {
      return baseStars * 5;
    }

    final performanceRatio = _globalFastestTime! / _timer;

    if (performanceRatio >= 1.0) {
      return baseStars * 5;
    } else if (performanceRatio >= 0.8) {
      return baseStars * 3;
    } else if (performanceRatio >= 0.6) {
      return baseStars * 2;
    } else {
      return baseStars;
    }
  }

  Future<void> _loadFastestTime() async {
    try {
      debugPrint('Loading fastest times for difficulty: $_difficulty');

      // Load personal fastest time
      final response = await http.get(
        Uri.parse('$baseUrl/api/game/fastest-time/${widget.playerId}/memory_match/$_difficulty'),
      );

      debugPrint('Personal fastest time response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _fastestTime = data['data']['time_seconds'];
          });
          debugPrint('Loaded personal fastest time: $_fastestTime');
        } else {
          setState(() {
            _fastestTime = null;
          });
          debugPrint('No personal fastest time found');
        }
      }

      // Load global fastest time
      final leaderboardResponse = await http.get(
        Uri.parse('$baseUrl/api/game/fastest-times/leaderboard?game_type=memory_match&difficulty=$_difficulty'),
      );

      debugPrint('Global leaderboard response: ${leaderboardResponse.statusCode}');
      debugPrint('Leaderboard body: ${leaderboardResponse.body}');

      if (leaderboardResponse.statusCode == 200) {
        final leaderboardData = json.decode(leaderboardResponse.body);
        if (leaderboardData['success'] == true) {
          final List<dynamic> times = leaderboardData['data'] ?? [];
          if (times.isNotEmpty) {
            setState(() {
              _globalFastestTime = times[0]['time_seconds'];
            });
            debugPrint('Loaded global fastest time: $_globalFastestTime');
          } else {
            setState(() {
              _globalFastestTime = null;
            });
            debugPrint('No global fastest time found');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading fastest times: $e');
    }
  }

  void _generateCards() {
    final pairs = _difficulty == "EASY" ? 5 : (_difficulty == "AVERAGE" ? 6 : 7);
    final prefix = _difficulty.toLowerCase();

    final cards = <CardItem>[];
    for (int i = 1; i <= pairs; i++) {
      final image = "assets/memorymatch/$prefix$i.png";
      cards.add(CardItem(id: i, imagePath: image));
      cards.add(CardItem(id: i, imagePath: image));
    }
    cards.shuffle(Random());
    setState(() {
      _cards = cards;
      _flippedIndices = [];
      _isChecking = false;
    });
  }

  void _onCardTap(int index) async {
    if (_isChecking ||
        _cards[index].isMatched ||
        _cards[index].isFlipped ||
        _flippedIndices.length >= 2) {
      return;
    }

    try {
      await FlameAudio.play('click1.wav');
    } catch (e) {
      debugPrint('Click sound not found: $e');
    }

    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      setState(() => _moves++);
      _checkMatch();
    }
  }

  Future<void> _checkMatch() async {
    _isChecking = true;
    final int firstIndex = _flippedIndices[0];
    final int secondIndex = _flippedIndices[1];

    final bool isMatch = _cards[firstIndex].id == _cards[secondIndex].id;

    setState(() {
      _cards[firstIndex].isMatching = isMatch;
      _cards[secondIndex].isMatching = isMatch;
      _cards[firstIndex].isNotMatching = !isMatch;
      _cards[secondIndex].isNotMatching = !isMatch;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      if (isMatch) {
        _cards[firstIndex].isMatched = true;
        _cards[secondIndex].isMatched = true;
      } else {
        _cards[firstIndex].isFlipped = false;
        _cards[secondIndex].isFlipped = false;
      }

      _cards[firstIndex].isMatching = false;
      _cards[secondIndex].isMatching = false;
      _cards[firstIndex].isNotMatching = false;
      _cards[secondIndex].isNotMatching = false;

      _flippedIndices.clear();
      _isChecking = false;
    });

    _checkWin();
  }

  void _checkWin() async {
    if (_cards.isNotEmpty && _cards.every((card) => card.isMatched)) {
      _gameTimer?.cancel();

      // Store OLD global best time BEFORE saving (this is the record to beat)
      final oldGlobalBest = _globalFastestTime;

      // Save fastest time first
      await _saveFastestTime();

      // Award stars
      await _awardStars();

      // Check if player beat the old global record
      if (oldGlobalBest != null && _timer < oldGlobalBest) {
        setState(() {
          _isNewBestTime = true;
        });
      } else {
        setState(() {
          _isNewBestTime = false;
        });
      }

      // Show combined win dialog
      if (mounted) {
        _showCombinedWinDialog();
      }
    }
  }

  void _showCombinedWinDialog() {
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Confetti animation
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(10, (index) {
                    return ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 10,
                      maxBlastForce: 15,
                      minBlastForce: 8,
                      gravity: 0.3,
                      colors: const [
                        Color(0xFFFDD000),
                        Color(0xFF5F6FDB),
                        Color(0xFF046EB8),
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.pink,
                        Colors.purple,
                      ],
                    );
                  }),
                ),
              ),
            ),
            Center(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Congratulations
                      // Congratulations - only if they beat the best time
                      Text(
                        _isNewBestTime ? 'CONGRATULATIONS!' : 'GAME COMPLETED!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _isNewBestTime ? const Color(0xFFFDD000) : const Color(0xFF5F6FDB),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Moves: $_moves',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Star icon and stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Stars Earned
                          Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFDD000).withValues(alpha: 0.2),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 35,
                                  color: Color(0xFFFDD000),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Stars Earned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<int>(
                                duration: const Duration(milliseconds: 1000),
                                tween: IntTween(begin: 0, end: _starsEarned),
                                builder: (context, value, child) {
                                  return Text(
                                    '+$value',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFDD000),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // Current Time
                          Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF5F6FDB).withValues(alpha: 0.2),
                                ),
                                child: const Icon(
                                  Icons.timer,
                                  size: 35,
                                  color: Color(0xFF5F6FDB),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<int>(
                                duration: const Duration(milliseconds: 1500),
                                tween: IntTween(begin: 0, end: _timer),
                                builder: (context, value, child) {
                                  return Text(
                                    _formatTime(value),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5F6FDB),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Total Stars
                      if (_totalStars > 0) ...[
                        Text(
                          'Total Stars: $_totalStars',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Milestone
                      if (_newMilestone != null) ...[
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDD000).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDD000), width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_newMilestone!['icon']} MILESTONE REACHED!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFDD000),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _newMilestone!['prize'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Your Previous Best (if exists and not a new record)
                      if (_fastestTime != null && _timer > _fastestTime!) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your Previous Best:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _formatTime(_fastestTime!),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Best Time (Global)
                      // Best Time (Global) - Only show if player DIDN'T beat it

                      // Best Time (Global) - Only show if player DIDN'T beat it
                      // Best Time Display - Always show, gold if they beat it
                      // Best Time Display - ALWAYS shown, in GOLD if they beat it
                      if (_globalFastestTime != null || _isNewBestTime) ...[
                        // Best Time Display - ALWAYS shown
                        // Best Time Display - ALWAYS shown
                        // Best Time Display - Show global best (or player's time if they beat it)
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _isNewBestTime
                                ? const Color(0xFFFDD000).withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: _isNewBestTime
                                ? Border.all(color: const Color(0xFFFDD000), width: 2)
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                _isNewBestTime ? '🏆 YOU BEAT THE RECORD!' : 'Best Time',
                                style: TextStyle(
                                  fontSize: _isNewBestTime ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isNewBestTime ? const Color(0xFFFDD000) : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(_isNewBestTime ? _timer : (_globalFastestTime ?? _timer)),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _isNewBestTime ? const Color(0xFFFDD000) : Colors.black87,
                                ),
                              ),
                              if (_isNewBestTime) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'New best record!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // New Personal Record Badge
                      if (_isNewPersonalRecord) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F6FDB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🎉 NEW PERSONAL RECORD!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await FlameAudio.play('click1.wav');
                                } catch (e) {
                                  debugPrint('Click sound not found: $e');
                                }
                                Navigator.pop(context);
                                Navigator.pop(context, true);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5F6FDB),
                                side: const BorderSide(color: Color(0xFF5F6FDB), width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text(
                                "EXIT",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await FlameAudio.play('click1.wav');
                                } catch (e) {
                                  debugPrint('Click sound not found: $e');
                                }
                                Navigator.pop(context);
                                _startGame();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5F6FDB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: const Text(
                                "PLAY AGAIN",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (_confettiController.state == ConfettiControllerState.playing) {
        _confettiController.stop();
      }
    });
  }

  void _showPauseDialog() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      const Text(
                        "PAUSED!",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F6FDB),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22, color: Colors.black54),
                        onPressed: () async {
                          try {
                            await FlameAudio.play('click1.wav');
                          } catch (e) {
                            debugPrint('Click sound not found: $e');
                          }
                          Navigator.pop(context);
                          _resumeGame();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // RESUME BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await FlameAudio.play('click1.wav');
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context);
                        _resumeGame();
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text(
                        "RESUME",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F6FDB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // RESTART BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await FlameAudio.play('click1.wav');
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context);

                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh, color: Color(0xFFFDD000), size: 60),
                                  const SizedBox(height: 15),
                                  const Text(
                                    "Restart Game",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Do you really want to restart? Your current progress will be lost.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () async {
                                            try {
                                              await FlameAudio.play('click1.wav');
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, false);
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: const BorderSide(color: Color(0xFF5F6FDB), width: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "No",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Color(0xFF5F6FDB),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await FlameAudio.play('click1.wav');
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFDD000),
                                            foregroundColor: const Color(0xFF816A03),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "Yes",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );

                        if (confirmed == true && mounted) {
                          _startGame();
                        } else if (mounted) {
                          _resumeGame();
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        "RESTART",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // EXIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await FlameAudio.play('click1.wav');
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context);

                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.exit_to_app, color: Colors.red, size: 60),
                                  const SizedBox(height: 15),
                                  const Text(
                                    "Exit Game",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Do you want to exit? Your current progress will be lost.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () async {
                                            try {
                                              await FlameAudio.play('click1.wav');
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, false);
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: const BorderSide(color: Color(0xFF5F6FDB), width: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "No",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Color(0xFF5F6FDB),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await FlameAudio.play('click1.wav');
                                            } catch (e) {
                                              debugPrint('Click sound not found: $e');
                                            }
                                            Navigator.pop(context, true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "Yes",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );

                        if (confirmed == true && mounted) {
                          Navigator.pop(context);
                        } else if (mounted) {
                          _resumeGame();
                        }
                      },
                      icon: const Icon(Icons.home, size: 20),
                      label: const Text(
                        "EXIT",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Colors.black26, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resumeGame() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _timer++);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Color _getDifficultyBackgroundColor() {
    switch (_difficulty) {
      case "EASY":
        return const Color(0xFF2E7D32);
      case "AVERAGE":
        return const Color(0xFF1976D2);
      case "DIFFICULT":
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color _getDifficultyBorderColor() {
    switch (_difficulty) {
      case "EASY":
        return const Color(0xFF2E7D32);
      case "AVERAGE":
        return const Color(0xFF1976D2);
      case "DIFFICULT":
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Future<void> _logoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/images-icons/sadlogout.png", width: 80, height: 80),
              const SizedBox(height: 15),
              const Text("Logout Confirmation",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text("Are you sure you want to log out?",
                  textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        try {
                          await FlameAudio.play('click1.wav');
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context, false);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF046EB8))),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await FlameAudio.play('click1.wav');
                        } catch (e) {
                          debugPrint('Click sound not found: $e');
                        }
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Logout",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showExitConfirmation() async {
    _gameTimer?.cancel(); // Pause the game

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
              const SizedBox(height: 15),
              const Text(
                "Exit Game",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to exit? Your progress will be lost.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false), // No - stay in game
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF5F6FDB), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        "No",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF5F6FDB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true), // Yes - exit
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        "Yes",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context); // Exit to homepage
    } else {
      _resumeGame(); // Resume if they clicked No
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            if (!_gameStarted) _buildTopBar(),
            Expanded(
              child: _gameStarted ? _buildGameBoard() : _buildDifficultySelection(),
            ),
          ],
        ),
    );
  }
  Widget _buildTopBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              // Logo on the left
              Image.asset(
                "assets/images-logo/starbooksmainlogo.png",
                width: 150,
                height: 50,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              // Avatar on the right
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _logoutDialog,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF046EB8), width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(widget.userAvatar, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF656BE6),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              // Simple back arrow button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: _gameStarted ? _showExitConfirmation : () async {
                  try {
                    await FlameAudio.play('click1.wav');
                  } catch (e) {
                    debugPrint('Click sound not found: $e');
                  }
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  "Whiz Memory Match",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 28),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelection() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Difficulty Level",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5F6FDB),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDifficultyButton("EASY", "5 pairs", const Color(0xFF2E7D32)),
                const SizedBox(width: 18),
                _buildDifficultyButton("AVERAGE", "6 pairs", const Color(0xFF1976D2)),
                const SizedBox(width: 18),
                _buildDifficultyButton("DIFFICULT", "7 pairs", const Color(0xFFD32F2F)),
              ],
            ),
            const SizedBox(height: 34),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FlameAudio.play('click1.wav');
                } catch (e) {
                  debugPrint('Click sound not found: $e');
                }
                _startGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD000),
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                "Start Game",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF915701),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String level, String points, Color color) {
    final isSelected = _difficulty == level;
    return GestureDetector(
      onTap: () async {
        try {
          await FlameAudio.play('click1.wav');
        } catch (e) {
          debugPrint('Click sound not found: $e');
        }
        setState(() => _difficulty = level);
      },
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Text(
              level,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              points,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGameBoard() {
    final totalCards = _cards.length;
    final cardsPerRow = (totalCards / 2).ceil();
    return Container(
      color: _getDifficultyBackgroundColor(),
      child: Column(
        children: [
          _buildGameStats(),
          const SizedBox(height: 48),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      cardsPerRow > _cards.length ? _cards.length : cardsPerRow,
                          (index) => _buildCard(index),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      _cards.length - cardsPerRow,
                          (index) => _buildCard(index + cardsPerRow),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  Widget _buildGameStats() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Moves: $_moves",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyBackgroundColor(),
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()), // <-- KEEP THIS (empty center space)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.pause_circle, size: 42, color: _getDifficultyBackgroundColor()),
                  onPressed: () async {
                    try {
                      await FlameAudio.play('click1.wav');
                    } catch (e) {
                      debugPrint('Click sound not found: $e');
                    }
                    _showPauseDialog();
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 44,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getDifficultyBackgroundColor(),
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: Center(
              child: Text(
                _formatTime(_timer),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    final showFront = card.isFlipped || card.isMatched;
    final backImage = "assets/memorymatch/${_difficulty.toLowerCase()}.png";
    return GestureDetector(
      onTap: () {
        if (!_isChecking && !card.isMatched) _onCardTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isMatching
                ? Colors.greenAccent
                : card.isNotMatching
                ? Colors.red
                : (showFront ? _getDifficultyBorderColor() : Colors.transparent),
            width: card.isMatching || card.isNotMatching ? 4 : (showFront ? 3 : 0),
          ),
          boxShadow: [
            if (card.isMatching)
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            if (card.isNotMatching)
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.8),
                blurRadius: 16,
                spreadRadius: 4,
              ),
          ],
        ),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('${card.id}_${card.isFlipped}_$index'),
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: showFront ? 0 : 1, end: showFront ? 1 : 0),
          builder: (context, value, _) {
            final angle = value * pi;
            final isBack = value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isBack
                    ? Image.asset(backImage, fit: BoxFit.cover)
                    : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: Image.asset(card.imagePath, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class CardItem {
  final int id;
  final String imagePath;
  bool isFlipped;
  bool isMatched;
  bool isMatching;
  bool isNotMatching;
  CardItem({
    required this.id,
    required this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
    this.isMatching = false,
    this.isNotMatching = false,
  });
}

