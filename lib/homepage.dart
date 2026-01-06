import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'login.dart';
import 'edit_profile.dart';
import 'player_badges.dart';
import 'whiz_battle.dart';
import 'whiz_challenge.dart';
import 'whiz_puzzle.dart';
import 'whiz_memory_match.dart';
import 'leaderboard.dart';
import 'package:flame_audio/flame_audio.dart';

// ✅ USER PROFILE MODEL
class UserProfile {
  String id;
  String username;
  String school;
  String age;
  String category;
  String sex;
  String region;
  String province;
  String city;
  String avatar;
  int stars; // ← ADD THIS LINE

  UserProfile({
    required this.id,
    required this.username,
    required this.school,
    required this.age,
    required this.category,
    required this.sex,
    required this.region,
    required this.province,
    required this.city,
    required this.avatar,
    this.stars = 0, // ← ADD THIS LINE
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var idValue = json['id'] ?? json['_id'] ?? '';
    if (idValue is Map && idValue.containsKey('\$oid')) {
      idValue = idValue['\$oid'];
    }

    return UserProfile(
      id: idValue.toString(),
      username: json['username'] ?? '',
      school: json['school'] ?? '',
      age: json['age']?.toString() ?? '',
      category: json['category'] ?? '',
      sex: json['sex'] ?? '',
      region: json['region']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      avatar: json['avatar'] ?? "assets/images-avatars/Adventurer.png",
      stars: json['stars'] ?? 0, // ← ADD THIS LINE
    );
  }

  UserProfile copyWith({
    String? username,
    String? school,
    String? age,
    String? category,
    String? sex,
    String? region,
    String? province,
    String? city,
    String? avatar,
    int? stars, // ← ADD THIS LINE
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      school: school ?? this.school,
      age: age ?? this.age,
      category: category ?? this.category,
      sex: sex ?? this.sex,
      region: region ?? this.region,
      province: province ?? this.province,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
      stars: stars ?? this.stars, // ← ADD THIS LINE
    );
  }
}

// ✅ HOME PAGE
class HomePage extends StatefulWidget {
  final UserProfile profile;
  final String initialTab;

  const HomePage({super.key, required this.profile, this.initialTab = "Home"});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late UserProfile _currentProfile;
  late String _selectedTab;
  bool _loadingProfile = true;
  final String baseUrl = "http://localhost:8000";

