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
    titleKey: 'before_fire',
    cards: [
      GuideCardData(
        icon: Icons.checklist_rounded,
        titleKey: 'prevention',
        itemKeys: [
          'install_smoke_detectors',
          'keep_cooking_areas_clear',
          'avoid_overloading_power',
          'store_petrol_gas',
        ],
      ),
      GuideCardData(
        icon: Icons.route,
        titleKey: 'escape_plan',
        itemKeys: [
          'plan_two_routes',
          'ensure_windows_openable',
          'set_meeting_point',
          'teach_children_call',
        ],
      ),
    ],
  ),
  GuideSection(
    titleKey: 'during_fire',
    cards: [
      GuideCardData(
        icon: Icons.shield,
        titleKey: 'immediate_actions',
        itemKeys: [
          'shout_api',
          'stay_low',
          'check_doors',
          'close_doors',
        ],
      ),
      GuideCardData(
        icon: Icons.pan_tool,
        titleKey: 'if_trapped',
        itemKeys: [
          'seal_doors',
          'signal_window',
          'call_bomba',
          'remain_calm',
        ],
      ),
    ],
  ),
  GuideSection(
    titleKey: 'after_fire',
    cards: [
      GuideCardData(
        icon: Icons.check_circle_outline,
        titleKey: 'first_steps',
        itemKeys: [
          'stay_out',
          'report_damage',
          'take_photos',
          'check_tnb',
        ],
      ),
      GuideCardData(
        icon: Icons.favorite_border,
        titleKey: 'recovery',
        itemKeys: [
          'ventilate_house',
          'discard_burnt_items',
          'seek_help_ngo',
          'clean_soot',
        ],
      ),
    ],
  ),
];

const _emergencyContacts = [
  EmergencyContact(
    labelKey: 'emergency_police_ambulance',
    number: '999',
    icon: Icons.local_hospital,
    descriptionKey: 'nationwide_emergency',
  ),
  EmergencyContact(
    labelKey: 'fire_rescue_bomba',
    number: '994',
    icon: Icons.fire_truck,
    descriptionKey: 'fire_department',
  ),
  EmergencyContact(
    labelKey: 'tenaga_nasional_tnb',
    number: '15454',
    icon: Icons.electrical_services,
    descriptionKey: 'report_electrical',
  ),
];

class FireGuideScreen extends StatelessWidget {
  const FireGuideScreen({super.key});

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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_paddingValue, 70, _paddingValue, _paddingValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _spacingLarge),
                  _WarningBanner(colors: colors),
                  const SizedBox(height: _spacingLarge),
                  ..._guideSections.map((section) => _Section(colors: colors, section: section)),
                  const SizedBox(height: _spacingLarge),
                  _EmergencyContacts(colors: colors),
                ],
              ),
            ),
            _Header(colors: colors),
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
      decoration: _buildCardDecoration(colors, opacity: 0.7),
      padding: const EdgeInsets.all(FireGuideScreen._paddingValue),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
            tooltip: l.translate('back'),
          ),
          const SizedBox(width: FireGuideScreen._spacingSmall),
          Text(
            l.translate('fire_safety_guide'),
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
      decoration: BoxDecoration(
        color: colors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(FireGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.bg100),
              const SizedBox(width: FireGuideScreen._spacingSmall),
              Text(
                l.translate('fire_warning'),
                style: TextStyle(color: colors.bg100, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: FireGuideScreen._spacingSmall),
          Text(
            l.translate('fire_spread_warning'),
            style: TextStyle(color: colors.bg100, fontSize: 14),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: FireGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.translate(section.titleKey),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary300),
          ),
          const SizedBox(height: FireGuideScreen._spacingMedium),
          ...section.cards.map((card) => _GuideCard(colors: colors, card: card)),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: FireGuideScreen._spacingMedium),
      decoration: _buildCardDecoration(colors),
      padding: const EdgeInsets.all(FireGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(card.icon, color: colors.accent200, size: 20),
              const SizedBox(width: FireGuideScreen._spacingSmall),
              Text(
                l.translate(card.titleKey),
                style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary300),
              ),
            ],
          ),
          const SizedBox(height: FireGuideScreen._spacingSmall),
          ...card.itemKeys.map(
                (itemKey) => Padding(
              padding: const EdgeInsets.only(bottom: FireGuideScreen._spacingSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: colors.text200)),
                  Expanded(
                    child: Semantics(
                      label: l.translate(itemKey),
                      child: Text(
                        l.translate(itemKey),
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
  }
}

class _EmergencyContacts extends StatelessWidget {
  final AppColorTheme colors;

  const _EmergencyContacts({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _buildCardDecoration(colors),
      padding: const EdgeInsets.all(FireGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone, color: colors.accent200, size: 24),
              const SizedBox(width: FireGuideScreen._spacingSmall),
              Text(
                l.translate('emergency_contacts'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
              ),
            ],
          ),
          const SizedBox(height: FireGuideScreen._spacingMedium),
          ..._emergencyContacts.map((contact) => _ContactItem(colors: colors, contact: contact)),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final AppColorTheme colors;
  final EmergencyContact contact;

  const _ContactItem({required this.colors, required this.contact});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: FireGuideScreen._spacingMedium),
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
            padding: const EdgeInsets.all(FireGuideScreen._paddingValue),
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
                const SizedBox(width: FireGuideScreen._spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.translate(contact.labelKey),
                        style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary300, fontSize: 16),
                      ),
                      Text(
                        l.translate(contact.descriptionKey),
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
  }

  Future<void> _launchPhone(BuildContext context, String number) async {
    final l = AppLocalizations.of(context);
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar(context, l.translate('dial_error', {'number': number}), Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar(context, l.translate('dial_error_with_exception', {'number': number, 'error': e.toString()}), Colors.redAccent);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(FireGuideScreen._paddingValue),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

BoxDecoration _buildCardDecoration(AppColorTheme colors, {double opacity = 0.85}) => BoxDecoration(
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