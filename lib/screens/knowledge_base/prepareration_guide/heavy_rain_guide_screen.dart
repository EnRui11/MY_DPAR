import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Data model for guide sections
class GuideSection {
  final String title;
  final List<GuideCardData> cards;

  const GuideSection({required this.title, required this.cards});
}

// Data model for guide cards
class GuideCardData {
  final IconData icon;
  final String title;
  final List<String> items;

  const GuideCardData({required this.icon, required this.title, required this.items});
}

// Data model for emergency contacts
class EmergencyContact {
  final String label;
  final String number;
  final IconData icon;
  final String description;

  const EmergencyContact({required this.label, required this.number, required this.icon, required this.description});
}

// Centralized data
const _guideSections = [
  GuideSection(
    title: 'Before Heavy Rain',
    cards: [
      GuideCardData(
        icon: Icons.home,
        title: 'Home Preparation',
        items: [
          'Clear drains, gutters, and canals around your home',
          'Secure outdoor items (e.g., furniture, potted plants)',
          'Use sandbags to divert water if in a flood-prone area',
          'Elevate valuables and appliances above flood levels',
        ],
      ),
      GuideCardData(
        icon: Icons.radio,
        title: 'Stay Informed',
        items: [
          'Monitor updates from MET Malaysia (www.met.gov.my)',
          'Sign up for NADMA alerts or local authority updates',
          'Know your area’s flood history and risk level',
          'Plan evacuation routes with your family',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'During Heavy Rain',
    cards: [
      GuideCardData(
        icon: Icons.shield_outlined,
        title: 'Indoor Safety',
        items: [
          'Stay indoors away from windows during lightning',
          'Unplug electrical devices during thunderstorms',
          'Avoid using running water (e.g., showers) during lightning',
          'Monitor water levels if near rivers or low areas',
        ],
      ),
      GuideCardData(
        icon: Icons.directions_car,
        title: 'If Outside',
        items: [
          'Never drive through flooded roads—6 inches of water can sweep a car',
          'Avoid walking in floodwater—it may hide hazards',
          'Stay away from trees and poles during lightning',
          'Seek higher ground if flooding starts',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'After Heavy Rain',
    cards: [
      GuideCardData(
        icon: Icons.check_circle_outline,
        title: 'Safety Checks',
        items: [
          'Inspect your home for flood or structural damage',
          'Report downed power lines to TNB (15454)',
          'Photograph damage for insurance claims',
          'Follow NADMA or local authority updates',
        ],
      ),
      GuideCardData(
        icon: Icons.favorite_border,
        title: 'Recovery',
        items: [
          'Avoid floodwater—it may carry diseases or debris',
          'Check water supply safety before drinking',
          'Assist neighbors, especially the elderly or disabled',
          'Clean and dry your home to prevent mold',
        ],
      ),
    ],
  ),
];

const _emergencyContacts = [
  EmergencyContact(
    label: 'Emergency (Police/Ambulance)',
    number: '999',
    icon: Icons.local_hospital,
    description: 'Nationwide Emergency Services',
  ),
  EmergencyContact(
    label: 'Fire & Rescue',
    number: '994',
    icon: Icons.fire_truck,
    description: 'Fire Department Emergency',
  ),
  EmergencyContact(
    label: 'Civil Defence (APM)',
    number: '991',
    icon: Icons.security,
    description: 'Civil Defence Force Malaysia',
  ),
  EmergencyContact(
    label: 'NADMA Hotline',
    number: '03-80642400',
    icon: Icons.support_agent,
    description: 'National Disaster Management Agency',
  ),
  EmergencyContact(
    label: 'Tenaga Nasional (Power)',
    number: '15454',
    icon: Icons.electrical_services,
    description: 'Report Power Outages',
  ),
];

class HeavyRainGuideScreen extends StatelessWidget {
  const HeavyRainGuideScreen({super.key});

  // Constants for consistent spacing
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_paddingValue, 70, _paddingValue, _paddingValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _spacingLarge),
                  _buildWarningBanner(colors),
                  const SizedBox(height: _spacingLarge),
                  ..._guideSections.map((section) => _buildSection(colors, section)),
                  _buildEmergencyContacts(colors, context),
                ],
              ),
            ),
            _buildHeader(context, colors),
          ],
        ),
      ),
    );
  }

  /// Builds the header with a back button and title.
  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Container(
    decoration: _cardDecoration(colors, opacity: 0.7),
    padding: const EdgeInsets.all(_paddingValue),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: _spacingSmall),
        Text(
          'Heavy Rain Safety Guide',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
        ),
      ],
    ),
  );

  /// Builds the warning banner with a critical safety message.
  Widget _buildWarningBanner(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.warning,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.bg100),
            const SizedBox(width: _spacingSmall),
            Text(
              'Safety Alert',
              style: TextStyle(color: colors.bg100, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: _spacingSmall),
        Text(
          'Heavy rain can lead to flash floods in minutes. If you hear thunder or see rising water, seek safety immediately!',
          style: TextStyle(color: colors.bg100, fontSize: 14),
        ),
      ],
    ),
  );

  /// Builds a section containing multiple guide cards.
  Widget _buildSection(AppColorTheme colors, GuideSection section) => Padding(
    padding: const EdgeInsets.only(bottom: _paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary300),
        ),
        const SizedBox(height: _spacingMedium),
        ...section.cards.map((card) => _buildGuideCard(colors, card)),
      ],
    ),
  );

  /// Builds a single guide card with an icon, title, and list of items.
  Widget _buildGuideCard(AppColorTheme colors, GuideCardData card) => Container(
    margin: const EdgeInsets.only(bottom: _spacingMedium),
    decoration: _cardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(card.icon, color: colors.accent200, size: 20),
            const SizedBox(width: _spacingSmall),
            Text(
              card.title,
              style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary300),
            ),
          ],
        ),
        const SizedBox(height: _spacingSmall),
        ...card.items.map(
              (item) => Padding(
            padding: const EdgeInsets.only(bottom: _spacingSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: colors.text200)),
                Expanded(
                  child: Semantics(
                    label: item,
                    child: Text(
                      item,
                      style: TextStyle(color: colors.text200, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  /// Builds the emergency contacts section.
  Widget _buildEmergencyContacts(AppColorTheme colors, BuildContext context) => Container(
    decoration: _cardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emergency, color: colors.accent200, size: 24),
            const SizedBox(width: _spacingSmall),
            Text(
              'Emergency Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
            ),
          ],
        ),
        const SizedBox(height: _spacingMedium),
        ..._emergencyContacts.map((contact) => _buildContactItem(colors, context, contact)),
      ],
    ),
  );

  /// Builds a single emergency contact item with a tappable phone number.
  Widget _buildContactItem(AppColorTheme colors, BuildContext context, EmergencyContact contact) => Container(
    margin: const EdgeInsets.only(bottom: _spacingMedium),
    decoration: BoxDecoration(
      color: colors.bg200,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: colors.bg300.withOpacity(0.2)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _launchPhone(context, contact.number),
        child: Padding(
          padding: const EdgeInsets.all(_paddingValue),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accent200.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(contact.icon, color: colors.accent200, size: 24),
              ),
              const SizedBox(width: _spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.label,
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary300, fontSize: 16),
                    ),
                    Text(
                      contact.description,
                      style: TextStyle(color: colors.text200, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accent200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.call, color: colors.bg100, size: 20),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Launches the phone dialer with the given number, showing an error if it fails.
  Future<void> _launchPhone(BuildContext context, String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar(context, 'Could not dial $number');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error dialing $number: $e');
    }
  }

  /// Displays an error snackbar with the given message.
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_paddingValue),
      ),
    );
  }

  /// Reusable card decoration with customizable opacity.
  BoxDecoration _cardDecoration(AppColorTheme colors, {double opacity = 0.7}) => BoxDecoration(
    color: colors.bg100.withOpacity(opacity),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colors.bg300.withOpacity(0.2)),
  );
}
