import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/cpr_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/bleeding_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/burns_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/fractures_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/bites_stings_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/first_aid_kit_screen.dart';
import 'package:mydpar/localization/app_localizations.dart';

/// A screen providing an overview of first aid guides with multi-language support.
///
/// Includes emergency actions, quick response options, common emergencies, and a first aid kit checklist.
class FirstAidGuideScreen extends StatelessWidget {
  const FirstAidGuideScreen({super.key});

  // Constants for consistent padding and spacing
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _FirstAidContent(colors: colors),
            _Header(colors: colors),
          ],
        ),
      ),
    );
  }
}

/// Encapsulates the scrollable content of the first aid guide screen.
class _FirstAidContent extends StatelessWidget {
  final AppColorTheme colors;

  const _FirstAidContent({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FirstAidGuideScreen._paddingValue,
        60,
        FirstAidGuideScreen._paddingValue,
        FirstAidGuideScreen._paddingValue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: FirstAidGuideScreen._spacingLarge),
          _EmergencyActions(colors: colors),
          const SizedBox(height: FirstAidGuideScreen._spacingLarge),
          _QuickResponseGrid(colors: colors),
          const SizedBox(height: FirstAidGuideScreen._spacingLarge),
          _CommonEmergencies(colors: colors),
          const SizedBox(height: FirstAidGuideScreen._spacingLarge),
          _FirstAidKitChecklist(colors: colors),
        ],
      ),
    );
  }
}

/// Displays the header with a back button and localized title.
class _Header extends StatelessWidget {
  final AppColorTheme colors;

