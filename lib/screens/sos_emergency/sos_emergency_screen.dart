import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Displays an SOS emergency screen with location, countdown, and alert features.
class SOSEmergencyScreen extends StatefulWidget {
  const SOSEmergencyScreen({super.key});

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen>
    with SingleTickerProviderStateMixin {
  // State variables
  int _alertCountdown = 10;
  int _cancelCountdown = 5;
  bool _isAlertSent = false;
  bool _isCancelling = false;
  Position? _currentPosition;
  String _currentAddress = 'Fetching location...';
  bool _isAudioPlaying = false;
  String? _alertDocId;

  // Controllers and services
  late final MapController _mapController;
  late final AnimationController _flickerController;
  late Animation<Color?> _flickerAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Timers
  Timer? _locationTimer;
  Timer? _updateTimer;

  // Constants
  static const _padding = 24.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 12.0;
  static const _spacingLarge = 24.0;
  static const _defaultLocation = LatLng(3.1390, 101.6869);
  static const _notificationId = 888;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
    _checkAndInitializeAlert();
  }

  /// Initializes controllers for map and animation.
  void _initializeControllers() {
    _mapController = MapController();
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  /// Initializes audio and notification services.
  Future<void> _initializeServices() async {
    await _initializeNotifications();
    await _initializeAudio();
    _startLocationUpdates();
  }

  /// Checks for an existing alert and initializes state accordingly.
  Future<void> _checkAndInitializeAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final isAlertActive = prefs.getBool('is_alert_active') ?? false;
    final storedAlertId = prefs.getString('active_alert_id');

    if (isAlertActive && storedAlertId != null) {
      setState(() {
        _isAlertSent = true;
        _alertDocId = storedAlertId;
        _alertCountdown = 0;
        _flickerAnimation = ColorTween(begin: Colors.red, end: Colors.white)
            .animate(_flickerController);
        _flickerController.repeat();
      });
      _startFirebaseUpdates();
      await _showPersistentNotification();
      await _playAlertEffects();
    } else {
      _startAlertCountdown();
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _updateTimer?.cancel();
    _mapController.dispose();
    _flickerController.dispose();
    _audioPlayer.dispose();
    Vibration.cancel();
    super.dispose();
  }

  /// Initializes local notifications with permission handling.
  Future<void> _initializeNotifications() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      _showSnackBar('Notifications permission denied', Colors.orange);
      return;
    }

