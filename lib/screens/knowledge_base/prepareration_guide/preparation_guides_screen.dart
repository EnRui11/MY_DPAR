import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/emergency_kit_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/heavy_rain_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/flood_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/fire_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/landslide_guide_screen.dart';

// Data model for disaster types
class DisasterType {
  final String title;
  final IconData icon;
  final Widget? destinationScreen;

  const DisasterType({
    required this.title,
    required this.icon,
    this.destinationScreen,
  });
}

// Centralized data for disaster types relevant to Malaysia
const _disasterTypes = [
  DisasterType(
    title: 'Heavy Rain',
    icon: Icons.thunderstorm_outlined,
    destinationScreen: HeavyRainGuideScreen(),
  ),
  DisasterType(
    title: 'Flood',
    icon: IconData(0xf07a3, fontFamily: 'MaterialIcons'), // Flood icon
    destinationScreen: FloodGuideScreen(),
  ),
  DisasterType(
    title: 'Fire',
    icon: Icons.local_fire_department,
    destinationScreen: FireGuideScreen(),
  ),
  DisasterType(
    title: 'Landslide',
    icon: Icons.landslide,
    destinationScreen: LandslideGuideScreen(),
  ),
  DisasterType(
    title: 'Haze',
    icon: Icons.air_outlined,
    destinationScreen: null, // Coming soon
  ),
];

class PreparationGuidesScreen extends StatelessWidget {
  const PreparationGuidesScreen({super.key});

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
                    _buildFeaturedGuide(colors, context),
                    const SizedBox(height: _spacingMedium),
                    Text(
                      'Disaster Types',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: _spacingMedium),
                    _buildDisasterTypesList(colors, context),
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
          'Preparation Guides',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
        ),
      ],
    ),
  );

  /// Builds the featured guide card for the emergency kit.
  Widget _buildFeaturedGuide(AppColorTheme colors, BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [colors.accent200, colors.accent100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(_padding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, color: colors.bg100),
            const SizedBox(width: _spacingSmall),
            Text(
              'Featured Guide',
              style: TextStyle(color: colors.bg100, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: _spacingMedium),
        Text(
          'Emergency Preparedness Kit',
          style: TextStyle(color: colors.bg100, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: _spacingSmall),
        Text(
          'Must-have items for disasters like floods and fires',
          style: TextStyle(color: colors.bg100.withOpacity(0.8)),
        ),
        const SizedBox(height: _spacingMedium),
        ElevatedButton(
          onPressed: () => _navigateTo(context, const EmergencyKitScreen()),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.bg100,
            foregroundColor: colors.accent200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('View Checklist'),
        ),
      ],
    ),
  );

  /// Builds the list of disaster type cards.
  Widget _buildDisasterTypesList(AppColorTheme colors, BuildContext context) => Column(
    children: _disasterTypes.map((disaster) => _buildDisasterTypeCard(colors, context, disaster)).toList(),
  );

  /// Builds a single disaster type card with an icon, title, and tap action.
  Widget _buildDisasterTypeCard(AppColorTheme colors, BuildContext context, DisasterType disaster) => Padding(
    padding: const EdgeInsets.only(bottom: _spacingSmall),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleDisasterTap(context, disaster),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: _cardDecoration(colors),
          padding: const EdgeInsets.all(_padding),
          child: Row(
            children: [
              Icon(disaster.icon, color: colors.accent200, size: 24),
              const SizedBox(width: _spacingMedium),
              Text(
                disaster.title,
                style: TextStyle(color: colors.primary300, fontWeight: FontWeight.w600),
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

  /// Handles tap actions for disaster types, navigating or showing a placeholder message.
  void _handleDisasterTap(BuildContext context, DisasterType disaster) {
    if (disaster.destinationScreen != null) {
      _navigateTo(context, disaster.destinationScreen!);
    } else {
      _showSnackBar(context, '${disaster.title} guide coming soon', Colors.grey);
    }
  }

  /// Navigates to the specified screen with a MaterialPageRoute.
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Displays a snackbar with a custom message and color.
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_padding),
        duration: const Duration(seconds: 2),
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