  const _Header({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border.all(color: colors.bg300.withOpacity(0.7)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: FirstAidGuideScreen._paddingValue,
        vertical: FirstAidGuideScreen._paddingValue - 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: FirstAidGuideScreen._spacingSmall),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('first_aid_guide'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the emergency actions section with a call button.
class _EmergencyActions extends StatelessWidget {
  final AppColorTheme colors;

  const _EmergencyActions({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.bg100),
              const SizedBox(width: FirstAidGuideScreen._spacingSmall),
              Text(
                l.translate('emergency_actions'),
                style: TextStyle(
                  color: colors.bg100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: FirstAidGuideScreen._spacingMedium),
          Text(
            l.translate('call_emergency_services'),
            style: TextStyle(
              color: colors.bg100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: FirstAidGuideScreen._spacingSmall),
          Text(
            l.translate('call_before_cpr'),
            style: TextStyle(color: colors.bg100.withOpacity(0.8)),
          ),
          const SizedBox(height: FirstAidGuideScreen._spacingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _makeEmergencyCall(context),
              icon: Icon(Icons.phone, color: colors.warning),
              label: Text(
                l.translate('call_emergency'),
                style: TextStyle(color: colors.warning),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.bg100,
                padding: const EdgeInsets.symmetric(vertical: FirstAidGuideScreen._spacingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Initiates an emergency call with error handling.
  Future<void> _makeEmergencyCall(BuildContext context) async {
    final url = Uri(scheme: 'tel', path: '999');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showSnackBar(
          context,
          AppLocalizations.of(context).translate('call_error_no_launch'),
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        context,
        AppLocalizations.of(context).translate('call_error', {'error': e.toString()}),
        Colors.red,
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Displays a grid of quick response options.
class _QuickResponseGrid extends StatelessWidget {
  final AppColorTheme colors;

  const _QuickResponseGrid({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.translate('quick_response'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.primary300,
          ),
        ),
        const SizedBox(height: FirstAidGuideScreen._spacingMedium),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: FirstAidGuideScreen._spacingMedium,
          crossAxisSpacing: FirstAidGuideScreen._spacingMedium,
          childAspectRatio: 1.1,
          children: [
            _QuickResponseCard(
              icon: Icons.monitor_heart,
              titleKey: 'cpr_guide',
              descriptionKey: 'cpr_guide_desc',
              colors: colors,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CPRGuideScreen()),
              ),
            ),
            _QuickResponseCard(
              icon: Icons.water_drop,
              titleKey: 'bleeding_control',
              descriptionKey: 'bleeding_control_desc',
              colors: colors,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BleedingGuideScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single quick response card with localized content.
class _QuickResponseCard extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final AppColorTheme colors;
  final VoidCallback onTap;

  const _QuickResponseCard({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(FirstAidGuideScreen._paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.warning, size: 32),
            const SizedBox(height: FirstAidGuideScreen._spacingMedium),
            Text(
              l.translate(titleKey),
              style: TextStyle(
                color: colors.primary300,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.translate(descriptionKey),
              style: TextStyle(color: colors.text200, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a list of common emergencies.
class _CommonEmergencies extends StatelessWidget {
  final AppColorTheme colors;

  const _CommonEmergencies({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.translate('common_emergencies'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.primary300,
          ),
        ),
        const SizedBox(height: FirstAidGuideScreen._spacingMedium),
        _EmergencyCard(
          icon: Icons.local_fire_department,
          titleKey: 'burns_treatment',
          descriptionKey: 'burns_treatment_desc',
          colors: colors,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BurnsGuideScreen()),
          ),
        ),
        const SizedBox(height: FirstAidGuideScreen._spacingMedium),
        _EmergencyCard(
          icon: Icons.personal_injury,
          titleKey: 'fractures_sprains',
          descriptionKey: 'fractures_sprains_desc',
          colors: colors,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FracturesGuideScreen()),
          ),
        ),
        const SizedBox(height: FirstAidGuideScreen._spacingMedium),
        _EmergencyCard(
          icon: Icons.bug_report,
          titleKey: 'bites_stings_title',
          descriptionKey: 'bites_stings_desc',
          colors: colors,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BitesStingsGuideScreen()),
          ),
        ),
      ],
    );
  }
}

/// A single emergency card with localized content.
class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final AppColorTheme colors;
  final VoidCallback onTap;

  const _EmergencyCard({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(FirstAidGuideScreen._paddingValue),
        child: Row(
          children: [
            Icon(icon, color: colors.accent200),
            const SizedBox(width: FirstAidGuideScreen._spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.translate(titleKey),
                    style: TextStyle(
                      color: colors.primary300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.translate(descriptionKey),
                    style: TextStyle(color: colors.text200, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the first aid kit checklist section.
class _FirstAidKitChecklist extends StatelessWidget {
  final AppColorTheme colors;

  const _FirstAidKitChecklist({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(FirstAidGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: colors.accent200),
              const SizedBox(width: FirstAidGuideScreen._spacingSmall),
              Text(
                l.translate('first_aid_kit_checklist'),
                style: TextStyle(
                  color: colors.primary300,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: FirstAidGuideScreen._spacingMedium),
          _ChecklistItem(textKey: 'bandages_gauze', colors: colors),
          _ChecklistItem(textKey: 'antiseptic_wipes', colors: colors),
          _ChecklistItem(textKey: 'medical_tape', colors: colors),
          const SizedBox(height: FirstAidGuideScreen._spacingSmall),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FirstAidKitScreen()),
            ),
            child: Text(
              l.translate('view_full_list'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single checklist item with localized text.
class _ChecklistItem extends StatelessWidget {
  final String textKey;
  final AppColorTheme colors;

  const _ChecklistItem({required this.textKey, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FirstAidGuideScreen._spacingSmall),
      child: Row(
        children: [
          Icon(Icons.check, color: colors.accent200, size: 16),
          const SizedBox(width: FirstAidGuideScreen._spacingSmall),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable card widget with gradient styling.
class _Card extends StatelessWidget {
  final AppColorTheme colors;
  final Widget child;

  const _Card({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.warning, colors.warning.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(FirstAidGuideScreen._paddingValue),
      child: child,
    );
  }
}