import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSEmergencyScreen extends StatefulWidget {
  const SOSEmergencyScreen({super.key});

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen>
    with SingleTickerProviderStateMixin {
  int alertCountdown = 10;
  int cancelCountdown = 5;
  bool isAlertSent = false;
  bool isCancelling = false;
  Position? currentPosition;
  String currentAddress = 'Fetching location...';
  late final MapController _mapController;
  late AnimationController _flickerController;
  late Animation<Color?> _flickerAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    startAlertCountdown();
    getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _flickerController.dispose();
    Vibration.cancel();
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            currentAddress = 'Location permissions are denied';
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
        _mapController.move(LatLng(position.latitude, position.longitude), 15);
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          currentAddress = '${place.street}, ${place.locality}, '
              '${place.administrativeArea} ${place.postalCode}';
        });
      }
    } catch (e) {
      setState(() {
        currentAddress = 'Error getting location';
      });
    }
  }

  void startAlertCountdown() {
    Future.doWhile(() async {
      if (alertCountdown <= 0) {
        setState(() {
          isAlertSent = true;
          _flickerAnimation = ColorTween(
            begin: Colors.red,
            end: Colors.white,
          ).animate(_flickerController);
          _flickerController.repeat();
          // Start emergency-like vibration when isAlertSent becomes true
          Vibration.hasVibrator().then((hasVibrator) {
            if (hasVibrator ?? false) {
              // Custom emergency alert pattern: rapid short pulses
              Vibration.vibrate(pattern: [1, 1000], repeat: 0);
            }
          });
        });
        return false;
      }
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          alertCountdown--;
        });
      }
      return true;
    });
  }

  void startCancelCountdown() {
    setState(() {
      isCancelling = true;
      cancelCountdown = 5;
    });
    Future.doWhile(() async {
      if (!isCancelling || cancelCountdown <= 0) {
        if (cancelCountdown <= 0) {
          setState(() {
            isAlertSent = false; // Set isAlertSent to false when cancelling
          });
          _flickerController.stop();
          Vibration.cancel(); // Stop vibration when isAlertSent becomes false
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Alert Cancel',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return false;
      }
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          cancelCountdown--;
        });
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return AnimatedBuilder(
      animation: _flickerController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: isAlertSent
              ? (_flickerAnimation.value ?? colors.warning)
              : colors.primary200,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildCountdownTimer(colors),
                  const SizedBox(height: 24),
                  _buildLocationSection(colors),
                  const SizedBox(height: 24),
                  _buildEmergencyContacts(colors),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownTimer(dynamic colors) {
    return GestureDetector(
      onTapDown: (_) {
        if (!isCancelling) {
          startCancelCountdown();
        }
      },
      onTapUp: (_) {
        setState(() {
          isCancelling = false;
          cancelCountdown = 5;
        });
      },
      child: AnimatedBuilder(
        animation: _flickerController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAlertSent
                    ? [
                        _flickerAnimation.value ?? colors.warning,
                        (_flickerAnimation.value ?? colors.warning)
                            .withOpacity(0.8),
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
                  isAlertSent ? 'Emergency Alert Sent' : 'Automatic Alert in',
                  style: TextStyle(
                    color: colors.bg100,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alertCountdown.toString(),
                  style: TextStyle(
                    color: colors.bg100,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCancelling
                      ? 'Cancelling in $cancelCountdown'
                      : 'Press and hold to cancel',
                  style: TextStyle(
                    color: colors.bg100,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationSection(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: currentPosition != null
                      ? LatLng(
                          currentPosition!.latitude, currentPosition!.longitude)
                      : const LatLng(3.1390, 101.6869),
                  zoom: 15,
                  interactiveFlags: InteractiveFlag.none,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      if (currentPosition != null)
                        Marker(
                          point: LatLng(
                            currentPosition!.latitude,
                            currentPosition!.longitude,
                          ),
                          width: 80,
                          height: 80,
                          builder: (context) => Icon(
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
          const SizedBox(height: 12),
          Text(
            currentAddress,
            style: TextStyle(
              color: colors.text200,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts(dynamic colors) {
    return Column(
      children: [
        _buildEmergencyButton(
          icon: Icons.phone,
          title: 'Emergency Services',
          subtitle: 'Call 999',
          colors: colors,
          onTap: () async {
            final Uri phoneUri = Uri(
              scheme: 'tel',
              path: '999',
            );
            if (await canLaunchUrl(phoneUri)) {
              await launchUrl(phoneUri);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not launch emergency call'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(height: 16),
        _buildEmergencyButton(
          icon: Icons.people,
          title: 'Emergency Contacts',
          subtitle: 'Alert your emergency contacts',
          colors: colors,
          onTap: () {
            // TODO: Implement emergency contacts alert
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required dynamic colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.warning, size: 24),
            const SizedBox(width: 12),
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
                  style: TextStyle(
                    color: colors.text200,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
