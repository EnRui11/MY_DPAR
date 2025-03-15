import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Unused in this file, consider removing if not needed
import 'package:provider/provider.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/account/login_screen.dart'; // Unused here, consider removing unless dynamically routed
import 'package:mydpar/services/cpr_audio_service.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/widgets/cpr_rhythm_overlay.dart';

void main() {
  // Ensure Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CPRAudioService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final colors = themeProvider.currentTheme;

        return MaterialApp(
          title: 'MyDPAR',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            // Core theme properties
            primaryColor: colors.primary100,
            scaffoldBackgroundColor: colors.bg200, // Changed to bg200 for consistency
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: createMaterialColor(colors.primary100),
              backgroundColor: colors.bg200,
              cardColor: colors.bg100,
              errorColor: colors.warning,
            ).copyWith(
              surface: colors.bg100,
              onSurface: colors.text200,
            ),
            // Text theme
            textTheme: TextTheme(
              headlineLarge: TextStyle(
                color: colors.primary300,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
              bodyLarge: TextStyle(color: colors.text100, fontSize: 16),
              bodyMedium: TextStyle(color: colors.text200, fontSize: 14),
            ),
            // Icon theme
            iconTheme: IconThemeData(color: colors.accent200),
            // Button theme
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          builder: (context, child) => _AppOverlayBuilder(child: child),
          home: const HomeScreen(),
        );
      },
    );
  }
}

/// Builds the app with a global CPR rhythm overlay
class _AppOverlayBuilder extends StatelessWidget {
  final Widget? child;

  const _AppOverlayBuilder({this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<CPRAudioService>(
      builder: (context, audioService, _) => Stack(
        children: [
          child!,
          if (audioService.isOverlayVisible)
            CPRRhythmOverlay(colors: Provider.of<ThemeProvider>(context).currentTheme),
        ],
      ),
    );
  }
}

/// Creates a MaterialColor from a Color for primarySwatch
MaterialColor createMaterialColor(Color color) {
  final strengths = <double>[.05];
  final swatch = <int, Color>{};
  final r = color.red, g = color.green, b = color.blue;

  for (var i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}