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

// Centralized data tailored to Malaysia's earthquake context
const _guideSections = [
  GuideSection(
    title: 'Before an Earthquake',
    cards: [
      GuideCardData(
        icon: Icons.home,
        title: 'Home Preparation',
        items: [
          'Secure heavy furniture to walls',
          'Know where and how to shut off utilities',
          'Keep emergency supplies ready',
          'Identify safe spots in each room',
        ],
      ),
      GuideCardData(
        icon: Icons.map,
        title: 'Emergency Plan',
        items: [
          'Create a family emergency plan',
          'Establish meeting points',
          'Practice earthquake drills',
          'Keep emergency contact numbers handy',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'During an Earthquake',
    cards: [
      GuideCardData(
        icon: Icons.shield,
        title: 'Drop, Cover, Hold On',
        items: [
          'Drop to your hands and knees',
          'Take cover under sturdy furniture',
          'Hold on until shaking stops',
          'Stay away from glass and windows',
        ],
      ),
      GuideCardData(
        icon: Icons.business,
        title: 'If Indoors',
        items: [
          'Stay inside',
          'Stay away from bookcases',
          'Don\'t use elevators',
          'Protect your head and neck',
        ],
      ),
      GuideCardData(
        icon: Icons.park,
        title: 'If Outdoors',
        items: [
          'Move to open area',
          'Stay away from buildings',
          'Avoid power lines',
          'Watch for falling objects',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'After an Earthquake',
    cards: [
      GuideCardData(
        icon: Icons.check_circle_outline,
        title: 'Safety Checks',
        items: [
          'Check for injuries',
          'Look for fire hazards',
          'Check utilities',
          'Listen to emergency broadcasts',
        ],
      ),
      GuideCardData(
        icon: Icons.warning_amber_rounded,
        title: 'Be Prepared For',
        items: [
          'Aftershocks',
          'Building damage',
          'Power outages',
          'Emergency response delays',
        ],
      ),
    ],
  ),
];

// Emergency contacts relevant to earthquake situations in Malaysia
const _emergencyContacts = [
  EmergencyContact(
    label: 'National Disaster Command Center',
    number: '03-8064 2400',
    icon: Icons.emergency,
    description: 'NADMA\'s disaster management center',
  ),
  EmergencyContact(
    label: 'Emergency Response',
    number: '999',
    icon: Icons.local_hospital,
    description: 'Police, ambulance, and fire services',
  ),
];

class EarthquakeGuideScreen extends StatelessWidget {
  const EarthquakeGuideScreen({super.key});

  // Spacing constants
  static const double _padding = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWarningBanner(colors),
                    const SizedBox(height: _spacingMedium),
                    ..._guideSections.map((section) => _buildSection(colors, context, section)),
                    const SizedBox(height: _spacingLarge),
                    _buildEmergencyContactsSection(colors, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header with a back button and title.
  Widget _buildHeader(AppColorTheme colors, BuildContext context) => Container(
        padding: const EdgeInsets.all(_padding),
        decoration: _cardDecoration(colors, opacity: 0.7),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.primary300),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
            const SizedBox(width: _spacingSmall),
            Text(
              'Earthquake Safety',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300),
            ),
          ],
        ),
      );

  /// Builds a warning banner for immediate actions during an earthquake.
  Widget _buildWarningBanner(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: colors.warning,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.bg100),
                const SizedBox(width: _spacingSmall),
                Text(
                  'Earthquake Warning',
                  style: TextStyle(
                      color: colors.bg100,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              'Drop, Cover, and Hold On! Stay away from windows and exterior walls.',
              style: TextStyle(color: colors.bg100),
            ),
          ],
        ),
      );

  /// Builds a section with a title and cards.
  Widget _buildSection(AppColorTheme colors, BuildContext context, GuideSection section) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
            child: Text(
              section.title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary300),
            ),
          ),
          ...section.cards.map((card) => _buildGuideCard(colors, card)),
          const SizedBox(height: _spacingMedium),
        ],
      );

  /// Builds a guide card with an icon, title, and items.
  Widget _buildGuideCard(AppColorTheme colors, GuideCardData card) => Container(
        margin: const EdgeInsets.only(bottom: _spacingMedium),
        padding: const EdgeInsets.all(_padding),
        decoration: _cardDecoration(colors),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(card.icon, color: colors.accent200),
                const SizedBox(width: _spacingMedium),
                Text(
                  card.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: colors.primary300),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            ...card.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: _spacingSmall),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: colors.accent200)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(color: colors.text200),
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
  Widget _buildEmergencyContactsSection(AppColorTheme colors, BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contacts',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.primary300),
          ),
          const SizedBox(height: _spacingMedium),
          ..._emergencyContacts.map((contact) => _buildContactCard(colors, context, contact)),
        ],
      );

  /// Builds a contact card with a phone number and description.
  Widget _buildContactCard(AppColorTheme colors, BuildContext context, EmergencyContact contact) => Container(
        margin: const EdgeInsets.only(bottom: _spacingMedium),
        decoration: _cardDecoration(colors),
        child: ListTile(
          leading: Icon(contact.icon, color: colors.accent200),
          title: Text(
            contact.label,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: colors.primary300),
          ),
          subtitle: Text(
            contact.description,
            style: TextStyle(color: colors.text200, fontSize: 12),
          ),
          trailing: IconButton(
            icon: Icon(Icons.phone, color: colors.accent200),
            onPressed: () => _makePhoneCall(contact.number),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: _padding, vertical: _spacingSmall),
        ),
      );

  /// Makes a phone call to the specified number.
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch $launchUri: $e');
    }
  }

  /// Provides a reusable card decoration with a subtle shadow.
  BoxDecoration _cardDecoration(AppColorTheme colors, {double opacity = 0.85}) =>
      BoxDecoration(
        color: colors.bg100.withOpacity(opacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent200.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}