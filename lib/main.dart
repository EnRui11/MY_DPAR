import 'package:flutter/material.dart';
import 'package:mydpar/screens/login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
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

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final colors = themeProvider.currentTheme;
        return MaterialApp(
          title: 'MyDPAR',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            // Dynamic theme properties based on ThemeProvider
            primaryColor: colors.primary100,
            scaffoldBackgroundColor: colors.bg100,
            textTheme: TextTheme(
              headlineLarge: TextStyle(
                  color: colors.primary300, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: colors.text100),
              bodyMedium: TextStyle(color: colors.text200),
            ),
            iconTheme: IconThemeData(color: colors.accent200),
            cardColor: colors.bg200,
            // Customize more Material3 properties as needed
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
