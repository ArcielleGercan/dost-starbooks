import 'package:flutter/material.dart';
import 'quiz_game.dart';

class QuizResultScreen extends StatelessWidget {
  final String category;
  final String difficulty;
  final int correctAnswers;
  final int incorrectAnswers;
  final int totalQuestions;
  final double averageTime;
  final Map<String, dynamic>? badgeAwarded;
  final int? rewardsEarned;
  final String? userId;

  const QuizResultScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.totalQuestions,
    required this.averageTime,
    this.badgeAwarded,
    this.rewardsEarned,
    this.userId,
  });

  Color _getDifficultyColor() {
    switch (difficulty.toUpperCase()) {
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

  bool _isPerfectScore() {
    return correctAnswers == totalQuestions;
  }

  bool _hasBadge() {
    return badgeAwarded != null;
  }

  String _getResultImage() {
    if (_isPerfectScore()) {
      return "assets/images-badges/whiz-achiever.png";
    } else {
      return "assets/images-icons/sadlogout.png";
    }
  }

  String _getResultTitle() {
    if (_isPerfectScore()) {
      return "CONGRATULATIONS!";
    } else {
      return "TRY AGAIN!";
    }
  }

  String _getResultMessage() {
    if (_isPerfectScore() && _hasBadge()) {
      return "Perfect score! You've earned a badge!";
    } else if (_isPerfectScore()) {
      return "Perfect score! Amazing work!";
    } else {
      return "Not quite there yet, but don't give up!";
    }
  }

  Color _getResultColor() {
    if (_isPerfectScore()) {
      return const Color(0xFFFDD000);
    } else {
      return const Color(0xFFBD442E);
    }
  }

  String _getBadgeImage(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return "assets/images-badges/whiz-ready.png";
      case 'average':
        return "assets/images-badges/whiz-happy.png";
      case 'difficult':
        return "assets/images-badges/whiz-achiever.png";
      default:
        return "assets/images-badges/whiz-achiever.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(difficultyColor),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Stack(
                          children: [
                            Text(
                              _getResultTitle(),
                              style: TextStyle(
                                fontSize: 55,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                letterSpacing: 1.5,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 6
                                  ..color = _isPerfectScore()
                                      ? const Color(0xFFAC8337)
                                      : const Color(0xFF631F13),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                            Text(
                              _getResultTitle(),
                              style: TextStyle(
                                fontSize: 55,
                                fontWeight: FontWeight.bold,
                                color: _getResultColor(),
                                fontFamily: 'Poppins',
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getResultMessage(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_hasBadge()) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade300,
                                Colors.amber.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha:0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                _getBadgeImage(
                                    badgeAwarded!['difficulty'] ?? 'easy'),
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.emoji_events,
                                    size: 60,
                                    color: Colors.white,
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "🏆 BADGE EARNED!",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Text(
                                    "${badgeAwarded!['difficulty']?.toString().toUpperCase() ?? 'ACHIEVEMENT'} Level",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Image.asset(
                        _getResultImage(),
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _isPerfectScore()
                                ? Icons.emoji_events
                                : Icons.sentiment_dissatisfied,
                            size: 80,
                            color: _getResultColor(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC527),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "PERFORMANCE STATS",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatBox(
                                  "$correctAnswers",
                                  "Correct",
                                  const Color(0xFFACE2C8),
                                ),
                                _buildStatBox(
                                  "$incorrectAnswers",
                                  "Incorrect",
                                  const Color(0xFFFFB2A4),
                                ),
                                _buildStatBox(
                                  "${averageTime.toStringAsFixed(1)} s",
                                  "Avg time /\nQuestion",
                                  const Color(0xFFC2C5FF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Pop results screen
                                Navigator.of(context).pop(); // Pop WhizChallenge screen
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1D9358),
                                side: const BorderSide(
                                  color: Color(0xFF1D9358),
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                "Exit",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isPerfectScore()) {
                                  Navigator.of(context).pop();
                                } else {
                                  if (userId != null) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => QuizScreen(
                                          category: category,
                                          difficulty: difficulty,
                                          userId: userId!,
                                          participationType: "Whiz Challenge",
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).pop(false);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D9358),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                _isPerfectScore()
                                    ? "Next Level"
                                    : "Retry",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color difficultyColor) {
    return Container(
      width: double.infinity,
      color: difficultyColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            difficulty.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color backgroundColor) {
    return Container(
      width: 100,
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}