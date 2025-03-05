import 'package:flutter/material.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/screens/knowledge_base_screen.dart';
import 'package:flutter/material.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/screens/knowledge_base_screen.dart';
import 'package:mydpar/screens/map_screen.dart';  
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary200, 
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 120, left: 24, right: 24, bottom: 24), // Adjusted padding for fixed header
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  const SizedBox(height: 64),

                  // SOS Button
                  _buildSOSButton(context),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: 24),

                  // Recent Alerts
                  // Replace the Recent Alerts section with this:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Alerts',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary300, // Changed to match the theme
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all alerts
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.accent200,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAlertsList(),
                  const SizedBox(height: 80), // Space for bottom navigation
                  const SizedBox(height: 16),
                  // Remove the entire _buildViewAllButton() method
                  const SizedBox(height: 80), // Space for bottom navigation
                ],
              ),
            ),
            // Fixed welcome header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent200, AppColors.accent100],
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
                    'Hello, Username',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bg100,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to MY_DPAR',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary100,
                    ),
                  ),
                  Text(
                    'Your Disaster Preparedness and Response Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary100,
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: MaterialButton(
              onPressed: () {
                // TODO: Implement SOS functionality
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.bg100, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'SOS Emergency',
                    style: TextStyle(
                      color: AppColors.bg100,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.location_on_outlined,
            label: 'Report Incident',
            onTap: () {
              // TODO: Navigate to incident reporting
            },
          ),
        ),
        const SizedBox(width: 16),
        // In the _buildQuickActions method, update the knowledge base card's onTap:
        Expanded(
          child: _buildActionCard(
            icon: Icons.book_outlined,
            label: 'Knowledge Base',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KnowledgeBaseScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.accent200, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary300,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAlertCard({required String topic, required String description}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic,
                    style: TextStyle(
                      color: AppColors.primary300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.text200,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAlertsList() {
    final List<Map<String, String>> alerts = [
      {
        'topic': 'Flash Flood Warning',
        'description': 'Heavy rainfall expected in Klang Valley area. Please stay alert and avoid flood-prone areas.',
      },
      {
        'topic': 'Earthquake Alert',
        'description': 'Magnitude 5.2 earthquake detected. Stay away from damaged buildings.',
      },
      {
        'topic': 'Weather Advisory',
        'description': 'Strong winds and thunderstorms expected in the evening.',
      },
    ];
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Scrollbar(
        thickness: 6,
        radius: const Radius.circular(3),
        child: SingleChildScrollView(
          child: Column(
            children: alerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAlertCard(
                topic: alert['topic']!,
                description: alert['description']!,
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomNavigation(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg100.withOpacity(0.7),
          border: Border(
            top: BorderSide(color: AppColors.bg100.withOpacity(0.2)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, true, () {}),
                _buildNavItem(Icons.map_outlined, false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );
                }),
                _buildNavItem(Icons.message_outlined, false, () {}),
                _buildNavItem(Icons.person_outline, false, () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent200.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? AppColors.accent200 : AppColors.text200,
        onPressed: onPressed,
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}