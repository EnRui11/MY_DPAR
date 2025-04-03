import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/emergency_kit_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/heavy_rain_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/flood_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/fire_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/landslide_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/haze_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/earthquake_guide_screen.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

class DisasterType {
  final String titleKey; // Changed to use localization key
  final Widget? destinationScreen;

  const DisasterType({
    required this.titleKey,
    this.destinationScreen,
  });
}

const _disasterTypes = [
  DisasterType(
    titleKey: 'heavy_rain',
    destinationScreen: HeavyRainGuideScreen(),
  ),
  DisasterType(
    titleKey: 'flood',
    destinationScreen: FloodGuideScreen(),
  ),
  DisasterType(
    titleKey: 'fire',
    destinationScreen: FireGuideScreen(),
  ),
  DisasterType(
    titleKey: 'landslide',
    destinationScreen: LandslideGuideScreen(),
  ),
  DisasterType(
    titleKey: 'earthquake',
    destinationScreen: EarthquakeGuideScreen(),
  ),
  DisasterType(
    titleKey: 'haze',
    destinationScreen: HazeGuideScreen(),
  ),
];

class PreparationGuidesScreen extends StatelessWidget {
  const PreparationGuidesScreen({super.key});

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
                    _FeaturedGuide(colors: colors),
                    const SizedBox(height: _spacingMedium),
                    Text(
                      l.translate('disaster_types'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: _spacingMedium),
                    _DisasterTypesList(colors: colors),
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
      padding: const EdgeInsets.all(PreparationGuidesScreen._paddingValue),
      decoration: _buildCardDecoration(colors, opacity: 0.7),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
            tooltip: l.translate('back'),
          ),
          const SizedBox(width: PreparationGuidesScreen._spacingSmall),
          Text(
            l.translate('preparation_guides'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedGuide extends StatelessWidget {
  final AppColorTheme colors;

  const _FeaturedGuide({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accent200, colors.accent100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(PreparationGuidesScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.bg100),
              const SizedBox(width: PreparationGuidesScreen._spacingSmall),
              Text(
                l.translate('featured_guide'),
                style: TextStyle(
                  color: colors.bg100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: PreparationGuidesScreen._spacingMedium),
          Text(
            l.translate('emergency_preparedness_kit'),
            style: TextStyle(
              color: colors.bg100,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: PreparationGuidesScreen._spacingSmall),
          Text(
            l.translate('emergency_kit_description'),
            style: TextStyle(color: colors.bg100.withOpacity(0.8)),
          ),
          const SizedBox(height: PreparationGuidesScreen._spacingMedium),
          ElevatedButton(
            onPressed: () => _navigateTo(context, const EmergencyKitScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.bg100,
              foregroundColor: colors.accent200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l.translate('view_checklist')),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _DisasterTypesList extends StatelessWidget {
  final AppColorTheme colors;

  const _DisasterTypesList({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _disasterTypes
          .map((disaster) => _DisasterTypeCard(colors: colors, disaster: disaster))
          .toList(),
    );
  }
}

class _DisasterTypeCard extends StatelessWidget {
  final AppColorTheme colors;
  final DisasterType disaster;

  const _DisasterTypeCard({required this.colors, required this.disaster});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PreparationGuidesScreen._spacingSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleDisasterTap(context, disaster),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: _buildCardDecoration(colors),
            padding: const EdgeInsets.all(PreparationGuidesScreen._paddingValue),
            child: Row(
              children: [
                Icon(
                  DisasterService.getDisasterIcon(disaster.titleKey.toLowerCase()),
                  color: colors.accent200,
                  size: 24,
                ),
                const SizedBox(width: PreparationGuidesScreen._spacingMedium),
                Text(
                  l.translate(disaster.titleKey),
                  style: TextStyle(
                    color: colors.primary300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: colors.text200,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleDisasterTap(BuildContext context, DisasterType disaster) {
    final l = AppLocalizations.of(context);
    if (disaster.destinationScreen != null) {
      _navigateTo(context, disaster.destinationScreen!);
    } else {
      _showSnackBar(
        context,
        l.translate('guide_coming_soon', {'title': l.translate(disaster.titleKey)}),
        Colors.grey,
      );
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(PreparationGuidesScreen._paddingValue),
        duration: const Duration(seconds: 2),
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