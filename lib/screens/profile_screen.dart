import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:mydpar/screens/map_screen.dart';
import 'package:mydpar/screens/community_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Model for emergency contact data, Firebase-ready
class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  // Factory for Firebase data parsing (uncomment when integrating)
  // factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
  //   name: json['name'] as String,
  //   relation: json['relation'] as String,
  //   phone: json['phone'] as String,
  // );

  // Convert to JSON for Firebase writes
  Map<String, dynamic> toJson() => {
    'name': name,
    'relation': relation,
    'phone': phone,
  };
}

// Model for settings items
class SettingItem {
  final IconData icon;
  final String title;

  const SettingItem(this.icon, this.title);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme; // Updated type

    return Scaffold(
      backgroundColor: colors.bg200,
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

  /// Builds the header with theme toggle and settings icon
  Widget _buildHeader(
      BuildContext context,
      ThemeProvider themeProvider,
      AppColorTheme colors,
      ) =>
      Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: _paddingValue, vertical: _spacingSmall),
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

  /// Builds the scrollable content area
  Widget _buildContent(BuildContext context, AppColorTheme colors) => Expanded(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(_paddingValue),
      child: Column(
        children: [
          _buildProfileHeader(colors),
          const SizedBox(height: _spacingLarge * 2), // 32px
          _buildEmergencyContactsSection(context, colors),
          const SizedBox(height: _spacingLarge * 2), // 32px
          _buildSettingsSection(context, colors),
        ],
      ),
    ),
  );

  /// Builds the profile header with avatar, name, and email
  Widget _buildProfileHeader(AppColorTheme colors) => Column(
    children: [
      Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: colors.primary100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_outline, size: 48, color: colors.accent200),
      ),
      const SizedBox(height: _spacingLarge),
      Text(
        'Username', // TODO: Replace with Firebase Auth user name
        style: TextStyle(
          color: colors.primary300,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        'email@example.com', // TODO: Replace with Firebase Auth email
        style: TextStyle(color: colors.text200),
      ),
    ],
  );

  /// Builds the emergency contacts section with a scrollable list
  Widget _buildEmergencyContactsSection(
      BuildContext context,
      AppColorTheme colors,
      ) {
    // Hardcoded contacts for now, replace with Firebase later
    const List<EmergencyContact> contacts = [
      EmergencyContact(name: 'Khoo JC', relation: 'Relationship', phone: '+60 12-756 1683'),
      EmergencyContact(name: 'Name 2', relation: 'Relationship', phone: '+1 234-567-8902'),
      EmergencyContact(name: 'Name 3', relation: 'Relationship', phone: '+1 234-567-8903'),
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
        const SizedBox(height: _spacingLarge),
        SizedBox(
          height: 200,
          child: Scrollbar(
            thickness: 6,
            radius: const Radius.circular(8),
            child: ListView(
              children: contacts
                  .map((contact) => Padding(
                padding: const EdgeInsets.only(bottom: _spacingMedium),
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

  /// Builds an individual emergency contact card
  Widget _buildEmergencyContact(
      BuildContext context,
      String name,
      String relation,
      String phone,
      AppColorTheme colors,
      ) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(_paddingValue),
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
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
                Text(
                  phone,
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.phone, color: colors.accent200),
                  onPressed: () => _launchPhoneCall(context, phone, colors),
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

  /// Builds the settings section with a list of options
  Widget _buildSettingsSection(BuildContext context, AppColorTheme colors) {
    const List<SettingItem> settings = [
      SettingItem(Icons.shield_outlined, 'Privacy'),
      SettingItem(Icons.help_outline, 'Help & Support'),
    ];

    return Column(
      children: settings
          .map((setting) => Padding(
        padding: const EdgeInsets.only(bottom: _spacingMedium),
        child: _buildSettingItem(context, setting.icon, setting.title, colors),
      ))
          .toList(),
    );
  }

  /// Builds an individual setting item
  Widget _buildSettingItem(
      BuildContext context,
      IconData icon,
      String title,
      AppColorTheme colors,
      ) =>
      GestureDetector(
        onTap: () {
          // TODO: Navigate to respective setting screen
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.bg100.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(_paddingValue),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: colors.accent200),
                  const SizedBox(width: _spacingMedium),
                  Text(
                    title,
                    style: TextStyle(color: colors.primary300),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, color: colors.text200),
            ],
          ),
        ),
      );

  /// Builds the bottom navigation bar
  Widget _buildBottomNavigation(BuildContext context, AppColorTheme colors) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border: Border(top: BorderSide(color: colors.bg100.withOpacity(0.2))),
        ),
        padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.home_outlined,
              false,
                  () => _navigateTo(context, const HomeScreen(), replace: true),
              colors,
            ),
            _buildNavItem(
              Icons.map_outlined,
              false,
                  () => _navigateTo(context, const MapScreen(), replace: true),
              colors,
            ),
            _buildNavItem(
              Icons.people_outline,
              false,
                  () => _navigateTo(context, const CommunityScreen()),
              colors,
            ),
            _buildNavItem(
              Icons.person,
              true, // Profile is active
                  () {},
              colors,
            ),
          ],
        ),
      );

  /// Reusable navigation item widget
  Widget _buildNavItem(
      IconData icon,
      bool isActive,
      VoidCallback onPressed,
      AppColorTheme colors,
      ) =>
      IconButton(
        icon: Icon(icon),
        color: isActive ? colors.accent200 : colors.text200,
        onPressed: onPressed,
      );

  /// Launches a phone call with error handling
  Future<void> _launchPhoneCall(
      BuildContext context,
      String phone,
      AppColorTheme colors,
      ) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch phone call'),
            backgroundColor: colors.warning,
          ),
        );
      }
    }
  }

  /// Navigates to a new screen, optionally replacing the current one
  void _navigateTo(BuildContext context, Widget screen, {bool replace = false}) {
    if (replace) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }
}