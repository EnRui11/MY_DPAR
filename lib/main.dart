import 'package:flutter/material.dart';
import 'package:mydpar/screens/knowledge_base_screen.dart';
import 'package:mydpar/screens/login_screen.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDPAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Make sure to add this font to your pubspec.yaml
      ),
      home: const HomeScreen(),
    );
  }
}
