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

// Centralized data tailored to Malaysia's haze context
const _guideSections = [
  GuideSection(
    title: 'Before Haze',
    cards: [
      GuideCardData(
        icon: Icons.checklist_rounded,
        title: 'Preparation',
        items: [
          'Stock N95 masks (not surgical masks) for all family members',
          'Seal windows and doors with tape or damp cloths',
          'Prepare air purifiers or fans with wet filters',
          'Plan to stay with relatives if haze worsens',
        ],
      ),
      GuideCardData(
        icon: Icons.favorite,
        title: 'Health Check',
        items: [
          'Visit a clinic if you have asthma or allergies',
          'Stock up on inhalers or medications',
          'Know your nearest klinik kesihatan or hospital',
          'Check API via DOE website or APIMS app',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'During Haze',
    cards: [
      GuideCardData(
        icon: Icons.shield,
        title: 'Protection Measures',
        items: [
          'Stay indoors when API exceeds 100',
          'Wear N95 masks properly if outdoors',
          'Limit outdoor activities, especially for kids',
          'Drink water frequently to stay hydrated',
        ],
      ),
      GuideCardData(
        icon: Icons.warning_amber_rounded,
        title: 'Health Warning Signs',
        items: [
          'Coughing or throat irritation',
          'Difficulty breathing or wheezing',
          'Eye redness or itchiness',
          'Headaches or dizziness',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'API Levels Guide',
    cards: [
      GuideCardData(
        icon: Icons.show_chart,
        title: 'Activity Guidelines',
        items: [
          '0-50: Safe for all activities',
          '51-100: Moderate; limit outdoor exertion',
          '101-200: Unhealthy; stay indoors if possible',
          '>200: Very unhealthy; avoid all outdoor exposure',
        ],
      ),
      GuideCardData(
        icon: Icons.groups,
        title: 'At-Risk Groups',
        items: [
          'Children and elderly (warga emas)',
          'Pregnant women',
          'Those with asthma or lung issues',
          'Heart disease patients',
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
    description: 'Nationwide Emergency Services (24/7)',
  ),
  EmergencyContact(
    label: 'DOE Hotline',
    number: '1-800-88-2727',
    icon: Icons.support_agent,
    description: 'Department of Environment Hotline',
  ),
  EmergencyContact(
    label: 'Fire & Rescue (Bomba)',
    number: '994',
    icon: Icons.fire_truck,
    description: 'Fire Department Emergency',
  ),
];

class HazeGuideScreen extends StatelessWidget {
  const HazeGuideScreen({super.key});

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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_padding, 70, _padding, _padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _spacingLarge),
                  _buildWarningBanner(colors),
                  const SizedBox(height: _spacingLarge),
                  ..._guideSections.map((section) => _buildSection(colors, section)),
                  const SizedBox(height: _spacingLarge),
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
    padding: const EdgeInsets.all(_padding),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: _spacingSmall),
        Text(
          'Haze Safety Guide',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
        ),
      ],
    ),
  );

  /// Builds a warning banner with a Malaysia-specific haze message.
  Widget _buildWarningBanner(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.warning,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(_padding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.bg100),
            const SizedBox(width: _spacingSmall),
            Text(
              'Haze Warning',
              style: TextStyle(color: colors.bg100, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: _spacingSmall),
        Text(
          'API > 100 is unhealthy—stay indoors and wear N95 masks if you must go out!',
          style: TextStyle(color: colors.bg100, fontSize: 14),
        ),
      ],
    ),
  );

  /// Builds a section with a title and guide cards.
  Widget _buildSection(AppColorTheme colors, GuideSection section) => Padding(
    padding: const EdgeInsets.only(bottom: _padding),
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

  /// Builds a guide card with an icon, title, and list of items.
  Widget _buildGuideCard(AppColorTheme colors, GuideCardData card) => Container(
    margin: const EdgeInsets.only(bottom: _spacingMedium),
    decoration: _cardDecoration(colors),
    padding: const EdgeInsets.all(_padding),
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
    padding: const EdgeInsets.all(_padding),
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

  /// Builds a tappable emergency contact item.
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
          padding: const EdgeInsets.all(_padding),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  /// Launches the phone dialer and handles errors.
  Future<void> _launchPhone(BuildContext context, String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar(context, 'Could not dial $number', Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar(context, 'Error dialing $number: $e', Colors.redAccent);
    }
  }

  /// Displays a snackbar with a custom message and color.
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_padding),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Provides a reusable card decoration with a subtle shadow.
  BoxDecoration _cardDecoration(AppColorTheme colors, {double opacity = 0.7}) => BoxDecoration(
    color: colors.bg100.withOpacity(opacity),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colors.bg300.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}