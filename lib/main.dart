import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/account/login_screen.dart';
import 'package:mydpar/services/cpr_audio_service.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/widgets/cpr_rhythm_overlay.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
            primaryColor: colors.primary100,
            scaffoldBackgroundColor: colors.bg200,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: createMaterialColor(colors.primary100),
              backgroundColor: colors.bg200,
              cardColor: colors.bg100,
              errorColor: colors.warning,
            ).copyWith(
              surface: colors.bg100,
              onSurface: colors.text200,
            ),
            textTheme: TextTheme(
              headlineLarge: TextStyle(
                color: colors.primary300,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
              bodyLarge: TextStyle(color: colors.text100, fontSize: 16),
              bodyMedium: TextStyle(color: colors.text200, fontSize: 14),
            ),
            iconTheme: IconThemeData(color: colors.accent200),
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
          home: const AuthWrapper(), // Replace LoginScreen with AuthWrapper
        );
      },
    );
  }
}

/// Wrapper to handle authentication state and route to appropriate screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is signed in
          return const HomeScreen();
        }
        // User is not signed in
        return const LoginScreen();
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
            CPRRhythmOverlay(
                colors: Provider.of<ThemeProvider>(context).currentTheme),
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