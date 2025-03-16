import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class FracturesGuideScreen extends StatelessWidget {
  const FracturesGuideScreen({super.key});

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
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                _paddingValue,
                70, // Adjusted for header height
                _paddingValue,
                _paddingValue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _spacingLarge),
                  _buildEmergencyWarning(context, colors),
                  const SizedBox(height: _spacingLarge),
                  _buildInitialAssessment(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildRiceMethod(context, colors),
                  const SizedBox(height: _spacingLarge),
                  _buildAdditionalCare(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildWhenToSeekHelp(colors),
                ],
              ),
            ),
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
      border: Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
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
        Expanded(
          child: Text(
            'Fractures & Sprains',
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

  /// Builds the emergency warning section
  Widget _buildEmergencyWarning(BuildContext context, AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [colors.warning, colors.warning.withOpacity(0.8)],
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
            Icon(Icons.warning_amber_rounded, color: colors.bg100, size: 28),
            const SizedBox(width: _spacingMedium),
            Text(
              'Emergency Warning',
              style: TextStyle(
                color: colors.bg100,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(_paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seek Immediate Help If:',
                style: TextStyle(
                  color: colors.bg100,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: _spacingMedium),
              _buildWarningItem('Suspected spinal or neck injury'),
              _buildWarningItem('Bone protruding through skin'),
              _buildWarningItem('Severe deformity or uncontrollable pain'),
              _buildWarningItem('Loss of pulse or sensation below injury'),
            ],
          ),
        ),
        const SizedBox(height: _spacingLarge),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _makeEmergencyCall(context),
            icon: Icon(Icons.phone, color: colors.warning),
            label: Text(
              'Call 999',
              style: TextStyle(color: colors.warning, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.bg100,
              padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 300.ms);

  /// Builds a warning item for emergency conditions
  Widget _buildWarningItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: _spacingSmall),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(right: _spacingSmall, top: 4),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  /// Builds the initial assessment section
  Widget _buildInitialAssessment(AppColorTheme colors) => Container(
    decoration: _buildCardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.personal_injury, color: colors.accent200),
            const SizedBox(width: _spacingMedium),
            Text(
              'Initial Assessment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingMedium),
        _buildAssessmentItem(
          colors,
          Icons.visibility,
          'Look for Signs',
          'Swelling or bruising\nDeformity or abnormal position\nOpen wounds near injury',
        ),
        const SizedBox(height: _spacingMedium),
        _buildAssessmentItem(
          colors,
          Icons.hearing,
          'Listen for',
          'Cracking or popping sounds\nPatient\'s description of pain\nWhen and how injury occurred',
        ),
      ],
    ),
  ).animate().fadeIn(duration: 400.ms);

  /// Builds an assessment item
  Widget _buildAssessmentItem(AppColorTheme colors, IconData icon, String title, String content) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: colors.accent200, size: 20),
      const SizedBox(width: _spacingMedium),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              content,
              style: TextStyle(
                color: colors.text200,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  /// Builds the RICE method section
  Widget _buildRiceMethod(BuildContext context, AppColorTheme colors) => Container(
    decoration: _buildCardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.healing, color: colors.accent200),
            const SizedBox(width: _spacingMedium),
            Text(
              'RICE Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        ...[
          _buildStep(
            context: context,
            colors: colors,
            stepInitial: 'R',
            title: 'Rest',
            icon: Icons.hotel,
            content: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(_paddingValue),
                  decoration: BoxDecoration(
                    color: colors.bg100.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stop all activity and avoid movement of the injured area.',
                        style: TextStyle(color: colors.text200),
                      ),
                      const SizedBox(height: _spacingSmall),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(_paddingValue),
                        decoration: BoxDecoration(
                          color: colors.bg100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Continuing to move or put weight on the injury can cause further damage.',
                          style: TextStyle(
                            color: colors.accent200,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStep(
            context: context,
            colors: colors,
            stepInitial: 'I',
            title: 'Ice',
            icon: Icons.ac_unit,
            content: Column(
              children: [
                _buildCheckItem(
                  icon: Icons.access_time,
                  text: 'Apply for 15-20 minutes',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.wrap_text,
                  text: 'Wrap ice pack in thin towel',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.update,
                  text: 'Repeat every 2-3 hours for 48-72 hours',
                  colors: colors,
                ),
              ],
            ),
          ),
          _buildStep(
            context: context,
            colors: colors,
            stepInitial: 'C',
            title: 'Compression',
            icon: Icons.compress,
            content: Column(
              children: [
                _buildCheckItem(
                  icon: Icons.medical_services,
                  text: 'Use elastic bandage',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.warning,
                  text: 'Not too tight - should be snug',
                  colors: colors,
                ),
                Container(
                  margin: const EdgeInsets.only(top: _spacingMedium),
                  padding: const EdgeInsets.all(_paddingValue),
                  decoration: BoxDecoration(
                    color: colors.primary100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
                          const SizedBox(width: _spacingSmall),
                          Text(
                            'Warning Signs',
                            style: TextStyle(
                              color: colors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _spacingMedium),
                      ...[
                        'Numbness or tingling',
                        'Increased pain',
                        'Cold or bluish skin',
                      ].map((text) => Padding(
                        padding: const EdgeInsets.only(bottom: _spacingSmall),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 8, top: 4),
                              decoration: BoxDecoration(
                                color: colors.warning.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: colors.text200,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStep(
            context: context,
            colors: colors,
            stepInitial: 'E',
            title: 'Elevation',
            icon: Icons.arrow_upward,
            content: Column(
              children: [
                _buildCheckItem(
                  icon: Icons.height,
                  text: 'Keep injured area above heart level',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.timer,
                  text: 'Maintain elevation for first 24-48 hours',
                  colors: colors,
                ),
              ],
            ),
          ),
        ].asMap().entries.map((entry) => entry.value.animate().fadeIn(duration: 400.ms, delay: (entry.key * 100).ms)).toList(),
      ],
    ),
  );

  /// Builds a single step in the RICE method
  Widget _buildStep({
    required BuildContext context,
    required AppColorTheme colors,
    required String stepInitial,
    required String title,
    required IconData icon,
    required Widget content,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: _spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.accent200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepInitial,
                      style: TextStyle(
                        color: colors.bg100,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _spacingMedium),
                Icon(icon, color: colors.accent200),
                const SizedBox(width: _spacingSmall),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.primary300,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.only(
                left: 24,
                top: _spacingMedium,
                bottom: _spacingMedium,
              ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: colors.accent200.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: content,
            ),
          ],
        ),
      );

  /// Builds a check item with icon and text
  Widget _buildCheckItem({
    required IconData icon,
    required String text,
    required AppColorTheme colors,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: _spacingMedium),
        child: Row(
          children: [
            Icon(icon, color: colors.accent200, size: 20),
            const SizedBox(width: _spacingMedium),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.text200),
              ),
            ),
          ],
        ),
      );

  /// Builds the additional care section
  Widget _buildAdditionalCare(AppColorTheme colors) => Container(
    decoration: _buildCardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_services, color: colors.accent200),
            const SizedBox(width: _spacingMedium),
            Text(
              'Additional Care',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        Container(
          padding: const EdgeInsets.all(_paddingValue),
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildCareItem(
                colors,
                Icons.medical_services,
                'Immobilization',
                'Use splints or slings to prevent movement of injured area.',
              ),
              const SizedBox(height: _spacingMedium),
              _buildCareItem(
                colors,
                Icons.medication,
                'Pain Management',
                'Over-the-counter pain relievers if needed (e.g., ibuprofen, paracetamol).',
              ),
              const SizedBox(height: _spacingMedium),
              _buildCareItem(
                colors,
                Icons.monitor_heart,
                'Monitor',
                'Check circulation, sensation, and movement regularly.',
              ),
            ],
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 400.ms);

  /// Builds a care item with icon and text
  Widget _buildCareItem(AppColorTheme colors, IconData icon, String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: colors.accent200, size: 20),
          const SizedBox(width: _spacingMedium),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left: 32, top: _spacingSmall),
        child: Text(
          description,
          style: TextStyle(
            color: colors.text200,
            height: 1.3,
          ),
        ),
      ),
    ],
  );

  /// Builds the "When to Seek Help" section
  Widget _buildWhenToSeekHelp(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.warning.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.warning.withOpacity(0.3)),
    ),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_hospital, color: colors.warning),
            const SizedBox(width: _spacingMedium),
            Text(
              'When to Seek Medical Help',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300, // Changed to primary300 for consistency
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        Container(
          padding: const EdgeInsets.all(_paddingValue),
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildHelpItem(colors, 'Unable to bear weight or move the injured area'),
              _buildHelpItem(colors, 'Severe pain or swelling'),
              _buildHelpItem(colors, 'Numbness or tingling'),
              _buildHelpItem(colors, 'Visible deformity'),
              _buildHelpItem(colors, 'Open wounds or bleeding'),
            ],
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 400.ms);

  /// Builds a help item with icon and text
  Widget _buildHelpItem(AppColorTheme colors, String text) => Padding(
    padding: const EdgeInsets.only(bottom: _spacingMedium),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: colors.warning, size: 20),
        const SizedBox(width: _spacingMedium),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.text200,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );

  /// Returns a reusable card decoration
  BoxDecoration _buildCardDecoration(AppColorTheme colors) => BoxDecoration(
    color: colors.bg100.withOpacity(0.85),
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

  /// Initiates an emergency phone call
  Future<void> _makeEmergencyCall(BuildContext context) async {
    final Uri url = Uri.parse('tel:999');
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
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_paddingValue),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}