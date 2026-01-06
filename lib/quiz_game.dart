import 'package:flutter/material.dart';
import 'dart:async';
import 'quiz_questions.dart';
import 'quiz_results.dart';
import 'quiz_api.dart';
import 'package:flame_audio/flame_audio.dart';
import 'global_music_manager.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  final String difficulty;
  final String userId;
  final String participationType;

  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.userId,
    this.participationType = "Whiz Challenge",
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  List<double> questionTimes = [];

  Timer? _timer;
  int _secondsRemaining = 15;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  bool _isAnswerLocked = false;
  bool _isMusicEnabled = true;

  bool _isLoading = true;
  String? _errorMessage;

  DateTime? _gameStartTime;
  int _totalGameDuration = 0;

  int get _timerDuration {
    final diff = widget.difficulty.toUpperCase();
    switch (diff) {
      case "EASY":
        return 15;
      case "AVERAGE":
        return 20;
      case "DIFFICULT":
        return 25;
      default:
        return 15;
    }
  }

  @override
  void initState() {
    super.initState();

    GlobalMusicManager().stopMusic();

    _gameStartTime = DateTime.now();
    _loadQuestions();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await FlameAudio.audioCache.load('quiz_music.mp3');
      if (_isMusicEnabled) {
        await FlameAudio.bgm.play('quiz_music.mp3', volume: 0.2);
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  Future<void> _pauseBackgroundMusic() async {
    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }
  }

  Future<void> _resumeBackgroundMusic() async {
    try {
      FlameAudio.bgm.resume();
    } catch (e) {
      debugPrint('Error resuming music: $e');
    }
  }

  Future<void> _stopBackgroundMusic() async {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }
  }

  Future<void> _restartBackgroundMusic() async {
    try {
      await FlameAudio.bgm.play('quiz_music.mp3', volume: 0.2);
    } catch (e) {
      debugPrint('Error restarting music: $e');
    }
  }

  void _toggleMusic() {
    setState(() {
      _isMusicEnabled = !_isMusicEnabled;
    });

    if (_isMusicEnabled) {
      _resumeBackgroundMusic();
    } else {
      _pauseBackgroundMusic();
    }
  }

  void _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final normalizedDifficulty = widget.difficulty.toUpperCase();
      debugPrint(
        'Loading questions for category: ${widget.category}, difficulty: $normalizedDifficulty',
      );

      questions = await QuizData.getQuestions(
        widget.category,
        normalizedDifficulty,
      );

      debugPrint('Loaded ${questions.length} questions');

      if (questions.isEmpty) {
        setState(() {
          _errorMessage =
          'No questions available for ${widget.category} - $normalizedDifficulty';
          _isLoading = false;
        });
        return;
      }


      setState(() {
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      debugPrint('ERROR loading questions: $e');
      setState(() {
        _errorMessage =
        'Failed to load questions. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _secondsRemaining = _timerDuration;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _handleTimeout();
          }
        });
      }
    });
  }

  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _handleTimeout();
          }
        });
      }
    });
  }

  void _handleTimeout() {
    if (_isAnswerLocked) return;

    _timer?.cancel();
    _isAnswerLocked = true;

    _pauseBackgroundMusic();

    setState(() {
      incorrectAnswers++;
      questionTimes.add(_timerDuration.toDouble());
      _showFeedback = true;
      _isCorrect = false;
      _selectedAnswer = null;
    });
  }

  void _handleAnswer(String answer) {
    if (_showFeedback || _isAnswerLocked) return;

    _timer?.cancel();
    _isAnswerLocked = true;

    final timeTaken = _timerDuration - _secondsRemaining;
    questionTimes.add(timeTaken.toDouble());

    final isCorrect = answer == questions[currentQuestionIndex].correctAnswer;

    setState(() {
      _selectedAnswer = answer;
    });

    _pauseBackgroundMusic();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showFeedback = true;
          _isCorrect = isCorrect;

          if (isCorrect) {
            correctAnswers++;
            score++;
          } else {
            incorrectAnswers++;
          }
        });
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _showFeedback = false;
        _isCorrect = false;
        _selectedAnswer = null;
        _isAnswerLocked = false;
      });
      _startTimer();
      if (_isMusicEnabled) {
        _restartBackgroundMusic();
      }
    } else {
      _saveResultAndNavigate();
    }
  }

  Future<void> _saveResultAndNavigate() async {
    _timer?.cancel();
    _stopBackgroundMusic();

    if (_gameStartTime != null) {
      _totalGameDuration = DateTime.now().difference(_gameStartTime!).inSeconds;
    }

    final avgTime = questionTimes.isNotEmpty
        ? questionTimes.reduce((a, b) => a + b) / questionTimes.length
        : 0.0;

    final rewards = correctAnswers * 10;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF046EB8)),
      ),
    );

    // Around line 175, update _saveResultAndNavigate:
    try {
      final response = await QuizApiService.saveChallengeResult(
        playerId: widget.userId,
        category: widget.category,
        difficultyLevel: _normalizeDifficulty(widget.difficulty),
        score: score,
        totalQuestions: questions.length,
        correctAnswers: correctAnswers,
        timeTaken: _totalGameDuration,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResultScreen(
              category: widget.category,
              difficulty: widget.difficulty,
              correctAnswers: correctAnswers,
              incorrectAnswers: incorrectAnswers,
              totalQuestions: questions.length,
              averageTime: avgTime,
              badgeAwarded: response.badgeAwarded,
              rewardsEarned: rewards,
              userId: widget.userId,
            ),
          ),
        );
      } else {
        _showErrorAndNavigate(avgTime);
      }
    } catch (e) {
      debugPrint('Error saving game result: $e');
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorAndNavigate(avgTime);
    }
  }

  String _normalizeDifficulty(String diff) {
    final normalized = diff.toUpperCase();
    switch (normalized) {
      case "EASY":
        return "Easy";
      case "AVERAGE":
        return "Average";
      case "DIFFICULT":
        return "Difficult";
      default:
        return "Easy";
    }
  }

  void _showErrorAndNavigate(double avgTime) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game completed but failed to sync with server'),
        backgroundColor: Colors.orange,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          category: widget.category,
          difficulty: widget.difficulty,
          correctAnswers: correctAnswers,
          incorrectAnswers: incorrectAnswers,
          totalQuestions: questions.length,
          averageTime: avgTime,
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    _timer?.cancel();
    final wasMusicEnabled = _isMusicEnabled;
    if (wasMusicEnabled) {
      _pauseBackgroundMusic();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
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
                  Text(
                    "PAUSED!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22, color: Colors.black54),
                    onPressed: () {
                      Navigator.pop(context);
                      _resumeTimer();
                      if (wasMusicEnabled && _isMusicEnabled) {
                        _resumeBackgroundMusic();
                      }
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
                  onPressed: () {
                    Navigator.pop(context);
                    _resumeTimer();
                    if (wasMusicEnabled && _isMusicEnabled) {
                      _resumeBackgroundMusic();
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text(
                    "RESUME",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getDifficultyColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Replace the RESTART BUTTON section in _showPauseDialog() (around line 419)
// RESTART BUTTON (with confirmation)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Keep pause dialog open, show confirmation
                    final confirmed = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: 400,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh,
                                color: Color(0xFFF39C12),
                                size: 60,
                              ),
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
                                "Do you really want to restart? Your progress will be lost.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: const BorderSide(
                                          color: Color(0xFF046EB8),
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        "No",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Color(0xFF046EB8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF39C12),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (confirmed == true && mounted) {
                      // Close pause dialog first
                      Navigator.pop(context);
                      // Stop music and restart game
                      _stopBackgroundMusic();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            category: widget.category,
                            difficulty: widget.difficulty,
                            userId: widget.userId,
                            participationType: widget.participationType,
                          ),
                        ),
                      );
                    }
                    // If cancelled, confirmation dialog closes automatically, pause dialog remains open
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    "RESTART",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
                    // Keep pause dialog open, show confirmation
                    final confirmed = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: 400,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.exit_to_app,
                                color: Color(0xFFE74C3C),
                                size: 60,
                              ),
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
                                "Do you want to exit? Your progress will be lost.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: const BorderSide(
                                          color: Color(0xFF046EB8),
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Color(0xFF046EB8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE74C3C),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        "Exit",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (confirmed == true && mounted) {
                      // Close pause dialog first
                      Navigator.pop(context);
                      // Stop music
                      _stopBackgroundMusic();
                      // Pop twice to exit quiz screen
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }
                    // If cancelled, confirmation dialog closes automatically, pause dialog remains open
                  },
                  icon: const Icon(Icons.home, size: 20),
                  label: const Text(
                    "EXIT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.black26, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopBackgroundMusic();
    super.dispose();
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty.toUpperCase()) {
      case "EASY":
        return const Color(0xFF1D9358);
      case "AVERAGE":
        return const Color(0xFF046EB8);
      case "DIFFICULT":
        return const Color(0xFFBD442E);
      default:
        return const Color(0xFF1D9358);
    }
  }

  Color _getButtonColor(int index) {
    final colors = [
      const Color(0xFF046EB8),
      const Color(0xFFF39C12),
      const Color(0xFFE67E22),
      const Color(0xFF9B59B6),
    ];
    return colors[index % colors.length];
  }

  String _getDifficultyBackground() {
    switch (widget.difficulty.toUpperCase()) {
      case "EASY":
        return "assets/backgrounds/easybg.png";
      case "AVERAGE":
        return "assets/backgrounds/averagebg.png";
      case "DIFFICULT":
        return "assets/backgrounds/difficultbg.png";
      default:
        return "assets/backgrounds/easybg.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: difficultyColor),
              const SizedBox(height: 20),
              const Text(
                'Loading questions...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Color(0xFFE74C3C),
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046EB8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loadQuestions,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(
                        'Retry',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9358),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz, size: 80, color: Color(0xFF046EB8)),
              const SizedBox(height: 20),
              const Text(
                'No questions available',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getDifficultyBackground()),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(difficultyColor),
            Expanded(
              child: _showFeedback
                  ? _buildFeedbackView(difficultyColor)
                  : _buildQuestionView(question, difficultyColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color difficultyColor) {
    return Container(
      width: double.infinity,
      color: difficultyColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            widget.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.difficulty.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(Question question, Color difficultyColor) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top row with pause and music controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _showPauseDialog,
                    icon: const Icon(
                      Icons.pause_circle,
                      color: Colors.black87,
                      size: 32,
                    ),
                    tooltip: 'Pause Game',
                  ),
                  IconButton(
                    onPressed: _toggleMusic,
                    icon: Icon(
                      _isMusicEnabled ? Icons.volume_up : Icons.volume_off,
                      color: Colors.black87,
                      size: 24,
                    ),
                    tooltip: _isMusicEnabled ? 'Mute Music' : 'Unmute Music',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Timer circle
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(
                  begin: _secondsRemaining / _timerDuration,
                  end: _secondsRemaining / _timerDuration,
                ),
                builder: (context, value, child) {
                  return SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              difficultyColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          "$_secondsRemaining",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: difficultyColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question: ${currentQuestionIndex + 1} of ${questions.length}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Score: $score",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: difficultyColor, width: 2),
                ),
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  return _buildAnswerButton(question.options[index], index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String answer, int index) {
    final buttonColor = _getButtonColor(index);
    final isSelected = _selectedAnswer == answer && _isAnswerLocked;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleAnswer(answer),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? buttonColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: buttonColor, width: isSelected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
                fontFamily: 'Poppins',
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackView(Color difficultyColor) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isCorrect ? "CORRECT ANSWER!" : "WRONG ANSWER!",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect
                      ? const Color(0xFF1D9358)
                      : const Color(0xFFE74C3C),
                  fontFamily: 'Poppins',
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046EB8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Next Question",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: difficultyColor, width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Image.asset(
                        "assets/images-icons/lightbulb.png",
                        width: 35,
                        height: 35,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.lightbulb,
                            color: Color(0xFFFFC107),
                            size: 40,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            questions[currentQuestionIndex].question,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Colors.black87,
                              ),
                              children: [
                                const TextSpan(
                                  text: "Answer: ",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: questions[currentQuestionIndex]
                                      .correctAnswer,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}