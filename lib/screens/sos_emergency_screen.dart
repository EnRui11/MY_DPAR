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
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class SOSEmergencyScreen extends StatefulWidget {
  const SOSEmergencyScreen({super.key});

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen>
    with SingleTickerProviderStateMixin {
  int _alertCountdown = 10;
  int _cancelCountdown = 5;
  bool _isAlertSent = false;
  bool _isCancelling = false;
  Position? _currentPosition;
  String _currentAddress = 'Fetching location...';
  late final MapController _mapController;
  late final AnimationController _flickerController;
  late Animation<Color?> _flickerAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _startAlertCountdown();
    _getCurrentLocation();
    _initAudio();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _flickerController.dispose();
    _audioPlayer.dispose();
    Vibration.cancel();
    super.dispose();
  }

  /// Initializes the emergency alert audio
  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/loud-emergency-alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      _showSnackBar('Failed to initialize audio: $e', Colors.red);
    }
  }

  /// Fetches the user's current location and updates the map
  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = 'Location services are disabled');
        _showSnackBar('Location services are disabled', Colors.red);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = 'Location permissions are denied');
          _showSnackBar('Location permission denied', Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = 'Location permissions permanently denied');
        _showSnackBar('Location permission permanently denied', Colors.red);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _mapController.move(LatLng(position.latitude, position.longitude), 15);
      });

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        setState(() {
          _currentAddress = '${place.street ?? ''}, ${place.locality ?? ''}, '
              '${place.administrativeArea ?? ''} ${place.postalCode ?? ''}'.trim();
          if (_currentAddress.isEmpty) _currentAddress = 'Unnamed Location';
        });
      }
    } catch (e) {
      setState(() => _currentAddress = 'Error getting location');
      _showSnackBar('Error getting location: $e', Colors.red);
    }
  }

  /// Starts the countdown before sending the alert
  void _startAlertCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_alertCountdown <= 0) {
        timer.cancel();
        setState(() {
          _isAlertSent = true;
          _flickerAnimation = ColorTween(
            begin: Colors.red,
            end: Colors.white,
          ).animate(_flickerController);
          _flickerController.repeat();
        });
        _playAlertEffects();
        return;
      }
      setState(() => _alertCountdown--);
    });
  }

  /// Plays alert effects (audio and vibration)
  Future<void> _playAlertEffects() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.resume();
      setState(() => _isPlaying = true);

      final bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) {
        Vibration.vibrate(pattern: [1, 1000], repeat: 0);
      }
    } catch (e) {
      _showSnackBar('Failed to play alert effects: $e', Colors.red);
    }
  }

  /// Starts the cancellation countdown
  void _startCancelCountdown() {
    setState(() {
      _isCancelling = true;
      _cancelCountdown = 5;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isCancelling || _cancelCountdown <= 0) {
        timer.cancel();
        if (_cancelCountdown <= 0) {
          _cancelAlert();
        }
        return;
      }
      setState(() => _cancelCountdown--);
    });
  }

  /// Cancels the alert and resets the screen
  Future<void> _cancelAlert() async {
    setState(() => _isAlertSent = false);
    _flickerController.stop();
    Vibration.cancel();

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    _showSnackBar('Alert Cancelled', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme; // Updated type

    return AnimatedBuilder(
      animation: _flickerController,
      builder: (context, child) => Scaffold(
        backgroundColor:
        _isAlertSent ? (_flickerAnimation.value ?? colors.warning) : colors.bg200,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(_paddingValue),
            child: Column(
              children: [
                _buildCountdownTimer(colors),
                const SizedBox(height: _spacingLarge),
                _buildLocationSection(colors),
                const SizedBox(height: _spacingLarge),
                _buildEmergencyContacts(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the countdown timer widget
  Widget _buildCountdownTimer(AppColorTheme colors) => GestureDetector(
    onTapDown: (_) {
      if (!_isCancelling && (_isAlertSent || _alertCountdown > 0)) {
        _startCancelCountdown();
      }
    },
    onTapUp: (_) {
      setState(() {
        _isCancelling = false;
        _cancelCountdown = 5;
      });
    },
    child: AnimatedBuilder(
      animation: _flickerController,
      builder: (context, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(_paddingValue),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isAlertSent
                ? [
              _flickerAnimation.value ?? colors.warning,
              (_flickerAnimation.value ?? colors.warning).withOpacity(0.8),
            ]
                : [
              colors.warning,
              colors.warning.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.warning.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _isAlertSent ? 'Emergency Alert Sent' : 'Automatic Alert in',
              style: TextStyle(
                color: colors.bg100,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              _isCancelling ? _cancelCountdown.toString() : _alertCountdown.toString(),
              style: TextStyle(
                color: colors.bg100,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              _isCancelling
                  ? 'Cancelling in $_cancelCountdown'
                  : 'Press and hold to cancel',
              style: TextStyle(color: colors.bg100, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );

  /// Builds the location section with map and address
  Widget _buildLocationSection(AppColorTheme colors) => Container(
    padding: const EdgeInsets.all(_paddingValue - 8),
    decoration: BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.bg100.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Location',
          style: TextStyle(
            color: colors.primary300,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: _spacingMedium),
        SizedBox(
          height: 150,
          child: ClipRRect(
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
                        point:
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        builder: (_) => Icon(
                          Icons.location_pin,
                          color: colors.warning,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: _spacingMedium),
        Text(
          _currentAddress,
          style: TextStyle(color: colors.text200, fontSize: 14),
        ),
      ],
    ),
  );

  /// Builds the emergency contacts section
  Widget _buildEmergencyContacts(AppColorTheme colors) => Column(
    children: [
      _buildEmergencyButton(
        icon: Icons.phone,
        title: 'Emergency Services',
        subtitle: 'Call 999',
        colors: colors,
        onTap: _callEmergencyServices,
      ),
      const SizedBox(height: _spacingLarge),
      _buildEmergencyButton(
        icon: Icons.people,
        title: 'Emergency Contacts',
        subtitle: 'Alert your emergency contacts',
        colors: colors,
        onTap: _alertEmergencyContacts,
      ),
    ],
  );

  /// Builds an individual emergency button
  Widget _buildEmergencyButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorTheme colors,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_paddingValue - 8),
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.bg100.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.warning, size: 24),
              const SizedBox(width: _spacingMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.text200, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// Initiates a call to emergency services
  Future<void> _callEmergencyServices() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '999');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar('Could not launch emergency call', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to launch call: $e', Colors.red);
    }
  }

  /// Alerts emergency contacts (placeholder for implementation)
  void _alertEmergencyContacts() {
    // TODO: Implement emergency contacts alert (e.g., SMS, Firebase notification)
    _showSnackBar('Emergency contacts alert not yet implemented', Colors.orange);
  }

  /// Default map location if no position is available
  static const LatLng _defaultLocation = LatLng(3.1390, 101.6869); // Kuala Lumpur

  /// Displays a snackbar with a message
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
}