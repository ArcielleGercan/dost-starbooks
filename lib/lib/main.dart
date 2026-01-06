import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'audio_service.dart'; // Import audio service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service
  await AudioService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}