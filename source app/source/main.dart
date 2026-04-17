import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow.shade200, brightness: Brightness.light),
        scaffoldBackgroundColor: Colors.yellow.shade50,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFF9C4), foregroundColor: Colors.black),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}