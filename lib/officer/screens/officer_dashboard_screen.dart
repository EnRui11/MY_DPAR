import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/officer/widgets/officer_nav_bar.dart';
import 'package:mydpar/services/sos_alert_service.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  static const double _padding = 16.0;
  static const double _spacing = 24.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors),
                const SizedBox(height: _spacing),
                _buildSOSSection(colors),
                const SizedBox(height: _spacing),
                _buildDisasterReportsSection(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Officer',
            style: TextStyle(
              color: colors.primary300,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Disaster Response Control Center',
            style: TextStyle(
              color: colors.text200,
              fontSize: 16,
            ),
          ),
        ],
      );

  Widget _buildSOSSection(AppColorTheme colors) {
    final sosService = Provider.of<SOSAlertService>(context);
    final alerts = sosService.activeAlerts;
    final bool hasActiveAlerts = alerts.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasActiveAlerts
              ? [
                  const Color(0xFFFF3D3D),
                  const Color(0xFFFF8080),
                ]
              : [
                  const Color(0xFF4CAF50),
                  const Color(0xFF81C784),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      hasActiveAlerts
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      key: ValueKey<bool>(hasActiveAlerts),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Active SOS',
                    style: TextStyle(
                      color: colors.bg100,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '${sosService.activeAlertsCount}',
                  key: ValueKey<int>(sosService.activeAlertsCount),
                  style: TextStyle(
                    color: colors.bg100,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
              );
            },
            child: alerts.isEmpty
                ? Container(
                    key: const ValueKey<bool>(false),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: colors.bg100,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Active SOS Emergencies',
                          style: TextStyle(
                            color: colors.bg100,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The situation is currently under control',
                          style: TextStyle(
                            color: colors.bg100.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: const ValueKey<bool>(true),
                    children: [
                      ...alerts.take(2).map((alert) => Column(
                            children: [
                              _buildSOSCard(
                                alert['emergencyType'] ?? 'Emergency',
                                alert['address'] ?? 'Location unavailable',
                                _formatTimestamp(alert['alertStartTime']),
                                colors,
                                alert,
                              ),
                              const SizedBox(height: 12),
                            ],
                          )),
                      if (alerts.length > 2)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+${alerts.length - 2} more emergencies',
                                style: TextStyle(
                                  color: colors.bg100,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement view all SOS screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.bg100,
                foregroundColor: hasActiveAlerts
                    ? const Color(0xFFFF3D3D)
                    : const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View All SOS'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildSOSCard(
    String title,
    String location,
    String time,
    AppColorTheme colors,
    Map<String, dynamic> alert,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: colors.bg100,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alert['username'] ?? 'Unknown User',
                      style: TextStyle(
                        color: colors.bg100,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: colors.bg100.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              location,
              style: TextStyle(
                color: colors.bg100.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );

  Widget _buildDisasterReportsSection(AppColorTheme colors) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disaster Reports',
                style: TextStyle(
                  color: colors.primary300,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(color: colors.accent200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDisasterCard(
            'Flash Flood',
            'Jalan Meru, Klang',
            '5 minutes ago',
            Icons.water_drop,
            'High',
            const Color(0xFFFF3D3D),
            colors,
          ),
          const SizedBox(height: 12),
          _buildDisasterCard(
            'Landslide',
            'Bukit Antarabangsa',
            '15 minutes ago',
            Icons.landscape,
            'Medium',
            const Color(0xFFFF8C00),
            colors,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add New Disaster Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildDisasterCard(
    String title,
    String location,
    String time,
    IconData icon,
    String severity,
    Color severityColor,
    AppColorTheme colors,
  ) =>
      Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: severityColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.primary300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location,
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(
                      color: colors.text200.withOpacity(0.7), fontSize: 12),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View Details →',
                    style: TextStyle(
                      color: colors.accent200,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // Replace the _buildBottomNavigation method with:
  Widget _buildBottomNavigation(AppColorTheme colors) => const OfficerNavBar();
}
