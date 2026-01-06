import 'package:flutter/material.dart';
import 'quiz_game.dart';
import 'global_music_manager.dart';
import 'package:flame_audio/flame_audio.dart';

class WhizChallenge extends StatefulWidget {
  final String userId;
  final String userAvatar;
  final String username;

  const WhizChallenge({
    super.key,
    required this.userId,
    required this.userAvatar,
    required this.username,
  });

  @override
  State<WhizChallenge> createState() => _WhizChallengeState();
}

class _WhizChallengeState extends State<WhizChallenge> {
  String selectedCategory = 'Science';
  String selectedDifficulty = 'Easy';
  String? _hoveredCategory;

  Future<void> _logoutDialog() async {
    try {
      await FlameAudio.play('click1.wav');
    } catch (e) {
      debugPrint('Click sound not found: $e');
    }

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
              const Text(
                "Logout Confirmation",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to log out?",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        try {
                          FlameAudio.play('click1.wav');
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
                      onPressed: () {
                        try {
                          FlameAudio.play('click1.wav');
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
                        "Logout",
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
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _buildSelectionScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // White top section with logo and avatar
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
                      child: Image.asset(
                        widget.userAvatar,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Colored header bar with back button and game name
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFFDD000),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF915701), size: 28),
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
                  "Starbooks Whiz Challenge",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF915701),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 28), // Balance the back button space
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    Column(
                      children: [
                        const Text(
                          "Select Category",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDD000),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            _buildCategoryCard('Science', 'assets/images-icons/science.png'),
                            const SizedBox(width: 30),
                            _buildCategoryCard('Math', 'assets/images-icons/math.png'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 80),
                    // Difficulty Selection
                    Column(
                      children: [
                        const Text(
                          "Difficulty Level",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDD000),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildDifficultyButton('Easy', const Color(0xFF1D9358)),
                        _buildDifficultyButton('Average', const Color(0xFF046EB8)),
                        _buildDifficultyButton('Difficult', const Color(0xFFBD442E)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                // PLAY Button
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FlameAudio.play('click1.wav');
                    } catch (e) {
                      debugPrint('Click sound not found: $e');
                    }
                    GlobalMusicManager().stopMusic();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          category: selectedCategory,
                          difficulty: selectedDifficulty,
                          userId: widget.userId,
                          participationType: 'Whiz Challenge',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD000),
                    foregroundColor: const Color(0xFF915701),
                    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "PLAY",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category, String imagePath) {
    final isSelected = selectedCategory == category;
    final isHovered = _hoveredCategory == category;
    final showColorful = isSelected || isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredCategory = category),
      onExit: (_) => setState(() => _hoveredCategory = null),
      child: GestureDetector(
        onTap: () async {
          try {
            await FlameAudio.play('click1.wav');
          } catch (e) {
            debugPrint('Click sound not found: $e');
          }
          setState(() => selectedCategory = category);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 220,
          height: 280,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFFDD000) : Colors.grey[300]!,
              width: isSelected ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovered ? 0.15 : 0.1),
                blurRadius: isHovered ? 12 : 8,
                offset: Offset(0, isHovered ? 6 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.35,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.zero,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ColorFiltered(
                          key: ValueKey(showColorful),
                          colorFilter: showColorful
                              ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          )
                              : const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ]),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 2,
                width: double.infinity,
                color: Colors.grey[300],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String difficulty, Color color) {
    final isSelected = selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () async {
        try {
          await FlameAudio.play('click1.wav');
        } catch (e) {
          debugPrint('Click sound not found: $e');
        }
        setState(() => selectedDifficulty = difficulty);
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          difficulty.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}