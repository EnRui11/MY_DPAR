import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class BleedingGuideScreen extends StatefulWidget {
  const BleedingGuideScreen({super.key});

  @override
  State<BleedingGuideScreen> createState() => _BleedingGuideScreenState();
}

class _BleedingGuideScreenState extends State<BleedingGuideScreen> {
  // Constants for consistency and easy tweaking
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 16.0;

  String _selectedSeverity = 'severe';

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
                  _buildEmergencyWarning(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildWoundAssessment(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildTreatmentTabs(colors),
                  const SizedBox(height: _spacingLarge),
                  _buildImportantTips(colors),
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
            'Bleeding Control',
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
  Widget _buildEmergencyWarning(AppColorTheme colors) => Container(
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
              _buildWarningItem('Uncontrollable bleeding or spurting blood'),
              _buildWarningItem('Signs of shock (pale, cold, sweaty skin)'),
              _buildWarningItem('Deep wounds or exposed internal tissue'),
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
  );

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

  /// Builds the wound assessment section
  Widget _buildWoundAssessment(AppColorTheme colors) => Container(
    decoration: _buildCardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_information, color: colors.accent200),
            const SizedBox(width: _spacingMedium),
            Text(
              'Wound Assessment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        _buildSeverityOption(
          colors,
          'severe',
          'Severe: Deep cuts, arterial bleeding',
          Colors.red,
        ),
        const SizedBox(height: _spacingSmall),
        _buildSeverityOption(
          colors,
          'moderate',
          'Moderate: Continuous bleeding, large cuts',
          Colors.orange,
        ),
        const SizedBox(height: _spacingSmall),
        _buildSeverityOption(
          colors,
          'minor',
          'Minor: Small cuts, scrapes',
          Colors.green,
        ),
      ],
    ),
  );

  /// Builds a severity option with animation for wound assessment
  Widget _buildSeverityOption(
      AppColorTheme colors,
      String severity,
      String text,
      Color indicatorColor,
      ) =>
      InkWell(
        onTap: () => setState(() => _selectedSeverity = severity),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _selectedSeverity == severity
                ? indicatorColor.withOpacity(0.1)
                : colors.bg100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedSeverity == severity
                  ? indicatorColor
                  : colors.bg300.withOpacity(0.2),
              width: _selectedSeverity == severity ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(_spacingMedium),
          transform: _selectedSeverity == severity
              ? Matrix4.identity().scaled(1.02) // Slight scale up when selected
              : Matrix4.identity(),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: _spacingMedium),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: colors.text200,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms), // Subtle fade-in effect
      );

  /// Builds the treatment tabs section
  Widget _buildTreatmentTabs(AppColorTheme colors) => Container(
    decoration: _buildCardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.healing,
              color: colors.accent200,
            ),
            const SizedBox(width: _spacingMedium),
            Text(
              'Treatment by Severity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        _buildTreatmentContent(colors),
      ],
    ),
  );

  /// Returns the color based on selected severity
  Color _getSeverityColor() {
    switch (_selectedSeverity) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'minor':
        return Colors.green;
      default:
        return Colors.grey; // Fallback
    }
  }

  /// Builds the treatment content based on selected severity
  Widget _buildTreatmentContent(AppColorTheme colors) {
    final Map<String, Widget> treatments = {
      'severe': _buildSevereTreatment(colors),
      'moderate': _buildModerateTreatment(colors),
      'minor': _buildMinorTreatment(colors),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: treatments[_selectedSeverity] ??
          const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  /// Builds treatment steps for severe bleeding
  Widget _buildSevereTreatment(AppColorTheme colors) => _buildTreatmentSteps(
    colors,
    Colors.red,
    'Requires immediate medical attention!',
    const [
      TreatmentStep(
        'Apply direct pressure with clean cloth or sterile gauze',
        'Press firmly on the wound. If blood soaks through, add more layers without removing the original dressing.',
      ),
      TreatmentStep(
        'Elevate the injured area',
        'Keep the wound above heart level if possible to reduce blood flow.',
      ),
      TreatmentStep(
        'Apply tourniquet if necessary',
        'For life-threatening limb bleeding, place 2-3 inches above wound, not on a joint.',
      ),
      TreatmentStep(
        'Monitor vital signs',
        'Watch for shock signs: rapid breathing, pale skin, confusion. Keep person warm and calm.',
      ),
    ],
  );

  /// Builds treatment steps for moderate bleeding
  Widget _buildModerateTreatment(AppColorTheme colors) => _buildTreatmentSteps(
    colors,
    Colors.orange,
    'Clean and dress the wound promptly',
    const [
      TreatmentStep(
        'Clean the wound thoroughly',
        'Wash with clean water and mild soap. Remove visible debris to prevent infection.',
      ),
      TreatmentStep(
        'Apply direct pressure',
        'Use sterile gauze or clean cloth. Maintain pressure for 10-15 minutes without lifting.',
      ),
      TreatmentStep(
        'Apply antiseptic and bandage',
        'Use antibiotic ointment if available. Cover with sterile dressing, change daily or when soiled.',
      ),
      TreatmentStep(
        'Monitor for infection',
        'Watch for increased pain, redness, swelling, or warmth. Seek care if these appear.',
      ),
    ],
  );

  /// Builds treatment steps for minor bleeding
  Widget _buildMinorTreatment(AppColorTheme colors) => _buildTreatmentSteps(
    colors,
    Colors.green,
    'Basic first aid is sufficient',
    const [
      TreatmentStep(
        'Clean the wound',
        'Gently wash with soap and water. Pat dry with clean cloth or gauze.',
      ),
      TreatmentStep(
        'Apply antiseptic',
        'Use antiseptic wipes or solution to prevent infection. Let it air dry briefly.',
      ),
      TreatmentStep(
        'Cover the wound',
        'Apply an appropriately sized adhesive bandage or gauze. Change daily or when wet.',
      ),
      TreatmentStep(
        'Keep it clean',
        'Keep wound clean and dry. Avoid touching it directly. Wash hands before changing dressing.',
      ),
    ],
  );

  /// Builds treatment steps with a header and list
  Widget _buildTreatmentSteps(
      AppColorTheme colors,
      Color accentColor,
      String header,
      List<TreatmentStep> steps,
      ) =>
      Column(
        key: ValueKey(header),
        children: [
          Container(
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(_spacingMedium),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: accentColor, size: 20),
                const SizedBox(width: _spacingSmall),
                Expanded(
                  child: Text(
                    header,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _spacingLarge),
          ...steps.asMap().entries.map((entry) {
            final int index = entry.key;
            final TreatmentStep step = entry.value;
            return _buildStep(
              context: context,
              colors: colors,
              stepNumber: index + 1,
              title: step.title,
              icon: _getStepIcon(index),
              content: _buildStepContent(colors, step.description),
            );
          }).toList(),
        ],
      );

  /// Gets appropriate icon for each step
  IconData _getStepIcon(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return Icons.healing;
      case 1:
        return Icons.height;
      case 2:
        return Icons.medical_services;
      case 3:
        return Icons.monitor_heart;
      default:
        return Icons.check_circle;
    }
  }

  /// Builds the content area for each step
  Widget _buildStepContent(AppColorTheme colors, String description) => Container(
    padding: const EdgeInsets.all(_paddingValue),
    decoration: BoxDecoration(
      color: colors.bg100.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      description,
      style: TextStyle(color: colors.text200),
    ),
  );

  /// Builds a single step
  Widget _buildStep({
    required BuildContext context,
    required AppColorTheme colors,
    required int stepNumber,
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
                    color: _getSeverityColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: colors.bg100,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _spacingMedium),
                Icon(
                  icon,
                  color: _getSeverityColor(),
                ),
                const SizedBox(width: _spacingSmall),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
                    color: _getSeverityColor().withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: content,
            ),
          ],
        ),
      );

  /// Builds the important tips section
  Widget _buildImportantTips(AppColorTheme colors) => Container(
    decoration: _buildCardDecoration(colors),
    padding: const EdgeInsets.all(_paddingValue),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, color: colors.accent200),
            const SizedBox(width: _spacingMedium),
            Text(
              'Important Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        _buildTipCard(
          colors,
          'Protect Yourself',
          Icons.shield,
          'Always wear disposable gloves when treating bleeding wounds to prevent infection transmission.',
          false,
        ),
        const SizedBox(height: _spacingMedium),
        _buildTipCard(
          colors,
          'What Not to Do',
          Icons.cancel_outlined,
          "Don't remove large embedded objects\nDon't apply tourniquet unless trained\nDon't use cotton wool directly on wounds",
          false,
          isBulletList: true,
        ),
        const SizedBox(height: _spacingMedium),
        _buildTipCard(
          colors,
          'Seek Professional Care',
          Icons.favorite_border,
          'When in doubt, always seek medical attention. Better safe than sorry, especially with deep or heavily bleeding wounds.',
          true,
        ),
      ],
    ),
  );

  /// Builds a tip card with optional bullet points
  Widget _buildTipCard(
      AppColorTheme colors,
      String title,
      IconData icon,
      String content,
      bool isWarning, {
        bool isBulletList = false,
      }) =>
      Container(
        padding: const EdgeInsets.all(_paddingValue),
        decoration: BoxDecoration(
          color: isWarning
              ? colors.warning.withOpacity(0.1)
              : colors.bg100.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: isWarning
              ? Border.all(color: colors.warning.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isWarning ? colors.warning : colors.accent200,
                  size: 20,
                ),
                const SizedBox(width: _spacingSmall),
                Text(
                  title,
                  style: TextStyle(
                    color: isWarning ? colors.warning : colors.text200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingSmall),
            isBulletList
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.split('\n').map((line) {
                return _buildBulletPoint(colors, line);
              }).toList(),
            )
                : Text(
              content,
              style: TextStyle(
                color: colors.text200,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  /// Builds a bullet point for the list
  Widget _buildBulletPoint(AppColorTheme colors, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 8, right: 8),
          decoration: BoxDecoration(
            color: colors.text200,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.text200,
              fontSize: 14,
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Represents a single treatment step with a title and description
class TreatmentStep {
  final String title;
  final String description;

  const TreatmentStep(this.title, this.description);
}