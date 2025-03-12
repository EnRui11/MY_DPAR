import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/profile_screen.dart';
import 'package:mydpar/screens/knowledge_base_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/report_incident_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.primary200,
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

  // Extracted header widget for better organization
  Widget _buildHeader(dynamic colors) {
    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hello, Username', // TODO: Replace with actual username
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.bg100,
            ),
          ),
          const SizedBox(height: 8),
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
  }

  // Extracted scrollable content
  Widget _buildContent(BuildContext context, dynamic colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 64),
          _buildSOSButton(context, colors),
          const SizedBox(height: 24),
          _buildQuickActions(context, colors),
          const SizedBox(height: 24),
          _buildRecentAlertsSection(context, colors),
          const SizedBox(height: 80), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, dynamic colors) {
    return TweenAnimationBuilder<double>(
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
            onPressed: () {
              // TODO: Implement SOS functionality
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: colors.bg100, size: 24),
                const SizedBox(width: 8),
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
  }

  Widget _buildQuickActions(BuildContext context, dynamic colors) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.location_on_outlined,
            label: 'Report Incident',
            colors: colors,
            onTap: () => _navigateTo(context, const ReportIncidentScreen()),
          ),
        ),
        const SizedBox(width: 16),
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
  }

  // Helper method for navigation
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required dynamic colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(16),
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
  }

  Widget _buildRecentAlertsSection(BuildContext context, dynamic colors) {
    return Column(
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
              onPressed: () {
                // TODO: Navigate to all alerts
              },
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
        const SizedBox(height: 16),
        _buildAlertsList(colors),
      ],
    );
  }

  Widget _buildAlertCard({
    required String topic,
    required String description,
    required dynamic colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: TextStyle(
                    color: colors.primary300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(dynamic colors) {
    const alerts = [
      {
        'topic': 'Flash Flood Warning',
        'description':
            'Heavy rainfall expected in Klang Valley area. Please stay alert and avoid flood-prone areas.',
      },
      {
        'topic': 'Earthquake Alert',
        'description':
            'Magnitude 5.2 earthquake detected. Stay away from damaged buildings.',
      },
      {
        'topic': 'Weather Advisory',
        'description':
            'Strong winds and thunderstorms expected in the evening.',
      },
    ];

    return SizedBox(
      height: 300,
      child: Scrollbar(
        thickness: 6,
        radius: const Radius.circular(3),
        child: ListView(
          children: alerts
              .map((alert) => _buildAlertCard(
                    topic: alert['topic']!,
                    description: alert['description']!,
                    colors: colors,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, dynamic colors) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border: Border(top: BorderSide(color: colors.bg100.withOpacity(0.2))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, true, () {}, colors),
                _buildNavItem(Icons.map_outlined, false,
                    () => _navigateTo(context, const MapScreen()), colors),
                _buildNavItem(Icons.message_outlined, false, () {}, colors),
                _buildNavItem(Icons.person_outline, false,
                    () => _navigateTo(context, const ProfileScreen()), colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    bool isActive,
    VoidCallback onPressed,
    dynamic colors,
  ) {
    return Container(
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
  }
}
