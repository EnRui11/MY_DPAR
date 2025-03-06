import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildEmergencyContact(
      BuildContext context, String name, String relation, String phone) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: colors.primary300,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                relation,
                style: TextStyle(
                  color: colors.text200,
                  fontSize: 14,
                ),
              ),
              Text(
                phone,
                style: TextStyle(
                  color: colors.text200,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.phone, color: colors.accent200),
                onPressed: () {
                  // TODO: Implement phone call functionality
                },
              ),
              IconButton(
                icon: Icon(Icons.edit, color: colors.accent200),
                onPressed: () {
                  // TODO: Implement edit contact functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accent200),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(color: colors.primary300),
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: colors.text200),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.primary200,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Theme Switch and Settings buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: colors.accent200,
                    ),
                    onPressed: () {
                      themeProvider
                          .toggleTheme(); // Switch theme and notify listeners
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: colors.primary300),
                    onPressed: () {
                      // TODO: Navigate to settings screen
                    },
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Header
                    Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: colors.primary100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 48,
                            color: colors.accent200,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Username', // TODO: Replace with actual username
                          style: TextStyle(
                            color: colors.primary300,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'email@example.com', // TODO: Replace with actual email
                          style: TextStyle(color: colors.text200),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Emergency Contacts
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Emergency Contacts',
                              style: TextStyle(
                                color: colors.primary300,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: colors.accent200),
                              onPressed: () {
                                // TODO: Implement add contact functionality
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: Scrollbar(
                            thickness: 6,
                            radius: const Radius.circular(8),
                            child: ListView(
                              children: [
                                _buildEmergencyContact(context, 'Name 1',
                                    'Relationship', '+1 234-567-8901'),
                                const SizedBox(height: 12),
                                _buildEmergencyContact(context, 'Name 2',
                                    'Relationship', '+1 234-567-8902'),
                                const SizedBox(height: 12),
                                _buildEmergencyContact(context, 'Name 3',
                                    'Relationship', '+1 234-567-8903'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Settings
                    Column(
                      children: [
                        _buildSettingItem(
                            context, Icons.shield_outlined, 'Privacy'),
                        const SizedBox(height: 12),
                        _buildSettingItem(
                            context, Icons.help_outline, 'Help & Support'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.7),
                border: Border(
                    top: BorderSide(color: colors.bg100.withOpacity(0.2))),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.home_outlined, color: colors.text200),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.map_outlined, color: colors.text200),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MapScreen()),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.message_outlined, color: colors.text200),
                      onPressed: () {
                        // TODO: Implement messaging functionality
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.person, color: colors.accent200),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
