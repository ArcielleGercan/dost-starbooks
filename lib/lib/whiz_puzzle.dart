import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'global_music_manager.dart';
import 'package:flame_audio/flame_audio.dart';

class WhizPuzzle extends StatefulWidget {
  final String userAvatar;
  final String playerId;

  const WhizPuzzle({
    super.key,
    this.userAvatar = "assets/images-avatars/Adventurer.png",
    required this.playerId,
  });

  @override
  State<WhizPuzzle> createState() => _WhizPuzzleState();
}

class _WhizPuzzleState extends State<WhizPuzzle> {
  String _difficulty = "EASY";
  String? _category;
  bool _gameStarted = false;
  int _moves = 0;
  int _timer = 0;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _isNewPersonalRecord = false;
  bool _isNewBestTime = false;
  int _starsEarned = 0;
  int _totalStars = 0;
  Map<String, dynamic>? _newMilestone;
  late final ConfettiController _confettiController;

  int? _globalFastestTime;
  final String baseUrl = "http://localhost:8000";
  int? _fastestTime;
  Timer? _gameTimer;

  late int _gridSize;

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

  List<PuzzlePiece> _pieces = [];
  String? _imageUrl;

  final List<String> _categories = [
    'Solar System',
    'Scientists',
    'The Human Body',
    'Animals',
    'Geometry',
    'Starbooks',
  ];

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
    if (_category == null) {
      _showWarningDialog();
      return;
    }

    setState(() {
      _gameStarted = true;
      _moves = 0;
      _timer = 0;
      _isPaused = false;
      _isCompleted = false;
      _isNewPersonalRecord = false;  // ADD THIS
      _isNewBestTime = false;        // ADD THIS
      _starsEarned = 0;              // ADD THIS
      _totalStars = 0;               // ADD THIS
      _newMilestone = null;          // ADD THIS
      _initializePuzzle();
    });

    _loadFastestTime();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused && !_isCompleted) {
        setState(() => _timer++);
      }
    });
  }

