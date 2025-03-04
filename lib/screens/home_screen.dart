import 'package:flutter/material.dart';
import 'package:mydpar/theme/color_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Hello, Username',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to MY_DPAR',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text200,
                    ),
                  ),
                  Text(
                    'Your Disaster Preparedness and Response Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text200,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SOS Button
                  _buildSOSButton(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Recent Alerts
                  Text(
                    'Recent Alerts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAlertsList(),
                  const SizedBox(height: 16),
                  _buildViewAllButton(),
                  const SizedBox(height: 80), // Space for bottom navigation
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Container(
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
    );
  }

  Widget _buildQuickActions() {
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
        Expanded(
          child: _buildActionCard(
            icon: Icons.book_outlined,
            label: 'Knowledge Base',
            onTap: () {
              // TODO: Navigate to knowledge base
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
              Icon(icon, color: AppColors.accent200, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.text200,
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

  Widget _buildAlertsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAlertCard(
                topic: 'Alert Topic',
                description: 'Description',
              ),
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Text(
                  topic,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    );
  }

  Widget _buildViewAllButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
      ),
      child: MaterialButton(
        onPressed: () {
          // TODO: Navigate to all alerts
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View All Alerts',
              style: TextStyle(
                color: AppColors.accent200,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.accent200),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
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
                _buildNavItem(Icons.home, true),
                _buildNavItem(Icons.map_outlined, false),
                _buildNavItem(Icons.message_outlined, false),
                _buildNavItem(Icons.person_outline, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? AppColors.accent200 : AppColors.text200,
      onPressed: () {
        // TODO: Implement navigation
      },
    );
  }
}