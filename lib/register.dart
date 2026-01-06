import 'package:flutter/material.dart';
import 'login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flame_audio/flame_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Starbooks Quiz',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  final Function(String username, String password)? onRegister;

  const RegisterPage({super.key, this.onRegister});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  int step = 0;
  String? selectedAvatar;

  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScale;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();
  final TextEditingController schoolController = TextEditingController();

  String? selectedAge;
  String? selectedCategory;
  String? selectedSex;

  String? selectedRegionId;
  String? selectedRegionName;
  String? selectedProvinceId;
  String? selectedProvinceName;
  String? selectedCityId;
  String? selectedCityName;

  // Password validation according to SS-007
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }



// Username validation
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.trim().length > 20) {
      return 'Username must not exceed 20 characters';
    }
    // Only alphanumeric and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateSchool(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'School is required';
    }
    if (value.trim().length < 2) {
      return 'School name must be at least 2 characters';
    }
    return null;
  }

  List<Map<String, String>> regions = [];
  List<Map<String, String>> provinces = [];
  List<Map<String, String>> cities = [];

  static const String baseUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();

    // Button scale animation
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

    // Fade animation for form fields
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    fetchRegions();
    _fadeController.forward(); // Start fade animation
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    schoolController.dispose();
    _buttonScaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _playClickSound() async {
    try {
      await FlameAudio.play('click1.wav');
    } catch (e) {
      debugPrint('Button click sound not found: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> fetchRegions() async {
    try {
      final url = Uri.parse('$baseUrl/api/region');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final parsed = <Map<String, String>>[];
        for (var e in data) {
          final id = (e['id'] ?? e['_id'] ?? '').toString();
          final name = (e['region_name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({'id': id, 'name': name});
          }
        }
        setState(() {
          regions = parsed;
        });
      } else {
        _showError('Failed to load regions');
      }
    } catch (e) {
      debugPrint('fetchRegions error: $e');
      _showError('Network error loading regions');
    }
  }

  Future<void> fetchProvinces(String regionId) async {
    setState(() {
      provinces = [];
      selectedProvinceId = null;
      selectedProvinceName = null;
      cities = [];
      selectedCityId = null;
      selectedCityName = null;
    });
    try {
      final url = Uri.parse('$baseUrl/api/province/$regionId');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final parsed = <Map<String, String>>[];
        for (var e in data) {
          final id = (e['id'] ?? e['_id'] ?? '').toString();
          final name = (e['province_name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({'id': id, 'name': name});
          }
        }
        setState(() => provinces = parsed);
      }
    } catch (e) {
      debugPrint('fetchProvinces error: $e');
    }
  }

  Future<void> fetchCities(String provinceId) async {
    setState(() {
      cities = [];
      selectedCityId = null;
      selectedCityName = null;
    });
    try {
      final url = Uri.parse('$baseUrl/api/city/$provinceId');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final parsed = <Map<String, String>>[];
        for (var e in data) {
          final id = (e['id'] ?? e['_id'] ?? '').toString();
          final name = (e['city_name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            parsed.add({'id': id, 'name': name});
          }
        }
        setState(() => cities = parsed);
      }
    } catch (e) {
      debugPrint('fetchCities error: $e');
    }
  }

  Future<void> registerUser() async {
    _playClickSound();
    await _buttonScaleController.forward();
    await _buttonScaleController.reverse();

    List<String> missingFields = [];

    if (usernameController.text.trim().isEmpty) {
      missingFields.add('Username');
    }
    if (passwordController.text.isEmpty) {
      missingFields.add('Password');
    }
    if (confirmPasswordController.text.isEmpty) {
      missingFields.add('Confirm Password');
    }
    if (schoolController.text.trim().isEmpty) {
      missingFields.add('School');
    }
    if (selectedAge == null) {
      missingFields.add('Age range');  // Changed from 'Age' to 'Age range'
    }
    if (selectedCategory == null) {
      missingFields.add('Category');
    }
    if (selectedSex == null) {
      missingFields.add('Sex');
    }
    if (selectedAvatar == null) {
      missingFields.add('Avatar');
    }
    if (selectedRegionId == null) {
      missingFields.add('Region');
    }
    if (selectedProvinceId == null) {
      missingFields.add('Province');
    }
    if (selectedCityId == null) {
      missingFields.add('City');
    }

    // If multiple fields are missing, show general message
    if (missingFields.length > 2) {
      _showError('Please fill in all required fields');
      return;
    }

    // If 1-2 fields missing, show specific message
    if (missingFields.isNotEmpty) {
      // Special handling for age range message
      if (missingFields.length == 1 && missingFields[0] == 'Age range') {
        _showError('Please select an age range');
      } else if (missingFields.length == 2 && missingFields.contains('Age range')) {
        // If age range is one of two missing fields, use better grammar
        String otherField = missingFields.firstWhere((f) => f != 'Age range');
        _showError('$otherField and Age range are required');
      } else {
        // Standard message for other combinations
        _showError('${missingFields.join(' and ')} ${missingFields.length == 1 ? 'is' : 'are'} required');
      }
      return;
    }

    // Validate username format
    String? usernameError = _validateUsername(usernameController.text);
    if (usernameError != null) {
      _showError(usernameError);
      return;
    }

    // Validate password format
    String? passwordError = _validatePassword(passwordController.text);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    // Validate password match
    if (passwordController.text != confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    // Validate school
    String? schoolError = _validateSchool(schoolController.text);
    if (schoolError != null) {
      _showError(schoolError);
      return;
    }

    // All validations passed, proceed with registration
    final payload = {
      "username": usernameController.text.trim(),
      "password": passwordController.text,
      "school": schoolController.text.trim(),
      "age": selectedAge ?? "",
      "avatar": selectedAvatar ?? "",
      "category": selectedCategory ?? "",
      "sex": selectedSex ?? "",
      "region": selectedRegionId,
      "province": selectedProvinceId,
      "city": selectedCityId,
    };

    final url = Uri.parse('$baseUrl/api/user/register');
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        if (!mounted) return;

        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Registration Successful!",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xDD000000),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Welcome, ${usernameController.text.trim()}!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your account has been created successfully. You can now log in to start playing!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xCF000000),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Replace the existing ElevatedButton in your success dialog with this:

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _playClickSound(); // Add this line
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (c) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Go to Login",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      } else {
        // Handle server errors
        String message = 'Registration failed';
        try {
          final jsonBody = jsonDecode(resp.body);
          if (jsonBody is Map) {
            // Handle Laravel validation errors
            if (jsonBody['errors'] != null) {
              final errors = jsonBody['errors'] as Map<String, dynamic>;
              final firstError = errors.values.first;
              message = firstError is List ? firstError.first : firstError.toString();
            } else if (jsonBody['message'] != null) {
              message = jsonBody['message'];
            }
          }
        } catch (_) {
          message = resp.body;
        }
        if (!mounted) return;
        _showError(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Network error. Please check your connection.');
    }
  }

  Widget _regionDropdown() =>
      _buildDropdown("Region", regions, selectedRegionId, (v) {
        setState(() {
          selectedRegionId = v;
          selectedRegionName = regions.firstWhere((r) => r['id'] == v)['name'];
          selectedProvinceId = null;
          selectedProvinceName = null;
          cities = [];
          selectedCityId = null;
          selectedCityName = null;
        });
        if (v != null) fetchProvinces(v);
      });

  Widget _provinceDropdown() =>
      _buildDropdown("Province", provinces, selectedProvinceId, (v) {
        setState(() {
          selectedProvinceId = v;
          selectedProvinceName = provinces.firstWhere(
                (p) => p['id'] == v,
          )['name'];
          selectedCityId = null;
          selectedCityName = null;
        });
        if (v != null) fetchCities(v);
      });

  Widget _cityDropdown() => _buildDropdown("City", cities, selectedCityId, (v) {
    setState(() {
      selectedCityId = v;
      selectedCityName = cities.firstWhere((c) => c['id'] == v)['name'];
    });
  });

  Widget _buildDropdown(
      String label,
      List<Map<String, String>> items,
      String? value,
      void Function(String?)? onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: _inputDecoration(label),
        initialValue: value,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
        ),
        items: items.map((e) {
          return DropdownMenuItem(
            value: e['id'],
            child: Text(
              e['name'] ?? e['id'] ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (step > 0) {
      setState(() {
        step--;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildStepper() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStepCircle(0),
            Expanded(
              child: Container(
                height: 2,
                color: step >= 1
                    ? const Color(0xFF046EB8)
                    : Colors.grey.shade400,
              ),
            ),
            _buildStepCircle(1),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Privacy Notice",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              "Account Setup",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepIndex) {
    final bool isCompleted = step > stepIndex;
    final bool isActive = step == stepIndex;

    final Color circleColor = (isActive || isCompleted)
        ? const Color(0xFF046EB8)
        : Colors.grey.shade400;

    return CircleAvatar(radius: 8, backgroundColor: circleColor);
  }

  Widget _buildOutlinedButton(
      String label,
      VoidCallback onPressed, {
        bool isProceed = false,
      }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF046EB8).withAlpha(50);
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          return const Color(0xFF046EB8);
        }),
      ),
      onPressed: () {
        _playClickSound();
        onPressed();
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.normal)),
    );
  }

  Widget _buildPrivacyStepButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildOutlinedButton("Back", () => _handleBack(context)),
        _buildOutlinedButton("Proceed", () {
          _fadeController.reset();
          setState(() {
            step = 1;
          });
          _fadeController.forward();
        }, isProceed: true),
      ],
    );
  }

  Widget _buildAccountSetupStepButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildOutlinedButton("Back", () => _handleBack(context)),
        Transform.scale(
          scale: _buttonScale.value,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDD000),
              foregroundColor: const Color(0xFFAC8337),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            onPressed: registerUser,
            child: const Text(
              "REGISTER",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return AnimatedBuilder(
        animation: Listenable.merge([_buttonScaleController, _fadeController]),
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
                      "assets/images-logo/starbooksnewlogo.png", height: 50),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminPage()),
                      );
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.person, color: Color(0xFF046EB8)),
                        SizedBox(width: 5),
                        Text(
                          "ADMIN",
                          style: TextStyle(
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
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: 900, minWidth: 400),
                    child: Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.9,
                      height: step == 0 ? 420 : 520,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildStepper(),
                          const SizedBox(height: 20),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                              child: SingleChildScrollView(
                                key: ValueKey(step),
                                // IMPORTANT for the animation to trigger
                                child: step == 0
                                    ? _buildPrivacyStepContent()
                                    : _buildAccountSetupStepContent(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          step == 0
                              ? _buildPrivacyStepButtons(context)
                              : _buildAccountSetupStepButtons(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }
  Widget _buildPrivacyStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Register",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF046EB8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
        child: Image.asset("assets/images-logo/bird1.png", height: 140),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            "Terms and Conditions",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "By accessing STARBOOKS WHIZ CHALLENGE, you agree to these terms and conditions. "
              "We collect personal information and usage data to improve our services and efficiency. "
              "We prioritize data security and do not share personal information with third parties without consent, "
              "except as required by law. Users must provide accurate information and comply with all laws while using our site. "
              "For questions, contact us at support@starbookswhizbee.com",
          style: TextStyle(fontSize: 14),  textAlign: TextAlign.justify,
        ),
      ],
    );
  }

    Widget _buildAccountSetupStepContent() {
      return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
        const Text(
          "Register",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF046EB8),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: CircleAvatar(
                radius: 80,
                backgroundColor: const Color(0xFFFDD000),
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.white,
                  backgroundImage: selectedAvatar != null
                      ? AssetImage(selectedAvatar!)
                      : null,
                  child: selectedAvatar == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTextField(
                    Icons.person,
                    "Username",
                    controller: usernameController,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPasswordField(
                          Icons.lock,
                          "Password",
                          hidePassword,
                              (val) => setState(() => hidePassword = !hidePassword),
                          passwordController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPasswordField(
                          Icons.lock,
                          "Confirm Password",
                          hideConfirmPassword,
                              (val) => setState(
                                () => hideConfirmPassword = !hideConfirmPassword,
                          ),
                          confirmPasswordController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          Icons.school,
                          "School",
                          controller: schoolController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAgeDropdown(
                          "Age",
                          onChanged: (v) => setState(() => selectedAge = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildAvatarDropdown(
                "Avatar",
                icon: Icons.camera_alt,
                onChanged: (value) {
                  setState(() {
                    selectedAvatar = "$value";
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryDropdown(
                "Category",
                onChanged: (v) => setState(() => selectedCategory = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSexDropdown(
                "Sex",
                onChanged: (v) => setState(() => selectedSex = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _regionDropdown()),
            const SizedBox(width: 10),
            Expanded(child: _provinceDropdown()),
            const SizedBox(width: 10),
            Expanded(child: _cityDropdown()),
          ],
        ),
      ],
    ));
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF046EB8), width: 2),
      ),
    );
  }

  Widget _buildTextField(
      IconData icon,
      String hint, {
        bool isPassword = false,
        TextEditingController? controller,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon),
      ),
    );
  }

  Widget _buildPasswordField(
      IconData icon,
      String hint,
      bool hide,
      void Function(bool) toggle,
      TextEditingController controller,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: hide,
        style: const TextStyle(fontSize: 12, fontFamily: "Poppins"),
        decoration: _inputDecoration(hint, icon: icon).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              hide ? Icons.visibility : Icons.visibility_off,
              size: 18,
            ),
            onPressed: () => toggle(!hide),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarDropdown(
      String label, {
        IconData? icon,
        void Function(String?)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        initialValue: selectedAvatar?.split('/').last.split('.').first,
        items: const [
          DropdownMenuItem(value: "Adventurer", child: Text("Adventurer")),
          DropdownMenuItem(value: "Astronaut", child: Text("Astronaut")),
          DropdownMenuItem(value: "Boy", child: Text("Boy")),
          DropdownMenuItem(value: "Brainy", child: Text("Brainy")),
          DropdownMenuItem(value: "Cool-Monkey", child: Text("Cool-Monkey")),
          DropdownMenuItem(
            value: "Cute-Elephant",
            child: Text("Cute-Elephant"),
          ),
          DropdownMenuItem(value: "Doctor-Boy", child: Text("Doctor-Boy")),
          DropdownMenuItem(value: "Doctor-Girl", child: Text("Doctor-Girl")),
          DropdownMenuItem(value: "Engineer-Boy", child: Text("Engineer-Boy")),
          DropdownMenuItem(
            value: "Engineer-Girl",
            child: Text("Engineer-Girl"),
          ),
          DropdownMenuItem(value: "Girl", child: Text("Girl")),
          DropdownMenuItem(value: "Hacker", child: Text("Hacker")),
          DropdownMenuItem(value: "Leonel", child: Text("Leonel")),
          DropdownMenuItem(
            value: "Scientist-Boy",
            child: Text("Scientist-Boy"),
          ),
          DropdownMenuItem(
            value: "Scientist-Girl",
            child: Text("Scientist-Girl"),
          ),
          DropdownMenuItem(value: "Sly-Fox", child: Text("Sly-Fox")),
          DropdownMenuItem(value: "Sneaky-Snake", child: Text("Sneaky-Snake")),
          DropdownMenuItem(value: "Teacher-Boy", child: Text("Teacher-Boy")),
          DropdownMenuItem(value: "Teacher-Girl", child: Text("Teacher-Girl")),
          DropdownMenuItem(value: "Twirky", child: Text("Twirky")),
          DropdownMenuItem(
            value: "Whiz-Achiever",
            child: Text("Whiz-Achiever"),
          ),
          DropdownMenuItem(value: "Whiz-Busy", child: Text("Whiz-Busy")),
          DropdownMenuItem(value: "Whiz-Happy", child: Text("Whiz-Happy")),
          DropdownMenuItem(value: "Whiz-Ready", child: Text("Whiz-Ready")),
          DropdownMenuItem(value: "Wise-Turtle", child: Text("Wise-Turtle")),
        ],
        onChanged: (value) {
          setState(() {
            switch (value) {
              case "Adventurer":
                selectedAvatar = "assets/images-avatars/Adventurer.png";
                break;
              case "Astronaut":
                selectedAvatar = "assets/images-avatars/Astronaut.png";
                break;
              case "Boy":
                selectedAvatar = "assets/images-avatars/Boy.png";
                break;
              case "Brainy":
                selectedAvatar = "assets/images-avatars/Brainy.png";
                break;
              case "Cool-Monkey":
                selectedAvatar = "assets/images-avatars/Cool-Monkey.png";
                break;
              case "Cute-Elephant":
                selectedAvatar = "assets/images-avatars/Cute-Elephant.png";
                break;
              case "Doctor-Boy":
                selectedAvatar = "assets/images-avatars/Doctor-Boy.png";
                break;
              case "Doctor-Girl":
                selectedAvatar = "assets/images-avatars/Doctor-Girl.png";
                break;
              case "Engineer-Boy":
                selectedAvatar = "assets/images-avatars/Engineer-Boy.png";
                break;
              case "Engineer-Girl":
                selectedAvatar = "assets/images-avatars/Engineer-Girl.png";
                break;
              case "Girl":
                selectedAvatar = "assets/images-avatars/Girl.png";
                break;
              case "Hacker":
                selectedAvatar = "assets/images-avatars/Hacker.png";
                break;
              case "Leonel":
                selectedAvatar = "assets/images-avatars/Leonel.png";
                break;
              case "Scientist-Boy":
                selectedAvatar = "assets/images-avatars/Scientist-Boy.png";
                break;
              case "Scientist-Girl":
                selectedAvatar = "assets/images-avatars/Scientist-Girl.png";
                break;
              case "Sly-Fox":
                selectedAvatar = "assets/images-avatars/Sly-Fox.png";
                break;
              case "Sneaky-Snake":
                selectedAvatar = "assets/images-avatars/Sneaky-Snake.png";
                break;
              case "Teacher-Boy":
                selectedAvatar = "assets/images-avatars/Teacher-Boy.png";
                break;
              case "Teacher-Girl":
                selectedAvatar = "assets/images-avatars/Teacher-Girl.png";
                break;
              case "Twirky":
                selectedAvatar = "assets/images-avatars/Twirky.png";
                break;
              case "Whiz-Achiever":
                selectedAvatar = "assets/images-avatars/Whiz-Achiever.png";
                break;
              case "Whiz-Busy":
                selectedAvatar = "assets/images-avatars/Whiz-Busy.png";
                break;
              case "Whiz-Happy":
                selectedAvatar = "assets/images-avatars/Whiz-Happy.png";
                break;
              case "Whiz-Ready":
                selectedAvatar = "assets/images-avatars/Whiz-Ready.png";
                break;
              case "Wise-Turtle":
                selectedAvatar = "assets/images-avatars/Wise-Turtle.png";
                break;
            }
          });
        },
      ),
    );
  }

  Widget _buildAgeDropdown(
      String label, {
        IconData? icon,
        void Function(String?)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          DropdownMenuItem(
            value: "0-12",
            child: Text("0-12", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "13-17",
            child: Text("13-17", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "18-22",
            child: Text("18-22", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "23-29",
            child: Text("23-29", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "30-39",
            child: Text("30-39", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "40+",
            child: Text("40+", style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCategoryDropdown(
      String label, {
        IconData? icon,
        void Function(String?)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          DropdownMenuItem(
            value: "Student",
            child: Text("Student", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Government Employee",
            child: Text("Government Employee", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Private Employee",
            child: Text("Private Employee", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Self-Employed",
            child: Text("Self-Employed", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Not Employed",
            child: Text("Not Employed", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Others",
            child: Text("Others", style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSexDropdown(
      String label, {
        IconData? icon,
        void Function(String?)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(label, icon: icon),
        style: const TextStyle(
          fontSize: 12,
          fontFamily: "Poppins",
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          DropdownMenuItem(
            value: "Male",
            child: Text("Male", style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: "Female",
            child: Text("Female", style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: onChanged,
      ),
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


