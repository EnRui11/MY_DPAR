import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mydpar/screens/main/bottom_nav_container.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/main/map_screen.dart';
import 'package:mydpar/screens/main/community_screen.dart';
import 'package:mydpar/screens/main/profile_screen.dart';
import 'package:mydpar/screens/account/login_screen.dart';
import 'package:mydpar/services/cpr_audio_service.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/widgets/cpr_rhythm_overlay.dart';
import 'package:mydpar/services/sos_alert_service.dart';
import 'package:mydpar/services/permission_service.dart';
import 'package:mydpar/services/background_location_service.dart';
import 'services/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Entry point of the MyDPAR application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();
  await PermissionRequester.requestInitial();

  // Start background location service
  BackgroundLocationService().startLocationUpdates();

  runApp(const MyDPARApp());
}

/// Handles Firebase initialization with robust error management.
class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase App Check with debug provider
      await FirebaseAppCheck.instance.activate(
        // Use debug provider for development
        androidProvider: AndroidProvider.debug,
        // For iOS devices
        appleProvider: AppleProvider.debug,
      );
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }
}

/// Manages permission requests for the app.
class PermissionRequester {
  static Future<void> requestInitial() async {
    final permissionService = PermissionService();
    await permissionService.requestInitialPermissions();
  }
}

/// Root application widget providing app-wide dependencies.
class MyDPARApp extends StatelessWidget {
  const MyDPARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CPRAudioService()),
        ChangeNotifierProvider(create: (_) => UserInformationService()),
        ChangeNotifierProvider(create: (_) => SOSAlertService()),
        ChangeNotifierProvider(create: (_) => PermissionService()),
        ChangeNotifierProvider(create: (_) => DisasterService()),
        ChangeNotifierProvider(create: (_) => NavigationService()),
      ],
      child: const AppThemeWrapper(),
    );
  }
}

/// Configures the app's theme and structure.
class AppThemeWrapper extends StatelessWidget {
  const AppThemeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
          primarySwatch: _createMaterialColor(colors.primary100),
          backgroundColor: colors.bg200,
          cardColor: colors.bg100,
          errorColor: colors.warning,
        ).copyWith(surface: colors.bg100, onSurface: colors.text200),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      builder: (context, child) => AppOverlay(child: child),
      home: const AuthWrapper(),
    );
  }

  /// Generates a MaterialColor swatch from a given color.
  MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[0.05];
    final swatch = <int, Color>{};
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    for (var i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (final strength in strengths) {
      final ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

/// Manages authentication state and routes to appropriate screens.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserInformationService>(context);
    final sosService = Provider.of<SOSAlertService>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: _authStateBuilder(userService, sosService),
    );
  }

  // In the _authStateBuilder method, replace the return statement:

  Widget Function(BuildContext, AsyncSnapshot<User?>) _authStateBuilder(
    UserInformationService userService,
    SOSAlertService sosService,
  ) {
    return (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (snapshot.hasError) {
        debugPrint('Authentication error: ${snapshot.error}');
        return const Scaffold(
            body: Center(child: Text('Error loading authentication state')));
      }

      final user = snapshot.data;
      if (user != null) {
        _initializeServices(context, userService, sosService);
        return const BottomNavContainer();
      }
      return const LoginScreen();
    };
  }

  void _initializeServices(
    BuildContext context,
    UserInformationService userService,
    SOSAlertService sosService,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!userService.isInitialized) {
        userService.initializeUser().catchError((e) {
          debugPrint('Failed to initialize user: $e');
        });
      }
      if (!sosService.isInitialized) {
        sosService.checkActiveAlert(context);
      }
    });
  }
}

/// Overlays the app with CPR rhythm feedback when active.
class AppOverlay extends StatelessWidget {
  final Widget? child;

  const AppOverlay({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<CPRAudioService>(context);
    final colors = Provider.of<ThemeProvider>(context).currentTheme;

    return Stack(
      children: [
        if (child != null) child!,
        if (audioService.isOverlayVisible) CPRRhythmOverlay(colors: colors),
      ],
    );
  }
}
