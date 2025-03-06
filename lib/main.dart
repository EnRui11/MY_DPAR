import 'package:flutter/material.dart';
import 'package:mydpar/screens/knowledge_base_screen.dart';
import 'package:mydpar/screens/login_screen.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Request permissions when app starts
    _checkPermissions();

    return MaterialApp(
      title: 'MyDPAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const LoginScreen(),
    );
  }
}
