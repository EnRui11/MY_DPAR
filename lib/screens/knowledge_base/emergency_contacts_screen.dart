import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

// Model for emergency contact data, Firebase-ready
class EmergencyContact {
  final String title;
  final String subtitle;
  final String phoneNumber;
  final String? website;
  final IconData icon;

  const EmergencyContact({
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
    this.website,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'phoneNumber': phoneNumber,
        'website': website,
        'icon': icon.codePoint,
      };
}

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 32.0;

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colors),
            Expanded(child: _buildContent(context, colors)),
          ],
        ),
      ),
    );
  }

  /// Builds the header with back button and title
  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border:
              Border.all(color: colors.bg300.withOpacity(0.2)), // Fixed Border
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _paddingValue,
          vertical: _paddingValue - 8,
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.primary300),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: _spacingSmall),
            Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
      );

  /// Builds the scrollable content area
  Widget _buildContent(BuildContext context, AppColorTheme colors) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Emergency Numbers', colors),
            const SizedBox(height: _spacingMedium),
            _buildEmergencyButton(
              context: context,
              number: '999',
              label: 'National Emergency',
              color: colors.warning,
              isPulsing: true,
            ),
            const SizedBox(height: _spacingMedium),
            _buildEmergencyButton(
              context: context,
              number: '112',
              label: 'Alternative Emergency',
              color: colors.accent100,
              isPulsing: false,
            ),
            const SizedBox(height: _spacingLarge),
            _buildSectionTitle('Disaster Response', colors),
            const SizedBox(height: _spacingMedium),
            _buildAgencyCard(
              context: context,
              contact: const EmergencyContact(
                title: 'NADMA',
                subtitle: 'National Disaster Management',
                phoneNumber: '+603 8870 4800',
                website: 'https://www.nadma.gov.my/bi/',
                icon: Icons.business,
              ),
              colors: colors,
            ),
            const SizedBox(height: _spacingMedium),
            _buildAgencyCard(
              context: context,
              contact: const EmergencyContact(
                title: 'MetMalaysia',
                subtitle: 'Meteorological Department',
                phoneNumber: '+603 7967 8000',
                website: 'https://www.met.gov.my/?lang=en',
                icon: Icons.cloud,
              ),
              colors: colors,
            ),
          ],
        ),
      );

  /// Builds a section title
  Widget _buildSectionTitle(String title, AppColorTheme colors) => Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.primary300,
        ),
      );

  /// Builds an emergency button with optional pulsing animation
  Widget _buildEmergencyButton({
    required BuildContext context,
    required String number,
    required String label,
    required Color color,
    required bool isPulsing,
  }) {
    final AppColorTheme colors =
        Provider.of<ThemeProvider>(context).currentTheme;
    return GestureDetector(
      onTap: () => _makePhoneCall(context, number),
      child: Container(
        padding: const EdgeInsets.all(_spacingMedium),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(_spacingMedium),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.phone,
                  color: colors.text200, size: 32), // Adjusted color
            ),
            const SizedBox(width: _spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: TextStyle(
                      color: colors.text200, // Adjusted color
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.text200.withOpacity(0.9), // Adjusted color
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(_spacingSmall),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.phone_in_talk,
                  color: colors.text200), // Adjusted color
            ),
          ],
        ),
      ).animate(
        onPlay: (controller) =>
            isPulsing ? controller.repeat(reverse: true) : null,
        effects: [
          if (isPulsing)
            ScaleEffect(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
            ),
        ],
      ),
    );
  }

  /// Builds an agency card with phone and website actions
  Widget _buildAgencyCard({
    required BuildContext context,
    required EmergencyContact contact,
    required AppColorTheme colors,
  }) =>
      Container(
        padding: const EdgeInsets.all(_spacingMedium),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(_spacingMedium),
              decoration: BoxDecoration(
                color: colors.accent100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(contact.icon,
                  color: Colors.white), // Kept white for contrast
            ),
            const SizedBox(width: _spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.title,
                    style: TextStyle(
                      color: colors.primary300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    contact.subtitle,
                    style: TextStyle(color: colors.text200, fontSize: 14),
                  ),
                  const SizedBox(height: _spacingSmall),
                  Text(
                    contact.phoneNumber,
                    style: TextStyle(
                      color: colors.accent200,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _buildActionButton(
                  context: context, // Added context parameter
                  icon: Icons.phone,
                  color: colors.accent200,
                  onTap: () => _makePhoneCall(context, contact.phoneNumber),
                ),
                if (contact.website != null) ...[
                  const SizedBox(height: _spacingSmall),
                  _buildActionButton(
                    context: context, // Added context parameter
                    icon: Icons.launch,
                    color: colors.accent100,
                    onTap: () => _launchURL(context, contact.website!),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  /// Builds an action button for phone or website
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(_spacingSmall),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: Colors.white, size: 20), // Kept white for contrast
      ),
    );
  }

  /// Initiates a phone call with error handling
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar(context, 'Could not launch phone call', Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, 'Failed to make call: $e', Colors.red);
    }
  }

  /// Launches a URL with error handling
  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(context, 'Could not launch URL', Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, 'Failed to launch URL: $e', Colors.red);
    }
  }

  /// Displays a snackbar with a message
  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