  late AnimationController _flashController;
  bool _isFlashing = false;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _selectedTab = widget.initialTab;
    _loadUserWithLocationNames();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _loadUserWithLocationNames() async {
    setState(() => _loadingProfile = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/homepage/${_currentProfile.id}"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          setState(() {
            _currentProfile = _currentProfile.copyWith(
              region: user['region'] ?? '',
              province: user['province'] ?? '',
              city: user['city'] ?? '',
              stars: user['stars'] ?? 0, // ← ADD THIS LINE
            );
            _loadingProfile = false;
          });
        }
      } else {
        setState(() => _loadingProfile = false);
      }
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }

  String get regionName => _currentProfile.region.isNotEmpty ? _currentProfile.region : "Unknown Region";
  String get provinceName => _currentProfile.province.isNotEmpty ? _currentProfile.province : "Unknown Province";
  String get cityName => _currentProfile.city.isNotEmpty ? _currentProfile.city : "Unknown City";

  Future<void> _editProfile() async {
    final updatedProfile = await showDialog<UserProfile>(
      context: context,
      builder: (_) => EditProfileDialog(profile: _currentProfile),
    );
    if (updatedProfile != null && mounted) {
      setState(() => _currentProfile = updatedProfile);
    }
  }

  Future<void> _logoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent closing by clicking outside
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images-icons/sadlogout.png",
                width: 80,
                height: 80,
              ),
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
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
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
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Call logout API
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _currentProfile.id}),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && mounted) {
          // Show success message
          await _showLogoutSuccessDialog(data['message']);

          // Navigate to login screen
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false, // Remove all previous routes
            );
          }
        } else {
          // Handle unsuccessful logout
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Logout failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Handle error response
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error during logout. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLogoutSuccessDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF046EB8),
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Logged Out",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF046EB8),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD000),
                    foregroundColor: const Color(0xFF816A03),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopNavButton(String label, IconData icon) {
    final isActive = _selectedTab == label;
    return InkWell(
      onTap: () async {
        try {
          await FlameAudio.play('click1.wav');
        } catch (e) {
          debugPrint('Click sound not found: $e');
        }
        setState(() => _selectedTab = label);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: isActive ? const Color(0xFFFFD13B) : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFFD13B) : Colors.black,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                )),
          ]),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isActive ? 70 : 0,
            color: isActive ? const Color(0xFFFFD13B) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Future<void> _triggerFlashAndNavigate(Widget page) async {
    if (_isFlashing) return;
    setState(() => _isFlashing = true);

    await _flashController.forward();

    if (mounted) {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => page,
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      // Reload profile data when returning from game
      if (mounted) {
        await _loadUserWithLocationNames();
      }
    }

    if (mounted) {
      await _flashController.reverse();
      setState(() => _isFlashing = false);
    }
  }

  Color _getStarColor() {
    if (_currentProfile.stars >= 1000) return const Color(0xFFB9F2FF); // Diamond (light blue)
    if (_currentProfile.stars >= 500) return const Color(0xFFE5E4E2); // Platinum (silver-white)
    if (_currentProfile.stars >= 250) return const Color(0xFFFFD700); // Gold
    if (_currentProfile.stars >= 100) return const Color(0xFFC0C0C0); // Silver
    if (_currentProfile.stars >= 50) return const Color(0xFFCD7F32); // Bronze
    return Colors.white; // Default white
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = _selectedTab == "Leaderboard"
        ? Leaderboard(
      currentUserId: _currentProfile.id,
      userAvatar: _currentProfile.avatar,
      username: _currentProfile.username,
    )
        : _buildHomeContent();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF046EB8),
          body: _loadingProfile
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(children: [
            _buildTopBar(),
            Expanded(child: mainContent),
          ]),
        ),
        AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: _flashController.value,
                child: Container(color: Colors.white),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Image.asset("assets/images-logo/starbooksmainlogo.png", width: 150, height: 50, fit: BoxFit.contain),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _buildTopNavButton("Home", Icons.home),
                const SizedBox(width: 40),
                _buildTopNavButton("Leaderboard", Icons.leaderboard),
              ]),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _logoutDialog,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, border: Border.all(color: const Color(0xFF046EB8), width: 3)),
                child: ClipOval(child: Image.asset(_currentProfile.avatar, fit: BoxFit.cover)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      height: 90,
      width: 850, // Made longer
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90BE),
        borderRadius: BorderRadius.circular(12), // Less rounded
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
            ),
            child: ClipOval(child: Image.asset(_currentProfile.avatar, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentProfile.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            await FlameAudio.play('click1.wav');
                          } catch (e) {
                            debugPrint('Click sound not found: $e');
                          }
                          _editProfile();
                        },
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Color(0xFF046EB8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentProfile.category,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  "$cityName, ${_currentProfile.region}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: _getStarColor(), size: 24),
                const SizedBox(width: 6),
                Text(
                  '${_currentProfile.stars}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                try {
                  await FlameAudio.play('click1.wav');
                } catch (e) {
                  debugPrint('Click sound not found: $e');
                }
                showDialog(
                  context: context,
                  builder: (_) => PlayerBadgesDialog(playerId: _currentProfile.id),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD000),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDD000), width: 2),
                ),
                child: const Text(
                  'Your Badges',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB8860B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Align(alignment: Alignment.topCenter, child: _buildProfileCard()),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 180, left: 70, right: 70), // ← CHANGED from 200 to 180
            child: LayoutBuilder(builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 800 ? 2 : 4;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.symmetric(vertical: 20),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.73,
                children: [
                  _GameBox(
                    title: "Whiz Memory Match",
                    imagePath: "assets/images-logo/whizmemorymatch.png",
                    backgroundColor: const Color(0xFF656BE6),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizMemoryMatch(
                        userAvatar: _currentProfile.avatar,
                        playerId: _currentProfile.id,
                        username: _currentProfile.username,
                      ),
                    ),
                  ),
                  _GameBox(
                    title: "Whiz Challenge",
                    imagePath: "assets/images-logo/whizchallenge.png",
                    backgroundColor: const Color(0xFFFDD000),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizChallenge(
                        userAvatar: _currentProfile.avatar,
                        userId: _currentProfile.id,
                        username: _currentProfile.username,
                      ),
                    ),
                  ),
                  _GameBox(
                    title: "Whiz Battle",
                    imagePath: "assets/images-logo/whizbattle.png",
                    backgroundColor: const Color(0xFFC571E2),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizBattle(
                        userAvatar: _currentProfile.avatar,
                        userId: _currentProfile.id,
                        username: _currentProfile.username,
                      ),
                    ),
                  ),
                  _GameBox(
                    title: "Whiz Puzzle",
                    imagePath: "assets/images-logo/whizpuzzle.png",
                    backgroundColor: const Color(0xFFE6833A),
                    onTapNavigate: () => _triggerFlashAndNavigate(
                      WhizPuzzle(
                        userAvatar: _currentProfile.avatar,
                        playerId: _currentProfile.id,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ✅ GameBox with upward hover, smooth return, fade, and bounce when hover ends
class _GameBox extends StatefulWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTapNavigate;

  const _GameBox({
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTapNavigate,
  });

  @override
  State<_GameBox> createState() => _GameBoxState();
}

class _GameBoxState extends State<_GameBox> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _floatController;
  late AnimationController _fadeOutController;
  late AnimationController _bounceController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _liftAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  bool _hovering = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );

    _liftAnimation = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );

    _shadowAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _floatController.dispose();
    _fadeOutController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent details) {
    setState(() => _hovering = true);
    _bounceController.reset();
    _hoverController.forward();
    _floatController.repeat(reverse: true);
  }

  void _onExit(PointerEvent details) async {
    setState(() => _hovering = false);

    _floatController.stop();
    _floatController.reset();

    await _hoverController.reverse();

    _bounceController.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    _bounceController.reverse();
  }

  Future<void> _onTap() async {
    try {
      await FlameAudio.play('click1.wav');
    } catch (e) {
      debugPrint('Click sound not found: $e');
    }

    _floatController.stop();
    setState(() => _hovering = false);

    _hoverController.duration = const Duration(milliseconds: 150);
    await _hoverController.reverse();

    await _fadeOutController.forward();

    widget.onTapNavigate();

    if (mounted) {
      _fadeOutController.reset();
      _hoverController.duration = const Duration(milliseconds: 800);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverController,
            _floatController,
            _fadeOutController,
            _bounceController
          ]),
          builder: (context, child) {
            final floatOffset = _hovering ? sin(_floatController.value * 2 * pi) * 8 : 0;
            final totalOffset = _liftAnimation.value + floatOffset + _bounceAnimation.value;

            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, totalOffset),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (_hovering)
                      Container(
                        width: 320,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withValues(alpha: 0.4 * _glowAnimation.value),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: -30,
                      child: Container(
                        width: 180 * _shadowAnimation.value,
                        height: 35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_hovering ? _rotationAnimation.value : 0),
                      child: Container(
                        width: 280,
                        height: 360,
                        decoration: BoxDecoration(
                          color: widget.backgroundColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: widget.backgroundColor.withValues(alpha: 0.7),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: widget.backgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

