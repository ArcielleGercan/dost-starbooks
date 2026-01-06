import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flame_audio/flame_audio.dart';
import 'register.dart';
import 'homepage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String baseUrl = 'http://localhost:8000';

  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    // Button scale animation for press effect
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  void _playClickSound() async {
    try {
      await FlameAudio.play('click1.wav');
    } catch (e) {
      debugPrint('Button click sound not found: $e');
    }
  }

  Future<void> _login() async {
    _playClickSound(); // Play sound when login button is pressed

    // Animate button press
    await _buttonScaleController.forward();
    await _buttonScaleController.reverse();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // TC_005: Empty username validation
    if (username.isEmpty && password.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TC_006: Empty password validation
    if (password.isEmpty && username.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TC_007: Both fields empty
    if (username.isEmpty && password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TC_008: Username too short
    if (username.length < 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username must be at least 3 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TC_009: Username too long
    if (username.length > 20) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username exceeds maximum length'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              profile: UserProfile(
                id: data['user']['id']?.toString() ??
                    data['user']['_id']?.toString() ??
                    '',
                username: data['user']['username'],
                school: data['user']['school'] ?? 'Unknown School',
                age: data['user']['age']?.toString() ?? 'N/A',
                category: data['user']['category'] ?? 'Student',
                sex: data['user']['sex'] ?? 'N/A',
                region: data['user']['region']?.toString() ?? '',
                province: data['user']['province']?.toString() ?? '',
                city: data['user']['city']?.toString() ?? '',
                avatar: data['user']['avatar'] ?? 'default',
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Invalid username or password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToRegister() {
    _playClickSound(); // Play sound when register link is clicked
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _buttonScaleController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF94D2FD),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  "assets/images-logo/starbooksnewlogo.png",
                  height: 50,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
                InkWell(
                  onTap: () {
                    _playClickSound();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminPage()),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: Color(0xFF046EB8)),
                      SizedBox(width: 5),
                      Text(
                        "ADMIN",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF046EB8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              Image.asset(
                "assets/images-icons/background1.png",
                width: screenWidth,
                height: screenHeight,
                fit: BoxFit.cover,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/images-logo/starbookslogin.png",
                          height: 170,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: 380,
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Log In",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF046EB8),
                                ),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: _usernameController,
                                onSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: "Username",
                                  labelStyle: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                  ),
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF046EB8),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              TextField(
                                controller: _passwordController,
                                onSubmitted: (_) => _login(),
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                  ),
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF046EB8),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              Transform.scale(
                                scale: _buttonScale.value,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFDD000),
                                      foregroundColor: const Color(0xFF816A03),
                                      textStyle: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    child: const Text("LOG IN"),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "No account yet? ",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _goToRegister,
                                    child: const Text(
                                      "Register here",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: const Center(
        child: Text("This is the Admin Page (to be implemented)."),
      ),
    );
  }
}