// Add _loadFastestTime method:
  Future<void> _loadFastestTime() async {
    try {
      // Load personal fastest time
      String url = '$baseUrl/api/game/fastest-time/${widget.playerId}/puzzle/$_difficulty';

      if (_category != null) {
        url += '?category=$_category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            _fastestTime = data['data']['time_seconds'];
          });
        }
      }

      // Load global fastest time
      await _loadGlobalFastestTime();
    } catch (e) {
      debugPrint('Error loading fastest times: $e');
    }
  }

  void _initializePuzzle() {
    switch (_difficulty) {
      case "EASY":
        _gridSize = 3;
        break;
      case "AVERAGE":
        _gridSize = 4;
        break;
      case "DIFFICULT":
        _gridSize = 5;
        break;
      default:
        _gridSize = 3;
    }

    _imageUrl = _getCategoryImage(_category!);

    List<PuzzlePiece> pieces = [];
    final random = Random();
    final trayWidth = 260.0;
    final trayHeight = 400.0;

    for (int i = 0; i < _gridSize * _gridSize; i++) {
      final correctRow = i ~/ _gridSize;
      final correctCol = i % _gridSize;

      pieces.add(PuzzlePiece(
        id: i,
        correctRow: correctRow,
        correctCol: correctCol,
        trayX: random.nextDouble() * (trayWidth - 60),
        trayY: random.nextDouble() * (trayHeight - 60),
        isLocked: false,
        isInTray: true,
      ));
    }

    _pieces = pieces;
  }

  String _getCategoryImage(String category) {
    switch (category) {
      case 'Solar System':
        return 'assets/puzzle/solar_system.png';
      case 'Scientists':
        return 'assets/puzzle/scientists.jpg';
      case 'The Human Body':
        return 'assets/puzzle/human_body.png';
      case 'Animals':
        return 'assets/puzzle/animals.jpg';
      case 'Geometry':
        return 'assets/puzzle/geometry.jpg';
      case 'Starbooks':
        return 'assets/puzzle/starbookswhiz.jpeg';
      default:
        return 'assets/puzzle/animals.png';
    }
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _checkCompletion() async {
    if (_pieces.every((piece) => piece.isLocked)) {
      setState(() {
        _isCompleted = true;
        _gameTimer?.cancel();
      });

      // Store OLD global best time BEFORE saving (this is the record to beat)
      final oldGlobalBest = _globalFastestTime;

      // Save the time first
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

  Future<void> _saveFastestTime() async {
    try {
      debugPrint('Saving fastest time: $_timer seconds for difficulty: $_difficulty, category: $_category');

      final response = await http.post(
        Uri.parse('$baseUrl/api/game/fastest-time'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'player_id': widget.playerId,
          'game_type': 'puzzle',
          'difficulty': _difficulty,
          'category': _category,
          'time_seconds': _timer,
          'moves': _moves,
        }),
      );

      debugPrint('Save fastest time response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Determine if it's a new personal record
        bool isNewRecord = data['is_new_record'] ?? false;

        setState(() {
          _isNewPersonalRecord = isNewRecord;
        });

        debugPrint('Is new personal record: $isNewRecord');

        // Reload to get updated times
        await _loadFastestTime();
        await _loadGlobalFastestTime();
      }
    } catch (e) {
      debugPrint('Error saving fastest time: $e');
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 60, color: Color(0xFF656BE6)),
              const SizedBox(height: 15),
              const Text(
                "Incomplete Selection",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please select a category before starting the game.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF656BE6),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPauseDialog() {
    setState(() => _isPaused = true);
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
                          color: Color(0xFFE6833A),
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
                          setState(() => _isPaused = false);
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
                          setState(() => _isPaused = false);
                          _resumeGame();
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text(
                        "RESUME",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6833A),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Do you really want to restart? Your current progress will be lost.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14),
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
                                            side: const BorderSide(color: Color(0xFFE6833A), width: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "No",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFE6833A),
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
                          setState(() => _isPaused = false);
                          _startGame();
                        } else if (mounted) {
                          setState(() => _isPaused = false);
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Do you want to exit? Your current progress will be lost.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14),
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
                                            side: const BorderSide(color: Color(0xFFE6833A), width: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text(
                                            "No",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFE6833A),
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
                          setState(() => _isPaused = false);
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
      if (mounted && !_isPaused && !_isCompleted) {
        setState(() => _timer++);
      }
    });
  }

  Future<void> _loadGlobalFastestTime() async {
    try {
      String url = '$baseUrl/api/game/fastest-times/leaderboard?game_type=puzzle&difficulty=$_difficulty';

      if (_category != null) {
        url += '&category=$_category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> times = data['data'] ?? [];
          if (times.isNotEmpty) {
            setState(() {
              _globalFastestTime = times[0]['time_seconds'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading global fastest time: $e');
    }
  }

  Future<void> _awardStars() async {
    try {
      int starsEarned = _calculateStars();
      debugPrint('Awarding $starsEarned stars for difficulty: $_difficulty, category: $_category');

      final response = await http.post(
        Uri.parse('$baseUrl/api/players/${widget.playerId}/stars'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stars': starsEarned,
          'game_type': 'puzzle',
          'difficulty': _difficulty,
          'category': _category,
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 10),
              const Text("Are you sure you want to log out?",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
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
                          style: TextStyle(fontSize: 14, color: Color(0xFF046EB8))),
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
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                        Color(0xFFE6833A),
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
                      // Title
                      Text(
                        _isNewBestTime ? 'CONGRATULATIONS!' : 'GAME COMPLETED!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _isNewBestTime ? const Color(0xFFFDD000) : const Color(0xFFE6833A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category
                      Text(
                        _category ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Moves
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
                                  color: const Color(0xFFE6833A).withValues(alpha: 0.2),
                                ),
                                child: const Icon(
                                  Icons.timer,
                                  size: 35,
                                  color: Color(0xFFE6833A),
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
                                      color: Color(0xFFE6833A),
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

                      // Best Time Display - Always show if available
                      if (_globalFastestTime != null || _isNewBestTime) ...[
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
                            color: const Color(0xFFE6833A),
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
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE6833A),
                                side: const BorderSide(color: Color(0xFFE6833A), width: 2),
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
                                backgroundColor: const Color(0xFFE6833A),
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
              Image.asset(
                "assets/images-logo/starbooksmainlogo.png",
                width: 150,
                height: 50,
                fit: BoxFit.contain,
              ),
              const Spacer(),
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
            color: Color(0xFFE6833A),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () async {
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
                  "Whiz Puzzle",
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Difficulty Level",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE6833A),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            _buildDifficultyButton("EASY", "3x3 Grid", const Color(0xFF2E7D32)),
                            const SizedBox(height: 16),
                            _buildDifficultyButton("AVERAGE", "4x4 Grid", const Color(0xFF1976D2)),
                            const SizedBox(height: 16),
                            _buildDifficultyButton("DIFFICULT", "5x5 Grid", const Color(0xFFD32F2F)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 80),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Select Category",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE6833A),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: 700,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 2.8,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _category == category;

                              Color categoryColor = const Color(0xFF9E9E9E);
                              if (isSelected) {
                                categoryColor = _getDifficultyBorderColor();
                              }

                              return GestureDetector(
                                onTap: () async {
                                  try {
                                    await FlameAudio.play('click1.wav');
                                  } catch (e) {
                                    debugPrint('Click sound not found: $e');
                                  }
                                  setState(() => _category = category);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: isSelected ? categoryColor : Colors.white,
                                    border: Border.all(
                                      color: isSelected ? categoryColor : const Color(0xFF9E9E9E),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6833A),
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                ),
                child: const Text(
                  "Start Game",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String level, String gridInfo, Color color) {
    bool isSelected = _difficulty == level;
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
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(30),
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
              gridInfo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withValues(alpha:0.9) : color.withValues(alpha:0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    final gridCellSize = _difficulty == "EASY" ? 165.0 : (_difficulty == "AVERAGE" ? 125.0 : 105.0);

    return Container(
      color: const Color(0xFFE6833A),
      child: Stack(
        children: [
          Column(
            children: [
              _buildGameStats(),
              const SizedBox(height: 55),
              Text(
                _category ?? "",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: gridCellSize * _gridSize,
                      height: gridCellSize * _gridSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.3),
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                        ),
                        itemCount: _gridSize * _gridSize,
                        itemBuilder: (context, index) {
                          final row = index ~/ _gridSize;
                          final col = index % _gridSize;
                          final piece = _pieces.firstWhere(
                                (p) => p.isLocked && p.correctRow == row && p.correctCol == col,
                            orElse: () => PuzzlePiece(
                              id: -1,
                              correctRow: -1,
                              correctCol: -1,
                              trayX: 0,
                              trayY: 0,
                              isLocked: false,
                            ),
                          );

                          return DragTarget<int>(
                            onWillAcceptWithDetails: (details) => !_isPaused,
                            onAcceptWithDetails: (details) {
                              final draggedPiece = _pieces.firstWhere((p) => p.id == details.data);
                              setState(() {
                                if (draggedPiece.correctRow == row && draggedPiece.correctCol == col) {
                                  draggedPiece.isLocked = true;
                                  _checkCompletion();
                                }
                                _moves++;
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 2),
                                  color: piece.id != -1
                                      ? Colors.white.withValues(alpha:0.2)
                                      : Colors.transparent,
                                ),
                                child: piece.id != -1
                                    ? _buildPuzzlePieceImage(piece, gridCellSize)
                                    : const SizedBox.shrink(),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 40),
                    Container(
                      width: 280,
                      height: gridCellSize * _gridSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: _pieces
                            .where((piece) => !piece.isLocked && piece.isInTray)
                            .map((piece) => _buildDraggablePiece(piece, gridCellSize))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
          ..._pieces
              .where((piece) => !piece.isLocked && !piece.isInTray && piece.floatingPosition != null)
              .map((piece) => _buildFloatingPiece(piece, gridCellSize))
        ],
      ),
    );
  }

  Widget _buildDraggablePiece(PuzzlePiece piece, double cellSize) {
    return Positioned(
      left: piece.trayX,
      top: piece.trayY,
      child: Draggable<int>(
        data: piece.id,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          if (!piece.isLocked) {
            setState(() {
              piece.isInTray = false;
              piece.floatingPosition = details.offset;
            });
          }
        },
        child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
      ),
    );
  }

  Widget _buildPuzzlePieceImage(PuzzlePiece piece, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.none,
          alignment: Alignment(
            _gridSize == 1 ? 0.0 : (piece.correctCol / (_gridSize - 1)) * 2 - 1,
            _gridSize == 1 ? 0.0 : (piece.correctRow / (_gridSize - 1)) * 2 - 1,
          ),
          child: SizedBox(
            width: size * _gridSize,
            height: size * _gridSize,
            child: Image.asset(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey,
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: size * 0.5,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingPiece(PuzzlePiece piece, double cellSize) {
    return Positioned(
      left: piece.floatingPosition!.dx,
      top: piece.floatingPosition!.dy,
      child: Draggable<int>(
        data: piece.id,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          if (!piece.isLocked) {
            setState(() {
              piece.floatingPosition = details.offset;
            });
          }
        },
        child: _buildPuzzlePieceImage(piece, cellSize * 0.8),
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
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6833A),
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.pause_circle, size: 44, color: Color(0xFFE6833A)),
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
          top: 50,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6833A),
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
            ),
            child: Center(
              child: Text(
                _formatTime(_timer),
                style: const TextStyle(
                  fontSize: 20,
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
}

// PuzzlePiece class
class PuzzlePiece {
  final int id;
  final int correctRow;
  final int correctCol;
  double trayX;
  double trayY;
  bool isLocked;
  bool isInTray;
  Offset? floatingPosition;

  PuzzlePiece({
    required this.id,
    required this.correctRow,
    required this.correctCol,
    required this.trayX,
    required this.trayY,
    required this.isLocked,
    this.isInTray = true,
    this.floatingPosition,
  });
}

