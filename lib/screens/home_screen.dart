import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/profile_screen.dart';
import 'package:mydpar/screens/knowledge_base_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:mydpar/screens/report_incident_screen.dart';
import 'package:mydpar/screens/community_screen.dart';
import 'package:mydpar/screens/sos_emergency_screen.dart';
import 'package:mydpar/screens/all_alerts_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:latlong2/latlong.dart';

// Model for alert data, Firebase-ready
class Alert {
  final String topic;
  final String description;
  final String severity;
  final String location;
  final String time;
  final String disasterType;
  final LatLng? coordinates;

  const Alert({
    required this.topic,
    required this.description,
    required this.severity,
    required this.location,
    required this.time,
    required this.disasterType,
    this.coordinates,
  });

  // Factory for Firebase data parsing (uncomment when integrating)
  // factory Alert.fromJson(Map<String, dynamic> json) => Alert(
  //   topic: json['topic'] as String,
  //   description: json['description'] as String,
  // );

  // Convert to JSON for Firebase writes
  Map<String, dynamic> toJson() => {
        'topic': topic,
        'description': description,
        'severity': severity,
        'location': location,
        'time': time,
        'disasterType': disasterType,
        'coordinates': coordinates != null
            ? {
                'latitude': coordinates!.latitude,
                'longitude': coordinates!.longitude
              }
            : null,
      };
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme; // Updated type

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(context, colors),
            _buildHeader(colors),
            _buildBottomNavigation(context, colors),
          ],
        ),
      ),
    );
  }

  /// Builds the header with gradient and welcome message
  Widget _buildHeader(AppColorTheme colors) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.accent200, colors.accent100],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello, Username', // TODO: Replace with Firebase Auth user name
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.bg100,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              'Welcome to MY_DPAR',
              style: TextStyle(fontSize: 16, color: colors.primary100),
            ),
            Text(
              'Your Disaster Preparedness and Response Assistant',
              style: TextStyle(fontSize: 16, color: colors.primary100),
            ),
          ],
        ),
      );

  /// Builds the scrollable main content area
  Widget _buildContent(BuildContext context, AppColorTheme colors) =>
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            _paddingValue, 120, _paddingValue, _paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 64),
            _buildQuickActions(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildSOSButton(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildRecentAlertsSection(context, colors),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      );

  /// Builds the animated SOS emergency button
  Widget _buildSOSButton(BuildContext context, AppColorTheme colors) =>
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.warning,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.warning.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: MaterialButton(
              onPressed: () => _navigateTo(context, const SOSEmergencyScreen()),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colors.bg100, size: 24),
                  const SizedBox(width: _spacingSmall),
                  Text(
                    'SOS Emergency',
                    style: TextStyle(
                      color: colors.bg100,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Builds the quick action cards (Report Incident, Knowledge Base)
  Widget _buildQuickActions(BuildContext context, AppColorTheme colors) => Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.location_on_outlined,
              label: 'Report Incident',
              colors: colors,
              onTap: () => _navigateTo(context, const ReportIncidentScreen()),
            ),
          ),
          const SizedBox(width: _spacingMedium),
          Expanded(
            child: _buildActionCard(
              icon: Icons.book_outlined,
              label: 'Knowledge Base',
              colors: colors,
              onTap: () => _navigateTo(context, const KnowledgeBaseScreen()),
            ),
          ),
        ],
      );

  /// Reusable action card widget
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required AppColorTheme colors,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.bg100.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(_spacingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.accent200, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: colors.primary300,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  /// Builds the recent alerts section with a header and list
  Widget _buildRecentAlertsSection(
          BuildContext context, AppColorTheme colors) =>
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Alerts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                ),
              ),
              TextButton(
                onPressed: () => _navigateTo(context, const AlertsScreen()),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: colors.accent200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _spacingMedium),
          _buildAlertsList(colors),
        ],
      );

  /// Builds an individual alert card
  Widget _buildAlertCard({
    required String topic,
    required String description,
    required String severity,
    required String location,
    required String time,
    required String disasterType,
    required AppColorTheme colors,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: _spacingMedium),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(_spacingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSeverityColor(severity, colors),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getDisasterIcon(disasterType),
                  color: colors.bg100, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        disasterType,
                        style: TextStyle(
                          color: colors.accent200,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(severity, colors)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          severity,
                          style: TextStyle(
                            color: _getSeverityColor(severity, colors),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic,
                    style: TextStyle(
                      color: colors.primary300,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: colors.text200, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: colors.text200, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          color: colors.text200,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, color: colors.text200, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: colors.text200,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Helper method to get color based on severity
  Color _getSeverityColor(String severity, AppColorTheme colors) {
    switch (severity.toLowerCase()) {
      case 'high':
        return colors.warning;
      case 'medium':
        return Color(0xFFFF8C00);
      case 'low':
        return Color(0xFF71C4EF);
        ;
      default:
        return colors.text200;
    }
  }

  /// Helper method to get icon based on disaster type
  IconData _getDisasterIcon(String type) {
    const IconData flood = IconData(0xf07a3, fontFamily: 'MaterialIcons');
    const IconData tsunami = IconData(0xf07cf, fontFamily: 'MaterialIcons');

    switch (type.toLowerCase()) {
      case 'flood':
        return flood;
      case 'fire':
        return Icons.local_fire_department;
      case 'earthquake':
        return Icons.terrain;
      case 'landslide':
        return Icons.landslide;
      case 'tsunami':
        return tsunami;
      case 'haze':
        return Icons.air;
      case 'typhoon':
        return Icons.cyclone;
      case 'weather':
        return Icons.thunderstorm;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  /// Builds the scrollable list of alerts
  Widget _buildAlertsList(AppColorTheme colors) {
    // Hardcoded alerts for now, replace with Firebase later
    const List<Alert> alerts = [
      Alert(
        topic: 'Flash Flood Warning',
        description:
            'Heavy rainfall expected in Klang Valley area. Please stay alert and avoid flood-prone areas.',
        severity: 'High',
        location: 'Klang Valley',
        time: '2 hours ago',
        disasterType: 'Flood',
        coordinates: null,
      ),
      Alert(
        topic: 'Earthquake Alert',
        description:
            'Magnitude 5.2 earthquake detected. Stay away from damaged buildings.',
        severity: 'Medium',
        location: 'Sabah',
        time: '4 hours ago',
        disasterType: 'Earthquake',
        coordinates: null,
      ),
      Alert(
        topic: 'Weather Advisory',
        description: 'Strong winds and thunderstorms expected in the evening.',
        severity: 'Low',
        location: 'Kuala Lumpur',
        time: '5 hours ago',
        disasterType: 'Weather',
        coordinates: null,
      ),
    ];

    return SizedBox(
      height: 300,
      child: Scrollbar(
        thickness: 6,
        radius: const Radius.circular(3),
        child: ListView(
          children: alerts
              .map((alert) => _buildAlertCard(
                    topic: alert.topic,
                    description: alert.description,
                    severity: alert.severity,
                    location: alert.location,
                    time: alert.time,
                    disasterType: alert.disasterType,
                    colors: colors,
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// Builds the bottom navigation bar
  Widget _buildBottomNavigation(BuildContext context, AppColorTheme colors) =>
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100,
            border:
                Border(top: BorderSide(color: colors.bg100)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                      Icons.home, true, () {}, colors), // Home is active
                  _buildNavItem(Icons.map_outlined, false,
                      () => _navigateTo(context, const MapScreen()), colors),
                  _buildNavItem(
                      Icons.people_outline,
                      false,
                      () => _navigateTo(context, const CommunityScreen()),
                      colors),
                  _buildNavItem(
                      Icons.person_outline,
                      false,
                      () => _navigateTo(context, const ProfileScreen()),
                      colors),
                ],
              ),
            ),
          ),
        ),
      );

  /// Reusable navigation item widget
  Widget _buildNavItem(
    IconData icon,
    bool isActive,
    VoidCallback onPressed,
    AppColorTheme colors,
  ) =>
      Container(
        decoration: BoxDecoration(
          color:
              isActive ? colors.accent200.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon),
          color: isActive ? colors.accent200 : colors.text200,
          onPressed: onPressed,
          iconSize: 24,
          padding: const EdgeInsets.all(12),
        ),
      );

  /// Navigates to a new screen
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
