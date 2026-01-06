import 'package:flutter/material.dart';
import 'package:flutter_projects/change_password.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'audio_service.dart';
import 'homepage.dart'; // contains UserProfile class

class EditProfileDialog extends StatefulWidget {
  final UserProfile profile;

  const EditProfileDialog({super.key, required this.profile});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final String baseUrl = "http://localhost:8000";
  final _formKey = GlobalKey<FormState>();

  late TextEditingController usernameController;
  late TextEditingController schoolController;

  String? selectedAvatar;
  String? selectedAge;
  String? selectedCategory;
  String? selectedSex;
  String? selectedRegionId;
  String? selectedProvinceId;
  String? selectedCityId;


  List<Map<String, String>> regions = [];
  List<Map<String, String>> provinces = [];
  List<Map<String, String>> cities = [];

  bool saving = false;
  bool showSuccess = false;
  double successOpacity = 1.0;

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    // Check for spaces
    if (value.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.trim().length > 20) {
      return 'Username must not exceed 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
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

  final List<String> avatarPaths = [
    "assets/images-avatars/Adventurer.png",
    "assets/images-avatars/Astronaut.png",
    "assets/images-avatars/Boy.png",
    "assets/images-avatars/Brainy.png",
    "assets/images-avatars/Cool-Monkey.png",
    "assets/images-avatars/Cute-Elephant.png",
    "assets/images-avatars/Doctor-Boy.png",
    "assets/images-avatars/Doctor-Girl.png",
    "assets/images-avatars/Engineer-Boy.png",
    "assets/images-avatars/Engineer-Girl.png",
    "assets/images-avatars/Girl.png",
    "assets/images-avatars/Hacker.png",
    "assets/images-avatars/Leonel.png",
    "assets/images-avatars/Scientist-Boy.png",
    "assets/images-avatars/Scientist-Girl.png",
    "assets/images-avatars/Sly-Fox.png",
    "assets/images-avatars/Sneaky-Snake.png",
    "assets/images-avatars/Teacher-Boy.png",
    "assets/images-avatars/Teacher-Girl.png",
    "assets/images-avatars/Twirky.png",
    "assets/images-avatars/Whiz-Achiever.png",
    "assets/images-avatars/Whiz-Busy.png",
    "assets/images-avatars/Whiz-Happy.png",
    "assets/images-avatars/Whiz-Ready.png",
    "assets/images-avatars/Wise-Turtle.png",
  ];

  late final List<String> avatarNames = avatarPaths
      .map(
        (path) =>
        path.split('/').last.replaceAll('.png', '').replaceAll('-', ' '),
  )
      .toList();

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController(text: widget.profile.username);
    schoolController = TextEditingController(text: widget.profile.school);

    selectedAvatar = widget.profile.avatar;
    selectedAge = widget.profile.age;
    selectedCategory = widget.profile.category;
    selectedSex = widget.profile.sex;

    fetchRegions().then((_) {
      selectedRegionId = regions.firstWhere(
            (r) => r['name'] == widget.profile.region,
        orElse: () => {'id': ''},
      )['id'];

      if (selectedRegionId != '') {
        fetchProvinces(selectedRegionId!).then((_) {
          selectedProvinceId = provinces.firstWhere(
                (p) => p['name'] == widget.profile.province,
            orElse: () => {'id': ''},
          )['id'];

          if (selectedProvinceId != '') {
            fetchCities(selectedProvinceId!).then((_) {
              selectedCityId = cities.firstWhere(
                    (c) => c['name'] == widget.profile.city,
                orElse: () => {'id': ''},
              )['id'];
              setState(() {});
            });
          } else {
            setState(() {});
          }
        });
      } else {
        setState(() {});
      }
    });
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, fontFamily: "Poppins"),
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
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> fetchRegions() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/api/region'));
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        regions = data
            .map<Map<String, String>>(
              (e) => {
            'id': e['id'].toString(),
            'name': (e['region_name'] ?? e['name']).toString(),
          },
        )
            .toList();
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> fetchProvinces(String regionId) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/api/province/$regionId'));
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        provinces = data
            .map<Map<String, String>>(
              (e) => {
            'id': e['id'].toString(),
            'name': (e['province_name'] ?? e['name']).toString(),
          },
        )
            .toList();
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> fetchCities(String provinceId) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/api/city/$provinceId'));
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        cities = data
            .map<Map<String, String>>(
              (e) => {
            'id': e['id'].toString(),
            'name': (e['city_name'] ?? e['name']).toString(),
          },
        )
            .toList();
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> saveProfile() async {
    // Validate username
    String? usernameError = _validateUsername(usernameController.text);
    if (usernameError != null) {
      _showError(usernameError);
      return;
    }

    // Validate school
    if (schoolController.text.trim().isEmpty) {
      _showError('School is required');
      return;
    }
    if (schoolController.text.trim().length < 2) {
      _showError('School name must be at least 2 characters');
      return;
    }

    // Validate required selections
    if (selectedAge == null) {
      _showError('Please select an age range');
      return;
    }

    if (selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    if (selectedSex == null) {
      _showError('Please select your sex');
      return;
    }

    if (selectedAvatar == null) {
      _showError('Please select an avatar');
      return;
    }

    // Validate location
    if (selectedRegionId == null || selectedProvinceId == null || selectedCityId == null) {
      _showError('Please select Region, Province, and City');
      return;
    }

    setState(() => saving = true);

    try {
      final resp = await http.put(
        Uri.parse('$baseUrl/api/user/update/${widget.profile.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text.trim(),
          'school': schoolController.text.trim(),
          'age': selectedAge,
          'category': selectedCategory,
          'sex': selectedSex,
          'avatar': selectedAvatar,
          'region': selectedRegionId,
          'province': selectedProvinceId,
          'city': selectedCityId,
        }),
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200 && data['success'] == true) {
        // Check if no changes were made
        if (data['no_changes'] == true) {
          setState(() => saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No changes were made'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final updatedProfile = widget.profile.copyWith(
          username: usernameController.text.trim(),
          school: schoolController.text.trim(),
          age: selectedAge,
          category: selectedCategory,
          sex: selectedSex,
          avatar: selectedAvatar,
          region: regions.firstWhere(
                (r) => r['id'] == selectedRegionId,
            orElse: () => {'name': ''},
          )['name'],
          province: provinces.firstWhere(
                (p) => p['id'] == selectedProvinceId,
            orElse: () => {'name': ''},
          )['name'],
          city: cities.firstWhere(
                (c) => c['id'] == selectedCityId,
            orElse: () => {'name': ''},
          )['name'],
        );

        AudioService().playDialogueSound();

        setState(() {
          showSuccess = true;
          saving = false;
        });

        await Future.delayed(const Duration(seconds: 4));
        setState(() => successOpacity = 0.0);
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) Navigator.pop(context, updatedProfile);
      } else {
        // Handle validation errors
        setState(() => saving = false);

        // Check if it's a validation error
        if (resp.statusCode == 422) {
          final errors = data['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstError = errors.values.first;
            final errorMessage = firstError is List ? firstError.first : firstError.toString();
            _showError(errorMessage);
          } else {
            _showError(data['message'] ?? 'Validation failed');
          }
        } else {
          _showError(data['message'] ?? 'Failed to update profile');
        }
      }
    } catch (e) {
      setState(() => saving = false);
      _showError('Network error. Please check your connection.');
      print('Error updating profile: $e'); // Debug log
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: showSuccess ? 420 : 850,
        height: showSuccess ? 320 : 370,
        padding: const EdgeInsets.all(30),
        child: showSuccess
            ? AnimatedOpacity(
          opacity: successOpacity,
          duration: const Duration(seconds: 1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images-logo/bird1.png",
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const Text(
                  "Profile Updated!",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your profile has been saved successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        )
            : Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit, color: Colors.black, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      AudioService().playClickSound();
                      AudioService().playDialogueSound();
                      showDialog(
                        context: context,
                        builder: (_) => ChangePasswordDialog(
                          userId: widget.profile.id,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.vpn_key,
                      color: Color(0xFF046EB8),
                    ),
                    label: const Text(
                      'Change Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF046EB8),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF046EB8),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 75,
                            backgroundColor: const Color(0xFFFDD000),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white,
                              backgroundImage: selectedAvatar != null
                                  ? AssetImage(selectedAvatar!)
                                  : null,
                              child: selectedAvatar == null
                                  ? const Icon(
                                Icons.person,
                                size: 25,
                                color: Colors.grey,
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: usernameController,
                                  decoration: _inputDecoration(
                                    'Username',
                                  ),
                                  validator: _validateUsername,
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                      controller: schoolController,
                                        decoration: _inputDecoration('School'),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'School is required';
                                          }
                                          if (value.trim().length < 2) {
                                            return 'School name must be at least 2 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedAge,
                                        decoration: _inputDecoration(
                                          'Age',
                                        ),
                                        isExpanded: true,
                                        items:
                                        const [
                                          "0-12",
                                          "13-17",
                                          "18-22",
                                          "23-29",
                                          "30-39",
                                          "40+",
                                        ]
                                            .map(
                                              (
                                              age,
                                              ) => DropdownMenuItem(
                                            value: age,
                                            child: Text(
                                              age,
                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                        )
                                            .toList(),
                                        onChanged: (val) => setState(
                                              () => selectedAge = val,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedAvatar,
                                        decoration: _inputDecoration(
                                          'Avatar',
                                        ),
                                        isExpanded: true,
                                        items: List.generate(
                                          avatarPaths.length,
                                              (index) => DropdownMenuItem(
                                            value: avatarPaths[index],
                                            child: Text(
                                              avatarNames[index],
                                              overflow: TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                        ),
                                        onChanged: (val) => setState(
                                              () => selectedAvatar = val,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedCategory,
                                        decoration: _inputDecoration(
                                          'Category',
                                        ),
                                        isExpanded: true,
                                        items:
                                        const [
                                          "Student",
                                          "Government Employee",
                                          "Private Employee",
                                          "Self-Employed",
                                          "Not Employed",
                                          "Others",
                                        ]
                                            .map(
                                              (
                                              cat,
                                              ) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(
                                              cat,
                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                        )
                                            .toList(),
                                        onChanged: (val) => setState(
                                              () => selectedCategory = val,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child:
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedSex,
                                        decoration: _inputDecoration(
                                          'Sex',
                                        ),
                                        isExpanded: true,
                                        items: const ["Male", "Female"]
                                            .map(
                                              (
                                              sex,
                                              ) => DropdownMenuItem(
                                            value: sex,
                                            child: Text(
                                              sex,
                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                        )
                                            .toList(),
                                        onChanged: (val) => setState(
                                              () => selectedSex = val,
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
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedRegionId,
                              decoration: _inputDecoration('Region'),
                              items: regions
                                  .map(
                                    (r) => DropdownMenuItem(
                                  value: r['id'],
                                  child: Text(
                                    r['name'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  selectedRegionId = val;
                                  selectedProvinceId = null;
                                  selectedCityId = null;
                                  provinces = [];
                                  cities = [];
                                });
                                fetchProvinces(val);
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedProvinceId,
                              decoration: _inputDecoration('Province'),
                              items: provinces
                                  .map(
                                    (p) => DropdownMenuItem(
                                  value: p['id'],
                                  child: Text(
                                    p['name'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  selectedProvinceId = val;
                                  selectedCityId = null;
                                  cities = [];
                                });
                                fetchCities(val);
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedCityId,
                              decoration: _inputDecoration('City'),
                              items: cities
                                  .map(
                                    (c) => DropdownMenuItem(
                                  value: c['id'],
                                  child: Text(
                                    c['name'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedCityId = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      AudioService().playClickSound();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF046EB8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF046EB8),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000),
                      foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: saving ? null : () {
                      AudioService().playClickSound();
                      saveProfile();
                    },
                    child: saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('SAVE CHANGES'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

