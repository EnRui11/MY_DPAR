import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:mydpar/screens/community_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.primary200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, themeProvider, colors),
            _buildContent(context, colors),
            _buildBottomNavigation(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeProvider themeProvider, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: colors.accent200,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: colors.primary300),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic colors) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(colors),
            const SizedBox(height: 32),
            _buildEmergencyContactsSection(context, colors),
            const SizedBox(height: 32),
            _buildSettingsSection(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic colors) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration:
              BoxDecoration(color: colors.primary100, shape: BoxShape.circle),
          child: Icon(Icons.person_outline, size: 48, color: colors.accent200),
        ),
        const SizedBox(height: 16),
        Text(
          'Username', // TODO: Replace with actual username
          style: TextStyle(
              color: colors.primary300,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        Text(
          'email@example.com', // TODO: Replace with actual email
          style: TextStyle(color: colors.text200),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactsSection(BuildContext context, dynamic colors) {
    const contacts = [
      ContactItem('Name 1', 'Relationship', '+1 234-567-8901'),
      ContactItem('Name 2', 'Relationship', '+1 234-567-8902'),
      ContactItem('Name 3', 'Relationship', '+1 234-567-8903'),
    ];

    return Column(
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
                  fontWeight: FontWeight.w600),
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
              children: contacts
                  .map((contact) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEmergencyContact(
                          context,
                          contact.name,
                          contact.relation,
                          contact.phone,
                          colors,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContact(
    BuildContext context,
    String name,
    String relation,
    String phone,
    dynamic colors,
  ) {
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
              Text(name,
                  style: TextStyle(
                      color: colors.primary300, fontWeight: FontWeight.w500)),
              Text(relation,
                  style: TextStyle(color: colors.text200, fontSize: 14)),
              Text(phone,
                  style: TextStyle(color: colors.text200, fontSize: 14)),
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

  Widget _buildSettingsSection(BuildContext context, dynamic colors) {
    const settings = [
      SettingItem(Icons.shield_outlined, 'Privacy'),
      SettingItem(Icons.help_outline, 'Help & Support'),
    ];

    return Column(
      children: settings
          .map((setting) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSettingItem(
                    context, setting.icon, setting.title, colors),
              ))
          .toList(),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, IconData icon, String title, dynamic colors) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to respective setting screen
      },
      child: Container(
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
                Text(title, style: TextStyle(color: colors.primary300)),
              ],
            ),
            Icon(Icons.chevron_right, color: colors.text200),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border(top: BorderSide(color: colors.bg100.withOpacity(0.2))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              Icons.home_outlined,
              false,
              () => _navigateTo(context, const HomeScreen(), replace: true),
              colors),
          _buildNavItem(
              Icons.map_outlined,
              false,
              () => _navigateTo(context, const MapScreen(), replace: true),
              colors),
          _buildNavItem(Icons.people_outline, false,
              () => _navigateTo(context, const CommunityScreen()), colors),
          _buildNavItem(Icons.person, true, () {}, colors),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, bool isActive, VoidCallback onPressed, dynamic colors) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? colors.accent200 : colors.text200,
      onPressed: onPressed,
    );
  }

  void _navigateTo(BuildContext context, Widget screen,
      {bool replace = false}) {
    if (replace) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }
}

class SettingItem {
  final IconData icon;
  final String title;

  const SettingItem(this.icon, this.title);
}

class ContactItem {
  final String name;
  final String relation;
  final String phone;

  const ContactItem(this.name, this.relation, this.phone);
}