    const androidSettings = AndroidInitializationSettings('sos_icon');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SOSEmergencyScreen()),
          );
        }
      },
    );
  }

  /// Initializes the emergency alert audio.
  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/loud-emergency-alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      _showSnackBar('Failed to initialize audio: $e', Colors.red);
    }
  }

  /// Starts periodic location updates.
  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCurrentLocation());
  }

  /// Fetches and updates the current location and address.
  Future<void> _updateCurrentLocation() async {
    if (!mounted) return;
    if (!await _checkLocationPermission()) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final address = placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : 'Unnamed Location';

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _mapController.move(LatLng(position.latitude, position.longitude), 15);
          _currentAddress = address;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = 'Error getting location');
    }
  }

  /// Formats a placemark into a readable address string.
  String _formatAddress(Placemark place) {
    return [
      place.street,
      place.locality,
      place.administrativeArea,
      place.postalCode,
    ].where((e) => e != null && e.isNotEmpty).join(', ').trim();
  }

  /// Checks and requests location permissions.
  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        setState(() => _currentAddress = 'Location services are disabled');
        _showSnackBar('Location services are disabled', Colors.red);
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _currentAddress = 'Location permissions are denied');
          _showSnackBar('Location permission denied', Colors.red);
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _currentAddress = 'Location permissions permanently denied');
        _showSnackBar('Location permission permanently denied', Colors.red);
      }
      return false;
    }

    return true;
  }

  /// Starts the countdown for sending the emergency alert.
  void _startAlertCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _alertCountdown <= 0) {
        timer.cancel();
        if (mounted && _alertCountdown <= 0) _sendAlert();
        return;
      }
      setState(() => _alertCountdown--);
    });
  }

  /// Sends the emergency alert and saves initial data to Firestore.
  Future<void> _sendAlert() async {
    setState(() {
      _isAlertSent = true;
      _flickerAnimation = ColorTween(begin: Colors.red, end: Colors.white)
          .animate(_flickerController);
      _flickerController.repeat();
    });
    await _playAlertEffects();

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('No user signed in', Colors.red);
      return;
    }

    final userData = await _fetchUserData(user.uid);
    final initialData = _buildInitialAlertData(user.uid, userData);
    await _saveAlertToFirestore(initialData);
  }

  /// Fetches user data from Firestore.
  Future<Map<String, dynamic>?> _fetchUserData(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data();
  }

  /// Builds initial alert data for Firestore.
  Map<String, dynamic> _buildInitialAlertData(String uid, Map<String, dynamic>? userData) {
    final alertStartTime = DateTime.now();
    return {
      'uid': uid,
      'username': userData?['lastName'] as String? ?? 'Unknown',
      'phoneNumber': userData?['phoneNumber'] as String? ?? 'Unknown',
      'emergencyContacts': (userData?['emergencyContacts'] as List<dynamic>? ?? [])
          .map((contact) => contact as Map<String, dynamic>)
          .toList(),
      'alertStartTime': Timestamp.fromDate(alertStartTime),
      'latestUpdateTime': Timestamp.fromDate(alertStartTime),
      'location': _currentPosition != null
          ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
          : GeoPoint(_defaultLocation.latitude, _defaultLocation.longitude),
      'address': _currentAddress,
      'isActive': true,
      'cancelTime': null,
    };
  }

  /// Saves alert data to Firestore and updates local state.
  Future<void> _saveAlertToFirestore(Map<String, dynamic> initialData) async {
    try {
      final docRef = await _firestore.collection('alerts').add(initialData);
      _alertDocId = docRef.id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_alert_id', _alertDocId!);
      await prefs.setBool('is_alert_active', true);

      _startFirebaseUpdates();
      await _showPersistentNotification();
    } catch (e) {
      _showSnackBar('Failed to save alert to Firebase: $e', Colors.red);
    }
  }

  /// Shows a persistent notification for the active alert.
  Future<void> _showPersistentNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'sos_alert_channel',
      'SOS Alerts',
      channelDescription: 'Persistent notification for active SOS alerts',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      icon: 'sos_icon',
    );

    await _notificationsPlugin.show(
      _notificationId,
      'SOS Alert Active',
      'Tap to return to emergency screen',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Starts periodic updates to Firebase with latest time and location.
  void _startFirebaseUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateAlertData());
  }

  /// Updates the latest time and location in Firestore.
  Future<void> _updateAlertData() async {
    if (!mounted || _alertDocId == null) return;

    final updateData = {
      'latestUpdateTime': Timestamp.now(),
      'location': _currentPosition != null
          ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
          : GeoPoint(_defaultLocation.latitude, _defaultLocation.longitude),
      'address': _currentAddress,
    };

    try {
      await _firestore.collection('alerts').doc(_alertDocId).update(updateData);
    } catch (e) {
      _showSnackBar('Failed to update alert data: $e', Colors.red);
    }
  }

  /// Plays audio and vibration effects for the alert.
  Future<void> _playAlertEffects() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.resume();
      setState(() => _isAudioPlaying = true);

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [1, 1000], repeat: 0);
      }
    } catch (e) {
      _showSnackBar('Failed to play alert effects: $e', Colors.red);
    }
  }

  /// Initiates the cancellation countdown.
  void _startCancelCountdown() {
    setState(() {
      _isCancelling = true;
      _cancelCountdown = 5;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCancelling || _cancelCountdown <= 0) {
        timer.cancel();
        if (mounted && _cancelCountdown <= 0) _cancelAlert();
        return;
      }
      setState(() => _cancelCountdown--);
    });
  }

  /// Cancels the alert and updates Firestore.
  Future<void> _cancelAlert() async {
    setState(() {
      _isAlertSent = false;
      _isAudioPlaying = false;
    });
    _flickerController.stop();
    Vibration.cancel();
    await _audioPlayer.pause();
    _updateTimer?.cancel();

    if (_alertDocId != null) {
      await _updateFirestoreOnCancel();
      await _clearSharedPreferences();
      await _notificationsPlugin.cancel(_notificationId);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      _showSnackBar('Alert Cancelled', Colors.green);
    }
  }

  /// Updates Firestore with cancel time.
  Future<void> _updateFirestoreOnCancel() async {
    try {
      await _firestore.collection('alerts').doc(_alertDocId).update({
        'isActive': false,
        'cancelTime': Timestamp.now(),
      });
    } catch (e) {
      _showSnackBar('Failed to update cancel time: $e', Colors.red);
    }
  }

  /// Clears alert-related data from SharedPreferences.
  Future<void> _clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_alert_id');
    await prefs.remove('is_alert_active');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return WillPopScope(
      onWillPop: () async => _handleBackPress(colors),
      child: AnimatedBuilder(
        animation: _flickerController,
        builder: (context, child) => Scaffold(
          backgroundColor: _isAlertSent ? (_flickerAnimation.value ?? colors.warning) : colors.bg200,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: Column(
                children: [
                  _buildCountdownTimer(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildLocationSection(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildEmergencyActions(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles back press logic.
  Future<bool> _handleBackPress(AppColorTheme colors) async {
    if (!_isAlertSent && _alertCountdown <= 0) return true;
    _showSnackBar('Please cancel the alert to exit', Colors.orange);
    return false;
  }

  /// Builds the countdown timer section.
  Widget _buildCountdownTimer(AppColorTheme colors) => GestureDetector(
    onTapDown: (_) {
      if (!_isCancelling && (_isAlertSent || _alertCountdown > 0)) {
        _startCancelCountdown();
      }
    },
    onTapUp: (_) => setState(() {
      _isCancelling = false;
      _cancelCountdown = 5;
    }),
    child: AnimatedBuilder(
      animation: _flickerController,
      builder: (context, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(_padding),
        decoration: _buildTimerDecoration(colors),
        child: Column(
          children: [
            Text(
              _isAlertSent ? 'Emergency Alert Sent' : 'Automatic Alert in',
              style: TextStyle(color: colors.bg100, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              _alertCountdown.toString(),
              style: TextStyle(color: colors.bg100, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              _isCancelling ? 'Cancelling in $_cancelCountdown' : 'Press and hold to cancel',
              style: TextStyle(color: colors.bg100, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );

  /// Builds the decoration for the countdown timer.
  BoxDecoration _buildTimerDecoration(AppColorTheme colors) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _isAlertSent
          ? [
        _flickerAnimation.value ?? colors.warning,
        (_flickerAnimation.value ?? colors.warning).withOpacity(0.8),
      ]
          : [colors.warning, colors.warning.withOpacity(0.8)],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: colors.warning.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Builds the location display section with a map.
  Widget _buildLocationSection(AppColorTheme colors) => Container(
    padding: const EdgeInsets.all(_padding - 8),
    decoration: _cardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Location',
          style: TextStyle(color: colors.primary300, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: _spacingMedium),
        SizedBox(
          height: 150,
          child: _buildMap(colors),
        ),
        const SizedBox(height: _spacingMedium),
        Text(_currentAddress, style: TextStyle(color: colors.text200, fontSize: 14)),
      ],
    ),
  );

  /// Builds the map widget.
  Widget _buildMap(AppColorTheme colors) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : _defaultLocation,
        zoom: 15,
        interactiveFlags: InteractiveFlag.none,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            if (_currentPosition != null)
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                builder: (_) => Icon(Icons.location_pin, color: colors.warning, size: 40),
              ),
          ],
        ),
      ],
    ),
  );

  /// Builds the emergency action buttons section.
  Widget _buildEmergencyActions(AppColorTheme colors) => Column(
    children: [
      _buildEmergencyButton(
        icon: Icons.phone,
        title: 'Emergency Services',
        subtitle: 'Call 999',
        colors: colors,
        onTap: _callEmergencyServices,
        isPulsing: true,
      ),
      const SizedBox(height: _spacingLarge),
      _buildEmergencyButton(
        icon: Icons.people,
        title: 'Emergency Contacts',
        subtitle: 'Alert your emergency contacts',
        colors: colors,
        onTap: _alertEmergencyContacts,
        isPulsing: false,
      ),
    ],
  );

  /// Builds a reusable emergency action button with optional pulsing animation.
  Widget _buildEmergencyButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorTheme colors,
    required VoidCallback onTap,
    required bool isPulsing,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_padding - 8),
          decoration: _cardDecoration(colors),
          child: Row(
            children: [
              Icon(icon, color: colors.warning, size: 24),
              const SizedBox(width: _spacingMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: colors.primary300, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.text200,
                      fontSize: 14,
                      fontWeight: isPulsing ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate(
          onPlay: (controller) => isPulsing ? controller.repeat(reverse: true) : null,
          effects: isPulsing
              ? [
            ScaleEffect(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.02, 1.02),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            ),
            ShimmerEffect(
              color: colors.warning.withOpacity(0.3),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
            ),
          ]
              : [],
        ),
      );

  /// Initiates a call to emergency services (999 in Malaysia).
  Future<void> _callEmergencyServices() async {
    final uri = Uri.parse('tel:999');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not launch emergency call', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to launch call: $e', Colors.red);
    }
  }

  /// Placeholder for alerting emergency contacts.
  void _alertEmergencyContacts() {
    _showSnackBar('Emergency contacts alert not yet implemented', Colors.orange);
  }

  /// Displays a snackbar with a given message and background color.
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Provides a reusable card decoration.
  BoxDecoration _cardDecoration(AppColorTheme colors) => BoxDecoration(
    color: colors.bg100.withOpacity(0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colors.bg100.withOpacity(0.2)),
  );
}