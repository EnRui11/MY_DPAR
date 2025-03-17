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

// Centralized data tailored to Malaysia's fire safety context
const _guideSections = [
  GuideSection(
    title: 'Before a Fire',
    cards: [
      GuideCardData(
        icon: Icons.checklist_rounded,
        title: 'Prevention',
        items: [
          'Install smoke detectors in every room and test monthly',
          'Keep cooking areas clear of flammable items (e.g., kain, oil)',
          'Avoid overloading power strips or extension cords',
          'Store petrol and gas cylinders securely outside',
        ],
      ),
      GuideCardData(
        icon: Icons.route,
        title: 'Escape Plan',
        items: [
          'Plan and practice two escape routes per room',
          'Ensure windows and grilles can be opened quickly',
          'Set a meeting point (e.g., outside surau or neighbor’s house)',
          'Teach children to call 999 or 994 in emergencies',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'During a Fire',
    cards: [
      GuideCardData(
        icon: Icons.shield,
        title: 'Immediate Actions',
        items: [
          'Shout "Api!" to alert everyone and evacuate fast',
          'Stay low to avoid thick smoke—crawl if needed',
          'Check doors with your hand; if hot, use another exit',
          'Close doors behind you to slow fire spread',
        ],
      ),
      GuideCardData(
        icon: Icons.pan_tool,
        title: 'If Trapped',
        items: [
          'Seal doors with wet towels or cloth to block smoke',
          'Stay near a window and signal with a light or cloth',
          'Call Bomba (994) or 999 if you have a phone',
          'Remain calm and wait for rescue',
        ],
      ),
    ],
  ),
  GuideSection(
    title: 'After a Fire',
    cards: [
      GuideCardData(
        icon: Icons.check_circle_outline,
        title: 'First Steps',
        items: [
          'Stay out until Bomba declares the area safe',
          'Report damage to insurance or local authorities',
          'Take photos of damage for claims or aid requests',
          'Check with TNB (15454) if power lines are affected',
        ],
      ),
      GuideCardData(
        icon: Icons.favorite_border,
        title: 'Recovery',
        items: [
          'Ventilate the house once safe to clear smoke',
          'Discard burnt food or items to avoid contamination',
          'Seek help from NGOs or JKM for relief if needed',
          'Clean soot with protective gear to avoid health risks',
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
    label: 'Fire & Rescue (Bomba)',
    number: '994',
    icon: Icons.fire_truck,
    description: 'Fire Department Emergency',
  ),
  EmergencyContact(
    label: 'Tenaga Nasional (TNB)',
    number: '15454',
    icon: Icons.electrical_services,
    description: 'Report Electrical Fires or Outages',
  ),
];

class FireGuideScreen extends StatelessWidget {
  const FireGuideScreen({super.key});

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
          'Fire Safety Guide',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
        ),
      ],
    ),
  );

  /// Builds a warning banner with a Malaysia-specific fire message.
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
              'Fire Warning',
              style: TextStyle(color: colors.bg100, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: _spacingSmall),
        Text(
          'Fires spread fast—get out within 2 minutes! Don’t wait, call Bomba (994) immediately!',
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
            Icon(Icons.phone, color: colors.accent200, size: 24),
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