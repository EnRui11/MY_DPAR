import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/emergency_kit_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/heavy_rain_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/flood_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/fire_guide_screen.dart';

class PreparationGuidesScreen extends StatelessWidget {
  const PreparationGuidesScreen({super.key});

  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_paddingValue),
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
        padding: const EdgeInsets.all(_paddingValue),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border:
              Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.primary300),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: _spacingSmall),
            Text(
              'Preparation Guides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
      );

  /// Builds the featured guide card with a button to view a checklist.
  Widget _buildFeaturedGuide(AppColorTheme colors, BuildContext context) =>
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.accent200, colors.accent100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: colors.bg100),
                const SizedBox(width: _spacingSmall),
                Text(
                  'Featured Guide',
                  style: TextStyle(
                    color: colors.bg100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            Text(
              'Emergency Preparedness Kit',
              style: TextStyle(
                color: colors.bg100,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              'Essential items to have ready for any disaster situation',
              style: TextStyle(color: colors.bg100.withOpacity(0.8)),
            ),
            const SizedBox(height: _spacingMedium),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyKitScreen(),
                  ),
                );
              },
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
  Widget _buildDisasterTypesList(AppColorTheme colors, BuildContext context) {
    const IconData flood = IconData(0xf07a3, fontFamily: 'MaterialIcons');

    return Column(
      children: [
        _buildDisasterTypeCard(
          colors,
          icon: Icons.thunderstorm_outlined,
          title: 'Heavy Rain',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HeavyRainGuideScreen(),
              ),
            );
          },
        ),
        _buildDisasterTypeCard(
          colors,
          icon: flood,
          title: 'Flood',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FloodGuideScreen(),
              ),
            );
          },
        ),
        _buildDisasterTypeCard(
          colors,
          icon: Icons.local_fire_department,
          title: 'Fire',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FireGuideScreen(),
              ),
            );
          },
        ),
        _buildDisasterTypeCard(
          colors,
          icon: Icons.landslide,
          title: 'Landslide',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Landslide guide coming soon')),
            );
          },
        ),
        _buildDisasterTypeCard(
          colors,
          icon: Icons.air_outlined,
          title: 'Haze',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Haze guide coming soon')),
            );
          },
        ),
        _buildDisasterTypeCard(
          colors,
          icon: Icons.cyclone,
          title: 'Typhoon',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Typhoon guide coming soon')),
            );
          },
        ),
      ],
    );
  }

  /// Builds a single disaster type card with an icon, title, and tap action.
  Widget _buildDisasterTypeCard(
    AppColorTheme colors, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: _spacingSmall),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.bg300.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(_paddingValue),
              child: Row(
                children: [
                  Icon(icon, color: colors.accent200, size: 24),
                  const SizedBox(width: _spacingMedium),
                  Text(
                    title,
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
