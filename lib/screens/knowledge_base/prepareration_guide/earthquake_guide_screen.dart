import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mydpar/localization/app_localizations.dart';

class GuideSection {
  final String titleKey; // Changed to use localization key
  final List<GuideCardData> cards;

  const GuideSection({required this.titleKey, required this.cards});
}

class GuideCardData {
  final IconData icon;
  final String titleKey; // Changed to use localization key
  final List<String> itemKeys; // Changed to use localization keys

  const GuideCardData({required this.icon, required this.titleKey, required this.itemKeys});
}

class EmergencyContact {
  final String labelKey; // Changed to use localization key
  final String number;
  final IconData icon;
  final String descriptionKey; // Changed to use localization key

  const EmergencyContact({
    required this.labelKey,
    required this.number,
    required this.icon,
    required this.descriptionKey,
  });
}

const _guideSections = [
  GuideSection(
    titleKey: 'before_earthquake',
    cards: [
      GuideCardData(
        icon: Icons.home,
        titleKey: 'home_preparation',
        itemKeys: [
          'secure_furniture',
          'know_utilities',
          'keep_supplies',
          'identify_safe_spots',
        ],
      ),
      GuideCardData(
        icon: Icons.map,
        titleKey: 'emergency_plan',
        itemKeys: [
          'create_plan',
          'establish_meeting_points',
          'practice_drills',
          'keep_contacts',
        ],
      ),
    ],
  ),
  GuideSection(
    titleKey: 'during_earthquake',
    cards: [
      GuideCardData(
        icon: Icons.shield,
        titleKey: 'drop_cover_hold',
        itemKeys: [
          'drop_hands_knees',
          'take_cover',
          'hold_on',
          'stay_away_glass',
        ],
      ),
      GuideCardData(
        icon: Icons.business,
        titleKey: 'if_indoors',
        itemKeys: [
          'stay_inside',
          'avoid_bookcases',
          'no_elevators',
          'protect_head',
        ],
      ),
      GuideCardData(
        icon: Icons.park,
        titleKey: 'if_outdoors',
        itemKeys: [
          'move_open_area',
          'avoid_buildings',
          'avoid_power_lines',
          'watch_falling_objects',
        ],
      ),
    ],
  ),
  GuideSection(
    titleKey: 'after_earthquake',
    cards: [
      GuideCardData(
        icon: Icons.check_circle_outline,
        titleKey: 'safety_checks',
        itemKeys: [
          'check_injuries',
          'look_fire_hazards',
          'check_utilities',
          'listen_broadcasts',
        ],
      ),
      GuideCardData(
        icon: Icons.warning_amber_rounded,
        titleKey: 'be_prepared_for',
        itemKeys: [
          'aftershocks',
          'building_damage',
          'power_outages',
          'response_delays',
        ],
      ),
    ],
  ),
];

const _emergencyContacts = [
  EmergencyContact(
    labelKey: 'national_disaster_center',
    number: '03-80642400',
    icon: Icons.emergency,
    descriptionKey: 'nadma_center',
  ),
  EmergencyContact(
    labelKey: 'emergency_response',
    number: '999',
    icon: Icons.local_hospital,
    descriptionKey: 'police_ambulance_fire',
  ),
];

class EarthquakeGuideScreen extends StatelessWidget {
  const EarthquakeGuideScreen({super.key});

  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _Header(colors: colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_paddingValue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WarningBanner(colors: colors),
                    const SizedBox(height: _spacingMedium),
                    ..._guideSections.map((section) => _Section(colors: colors, section: section)),
                    const SizedBox(height: _spacingLarge),
                    _EmergencyContactsSection(colors: colors),
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

class _Header extends StatelessWidget {
  final AppColorTheme colors;

  const _Header({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(EarthquakeGuideScreen._paddingValue),
      decoration: _buildCardDecoration(colors, opacity: 0.7),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
            tooltip: l.translate('back'),
          ),
          const SizedBox(width: EarthquakeGuideScreen._spacingSmall),
          Text(
            l.translate('earthquake_safety'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final AppColorTheme colors;

  const _WarningBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(EarthquakeGuideScreen._paddingValue),
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
              const SizedBox(width: EarthquakeGuideScreen._spacingSmall),
              Text(
                l.translate('earthquake_warning'),
                style: TextStyle(color: colors.bg100, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: EarthquakeGuideScreen._spacingSmall),
          Text(
            l.translate('earthquake_action'),
            style: TextStyle(color: colors.bg100),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final AppColorTheme colors;
  final GuideSection section;

  const _Section({required this.colors, required this.section});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: EarthquakeGuideScreen._spacingMedium),
          child: Text(
            l.translate(section.titleKey),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary300),
          ),
        ),
        ...section.cards.map((card) => _GuideCard(colors: colors, card: card)),
        const SizedBox(height: EarthquakeGuideScreen._spacingMedium),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final AppColorTheme colors;
  final GuideCardData card;

  const _GuideCard({required this.colors, required this.card});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: EarthquakeGuideScreen._spacingMedium),
      padding: const EdgeInsets.all(EarthquakeGuideScreen._paddingValue),
      decoration: _buildCardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(card.icon, color: colors.accent200),
              const SizedBox(width: EarthquakeGuideScreen._spacingMedium),
              Text(
                l.translate(card.titleKey),
                style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary300),
              ),
            ],
          ),
          const SizedBox(height: EarthquakeGuideScreen._spacingMedium),
          ...card.itemKeys.map(
                (itemKey) => Padding(
              padding: const EdgeInsets.only(bottom: EarthquakeGuideScreen._spacingSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: colors.accent200)),
                  Expanded(
                    child: Text(
                      l.translate(itemKey),
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
  }
}

class _EmergencyContactsSection extends StatelessWidget {
  final AppColorTheme colors;

  const _EmergencyContactsSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.translate('emergency_contacts'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary300),
        ),
        const SizedBox(height: EarthquakeGuideScreen._spacingMedium),
        ..._emergencyContacts.map((contact) => _ContactCard(colors: colors, contact: contact)),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final AppColorTheme colors;
  final EmergencyContact contact;

  const _ContactCard({required this.colors, required this.contact});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: EarthquakeGuideScreen._spacingMedium),
      decoration: _buildCardDecoration(colors),
      child: ListTile(
        leading: Icon(contact.icon, color: colors.accent200),
        title: Text(
          l.translate(contact.labelKey),
          style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary300),
        ),
        subtitle: Text(
          l.translate(contact.descriptionKey),
          style: TextStyle(color: colors.text200, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone, color: colors.accent200),
          onPressed: () => _makePhoneCall(context, contact.number),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EarthquakeGuideScreen._paddingValue,
          vertical: EarthquakeGuideScreen._spacingSmall,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final l = AppLocalizations.of(context);
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar(context, l.translate('dial_error', {'number': phoneNumber}), Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar(context, l.translate('dial_error_with_exception', {'number': phoneNumber, 'error': e.toString()}), Colors.redAccent);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(EarthquakeGuideScreen._paddingValue),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

BoxDecoration _buildCardDecoration(AppColorTheme colors, {double opacity = 0.85}) => BoxDecoration(
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