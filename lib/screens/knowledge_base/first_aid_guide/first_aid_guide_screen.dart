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

// Model for first aid data (optional, Firebase-ready if needed)
class FirstAidItem {
  final String title;
  final String description;
  final IconData icon;

  const FirstAidItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class FirstAidGuideScreen extends StatelessWidget {
  const FirstAidGuideScreen({super.key});

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(context, colors),
            _buildHeader(context, colors),
          ],
        ),
      ),
    );
  }

  /// Builds the header with back button and title
  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border:
              Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.7))),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _paddingValue,
          vertical: _paddingValue - 4,
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.primary300),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: _spacingSmall),
            Text(
              'First Aid Guide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
      );

  /// Builds the scrollable content area
  Widget _buildContent(BuildContext context, AppColorTheme colors) =>
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          _paddingValue,
          60,
          _paddingValue,
          _paddingValue,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: _spacingLarge),
            _buildEmergencyActions(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildQuickResponseGrid(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildCommonEmergencies(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildFirstAidKit(context, colors),
          ],
        ),
      );

  /// Builds the emergency actions section
  Widget _buildEmergencyActions(BuildContext context, AppColorTheme colors) =>
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.warning, colors.warning.withOpacity(0.7)],
          ),
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
                  'Emergency Actions',
                  style: TextStyle(
                    color: colors.bg100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            Text(
              'Call Emergency Services',
              style: TextStyle(
                color: colors.bg100,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              'Always call emergency services first in life-threatening situations',
              style: TextStyle(color: colors.bg100.withOpacity(0.8)),
            ),
            const SizedBox(height: _spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _makeEmergencyCall(context),
                icon: const Icon(Icons.phone),
                label: const Text('Call 999'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bg100,
                  foregroundColor: colors.warning,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
                ),
              ),
            ),
          ],
        ),
      );

  /// Builds the quick response grid
  Widget _buildQuickResponseGrid(BuildContext context, AppColorTheme colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Response',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
          const SizedBox(height: _spacingMedium),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: _spacingMedium,
            crossAxisSpacing: _spacingMedium,
            childAspectRatio: 1.1,
            children: [
              _buildQuickResponseCard(
                context: context,
                icon: Icons.monitor_heart,
                title: 'CPR Guide',
                description: 'Step-by-step CPR instructions',
                colors: colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CPRGuideScreen(),
                  ),
                ),
              ),
              _buildQuickResponseCard(
                context: context,
                icon: Icons.water_drop,
                title: 'Bleeding',
                description: 'Wound care and bleeding control',
                colors: colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BleedingGuideScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  /// Builds a quick response card
  Widget _buildQuickResponseCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required AppColorTheme colors,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap ??
            () => _showSnackBar(
                  context,
                  '$title guide not yet implemented',
                  Colors.orange,
                ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.bg300.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(_paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.warning, size: 32),
              const SizedBox(height: _spacingMedium),
              Text(
                title,
                style: TextStyle(
                  color: colors.primary300,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: colors.text200, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  /// Builds the common emergencies section
  Widget _buildCommonEmergencies(BuildContext context, AppColorTheme colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common Emergencies',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
          const SizedBox(height: _spacingMedium),
          _buildEmergencyCard(
            context: context,
            icon: Icons.local_fire_department,
            title: 'Burns Treatment',
            description: 'First aid for different types of burns',
            colors: colors,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BurnsGuideScreen(),
              ),
            ),
          ),
          const SizedBox(height: _spacingMedium),
          _buildEmergencyCard(
            context: context,
            icon: Icons.personal_injury,
            title: 'Fractures & Sprains',
            description: 'Immediate care for bone and joint injuries',
            colors: colors,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FracturesGuideScreen(),
              ),
            ),
          ),
          const SizedBox(height: _spacingMedium),
          _buildEmergencyCard(
            context: context,
            icon: Icons.bug_report,
            title: 'Bites & Stings',
            description: 'Treatment for insect and animal bites',
            colors: colors,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BitesStingsGuideScreen(),
              ),
            ),
          ),
        ],
      );

  /// Builds an emergency card
  Widget _buildEmergencyCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required AppColorTheme colors,
    VoidCallback? onTap, // Add this parameter
  }) =>
      GestureDetector(
        onTap: onTap ??
            () => _showSnackBar(
                context, '$title guide not yet implemented', Colors.orange),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.bg300.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(_paddingValue),
          child: Row(
            children: [
              Icon(icon, color: colors.accent200),
              const SizedBox(width: _spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.primary300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: colors.text200, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  /// Builds the first aid kit checklist section
  Widget _buildFirstAidKit(BuildContext context, AppColorTheme colors) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: colors.accent200),
                const SizedBox(width: _spacingSmall),
                Text(
                  'First Aid Kit Checklist',
                  style: TextStyle(
                    color: colors.primary300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            _buildChecklistItem('Bandages and gauze', colors),
            _buildChecklistItem('Antiseptic wipes', colors),
            _buildChecklistItem('Medical tape', colors),
            const SizedBox(height: _spacingSmall),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirstAidKitScreen(),
                ),
              ),
              child: Text(
                'View Full List',
                style: TextStyle(color: colors.accent200),
              ),
            ),
          ],
        ),
      );

  /// Builds a checklist item
  Widget _buildChecklistItem(String text, AppColorTheme colors) => Padding(
        padding: const EdgeInsets.only(bottom: _spacingSmall),
        child: Row(
          children: [
            Icon(Icons.check, color: colors.accent200, size: 16),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.text200, fontSize: 14),
              ),
            ),
          ],
        ),
      );

  /// Initiates an emergency call with error handling
  Future<void> _makeEmergencyCall(BuildContext context) async {
    final Uri url = Uri(scheme: 'tel', path: '999');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showSnackBar(context, 'Could not launch emergency call', Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, 'Failed to make call: $e', Colors.red);
    }
  }

  /// Displays a snackbar with a message
  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
