import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/knowledge_base/cpr_guide_screen.dart';

class BurnsGuideScreen extends StatefulWidget {
  const BurnsGuideScreen({super.key});

  @override
  State<BurnsGuideScreen> createState() => _BurnsGuideScreenState();
}

class _BurnsGuideScreenState extends State<BurnsGuideScreen> {
  // Constants for consistency and easy tweaking
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  String _selectedBurnType = 'thermal';
  String _selectedSeverity = 'first';

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
                  _buildBurnTypeSelection(colors),
                  const SizedBox(height: _spacingLarge),
                  if (_selectedBurnType.isNotEmpty)
                    _buildTreatmentContent(colors),
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
          border:
              Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
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
                'Burns Treatment',
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
                Icon(Icons.warning_amber_rounded,
                    color: colors.bg100, size: 28),
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
                  _buildWarningItem('Burns cover large areas of the body'),
                  _buildWarningItem('Burns on face, hands, feet, or genitals'),
                  _buildWarningItem('Chemical or electrical burns of any size'),
                  _buildWarningItem('Difficulty breathing or severe pain'),
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

  /// Builds the burn type and severity selection section
  Widget _buildBurnTypeSelection(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: _buildCardDecoration(colors),
            padding: const EdgeInsets.all(_paddingValue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: colors.accent200),
                    const SizedBox(width: _spacingMedium),
                    Text(
                      'Burn Assessment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _spacingMedium),
                Text(
                  'Select the type of burn:',
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
                const SizedBox(height: _spacingMedium),
                _buildBurnTypeOption(
                  colors,
                  'thermal',
                  'Thermal Burns',
                  'Heat, fire, or hot objects',
                  Colors.red,
                  Icons.local_fire_department,
                ),
                const SizedBox(height: _spacingSmall),
                _buildBurnTypeOption(
                  colors,
                  'chemical',
                  'Chemical Burns',
                  'Acids, bases, or other chemicals',
                  Colors.orange,
                  Icons.science,
                ),
                const SizedBox(height: _spacingSmall),
                _buildBurnTypeOption(
                  colors,
                  'electrical',
                  'Electrical Burns',
                  'Electric current injuries',
                  Colors.yellow,
                  Icons.bolt,
                ),
              ],
            ),
          ),
          if (_selectedBurnType == 'thermal') ...[
            const SizedBox(height: _spacingLarge),
            Container(
              decoration: _buildCardDecoration(colors),
              padding: const EdgeInsets.all(_paddingValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          color: colors.accent200),
                      const SizedBox(width: _spacingMedium),
                      Text(
                        'Burn Severity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.primary300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _spacingMedium),
                  Text(
                    'Assess the severity of the thermal burn:',
                    style: TextStyle(color: colors.text200, fontSize: 14),
                  ),
                  const SizedBox(height: _spacingMedium),
                  _buildSeverityOption(
                    colors,
                    'first',
                    'First Degree: Superficial - Red, painful, no blisters',
                    Colors.green,
                  ),
                  const SizedBox(height: _spacingSmall),
                  _buildSeverityOption(
                    colors,
                    'second',
                    'Second Degree: Partial thickness - Blisters, very painful',
                    Colors.orange,
                  ),
                  const SizedBox(height: _spacingSmall),
                  _buildSeverityOption(
                    colors,
                    'third',
                    'Third Degree: Full thickness - White/charred, may be painless',
                    Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  /// Builds a burn type option with animation
  Widget _buildBurnTypeOption(
    AppColorTheme colors,
    String burnType,
    String title,
    String description,
    Color indicatorColor,
    IconData icon,
  ) =>
      InkWell(
        onTap: () => setState(() {
          _selectedBurnType = burnType;
          if (burnType != 'thermal') _selectedSeverity = 'first';
        }),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _selectedBurnType == burnType
                ? indicatorColor.withOpacity(0.1)
                : colors.bg100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedBurnType == burnType
                  ? indicatorColor
                  : colors.bg300.withOpacity(0.2),
              width: _selectedBurnType == burnType ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(_spacingMedium),
          transform: _selectedBurnType == burnType
              ? Matrix4.identity().scaled(1.02)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: indicatorColor, size: 20),
                  const SizedBox(width: _spacingMedium),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.text200,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (_selectedBurnType == burnType) ...[
                const SizedBox(height: _spacingSmall),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: colors.text200.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),
      );

  /// Builds a severity option with animation
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
              ? Matrix4.identity().scaled(1.02)
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
        ).animate().fadeIn(duration: 300.ms),
      );

  /// Builds the treatment content section
  Widget _buildTreatmentContent(AppColorTheme colors) => Container(
        decoration: _buildCardDecoration(colors),
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                ),
                const SizedBox(width: _spacingMedium),
                Text(
                  'Treatment Steps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingLarge),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Column(
                key: ValueKey('$_selectedBurnType-$_selectedSeverity'),
                children: _buildTreatmentSteps(colors),
              ),
            ),
          ],
        ),
      );

  /// Builds treatment steps dynamically
  List<Widget> _buildTreatmentSteps(AppColorTheme colors) {
    final steps = _getTreatmentSteps();
    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      return _buildTreatmentStepCard(
        colors,
        stepNumber: index + 1,
        title: step.title,
        content: Text(
          step.description,
          style: TextStyle(color: colors.text200, fontSize: 14),
        ),
        icon: _getStepIcon(index),
      ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms);
    }).toList();
  }

  /// Builds a single treatment step card
  Widget _buildTreatmentStepCard(
    AppColorTheme colors, {
    required int stepNumber,
    required String title,
    required Widget content,
    required IconData icon,
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
                    color: _getTypeColor(),
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
                Icon(icon, color: _getTypeColor()),
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
                    color: _getTypeColor().withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  if (_selectedBurnType == 'electrical' &&
                      title == 'Check Vital Signs') ...[
                    const SizedBox(height: _spacingMedium),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CPRGuideScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.medical_services),
                      label: const Text('View CPR Guide'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary300,
                        foregroundColor: colors.bg100,
                        padding: const EdgeInsets.symmetric(
                          horizontal: _paddingValue,
                          vertical: _spacingSmall,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
            const SizedBox(height: _spacingMedium),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Column(
                key: ValueKey('$_selectedBurnType-$_selectedSeverity-tips'),
                children: _selectedBurnType.isNotEmpty
                    ? _getImportantTips(colors)
                    : [
                        _buildTipCard(
                          colors,
                          'Select Burn Type',
                          Icons.touch_app,
                          'Please select a burn type above to see specific treatment tips.',
                          false,
                        ),
                      ],
              ),
            ),
          ],
        ),
      );

  /// Gets the appropriate icon based on burn type
  IconData _getTypeIcon() {
    switch (_selectedBurnType) {
      case 'thermal':
        return Icons.local_fire_department;
      case 'chemical':
        return Icons.science;
      case 'electrical':
        return Icons.bolt;
      default:
        return Icons.healing;
    }
  }

  /// Gets the appropriate color based on burn type
  Color _getTypeColor() {
    switch (_selectedBurnType) {
      case 'thermal':
        switch (_selectedSeverity) {
          case 'first':
            return Colors.green;
          case 'second':
            return Colors.orange;
          case 'third':
            return Colors.red;
          default:
            return Colors.red; // Default for thermal
        }
      case 'chemical':
        return Colors.orange;
      case 'electrical':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  /// Gets the appropriate icon for each step
  IconData _getStepIcon(int stepIndex) {
    const icons = [
      Icons.healing,
      Icons.water_drop,
      Icons.medical_services,
      Icons.monitor_heart,
    ];
    return icons[stepIndex % icons.length];
  }

  /// Returns treatment steps based on burn type and severity
  List<TreatmentStep> _getTreatmentSteps() {
    switch (_selectedBurnType) {
      case 'thermal':
        switch (_selectedSeverity) {
          case 'first':
            return const [
              TreatmentStep(
                'Cool the Burn',
                'Hold under cool running water for 10-15 minutes. The skin may be red and painful.',
              ),
              TreatmentStep(
                'Clean the Area',
                'Gently wash with mild soap and water to prevent infection.',
              ),
              TreatmentStep(
                'Apply Moisturizer',
                'Use aloe vera or moisturizer to soothe the burned area.',
              ),
              TreatmentStep(
                'Protect the Burn',
                'Cover with loose gauze if needed. Should heal within 3-6 days.',
              ),
            ];
          case 'second':
            return const [
              TreatmentStep(
                'Cool the Burn',
                'Run cool water over the burn for 15-20 minutes. Do not break any blisters.',
              ),
              TreatmentStep(
                'Clean and Assess',
                'Gently clean the area. If burn is larger than 3 inches, seek medical attention.',
              ),
              TreatmentStep(
                'Cover the Burn',
                'Apply antibiotic ointment and cover with sterile gauze. Keep blisters intact.',
              ),
              TreatmentStep(
                'Monitor Healing',
                'Watch for signs of infection. May take 2-3 weeks to heal completely.',
              ),
            ];
          case 'third':
            return const [
              TreatmentStep(
                'Emergency Action',
                'Call emergency services immediately. This is a severe medical emergency.',
              ),
              TreatmentStep(
                'Protect the Area',
                'Cover loosely with clean, sterile cloth or gauze. Do not apply any ointments.',
              ),
              TreatmentStep(
                'Monitor Vital Signs',
                'Check breathing and circulation. Watch for signs of shock.',
              ),
              TreatmentStep(
                'Wait for Help',
                'Keep victim warm and comfortable until medical help arrives.',
              ),
            ];
          default:
            return const [
              TreatmentStep(
                'Select Severity',
                'Please select burn severity to see specific treatment steps.',
              ),
            ];
        }
      case 'chemical':
        return const [
          TreatmentStep(
            'Remove Chemical Source',
            'Brush off dry chemicals, then flush with running water immediately.',
          ),
          TreatmentStep(
            'Continue Rinsing',
            'Keep rinsing the affected area with cool water for at least 20 minutes.',
          ),
          TreatmentStep(
            'Remove Contaminated Items',
            'Take off any clothing or jewelry that has chemical residue.',
          ),
          TreatmentStep(
            'Seek Medical Help',
            'Chemical burns always require professional medical attention.',
          ),
        ];
      case 'electrical':
        return const [
          TreatmentStep(
            'Ensure Safety',
            'Make sure the power source is off and the person is not in contact.',
          ),
          TreatmentStep(
            'Check Vital Signs',
            'Monitor breathing and pulse, be prepared to perform CPR if necessary.',
          ),
          TreatmentStep(
            'Cool Any Burns',
            'If there are thermal burns, cool with clean water.',
          ),
          TreatmentStep(
            'Cover and Monitor',
            'Cover burns with sterile dressing and watch for signs of shock.',
          ),
        ];
      default:
        return const [];
    }
  }

  /// Returns important tips based on burn type and severity
  List<Widget> _getImportantTips(AppColorTheme colors) {
    switch (_selectedBurnType) {
      case 'thermal':
        switch (_selectedSeverity) {
          case 'first':
            return [
              _buildTipCard(
                colors,
                'Home Treatment',
                Icons.home,
                'Can usually be treated at home with basic first aid.',
                false,
              ),
              const SizedBox(height: _spacingSmall),
              _buildTipCard(
                colors,
                'What Not to Do',
                Icons.cancel_outlined,
                "Don't use ice or very cold water\nDon't apply butter or oils\nDon't use cotton balls",
                false,
                isBulletList: true,
              ),
              const SizedBox(height: _spacingSmall),
              _buildTipCard(
                colors,
                'When to Seek Help',
                Icons.medical_services,
                'If the burn affects a large area or shows signs of infection.',
                false,
              ),
            ];
          case 'second':
            return [
              _buildTipCard(
                colors,
                'Medical Attention',
                Icons.local_hospital,
                'Seek medical help if burn is large or on sensitive areas.',
                false,
              ),
              const SizedBox(height: _spacingSmall),
              _buildTipCard(
                colors,
                'Important Warnings',
                Icons.warning_amber_rounded,
                "Don't pop blisters\nDon't remove stuck clothing\nDon't apply home remedies\nDon't use ice",
                false,
                isBulletList: true,
              ),
              const SizedBox(height: _spacingSmall),
              _buildTipCard(
                colors,
                'Critical Signs',
                Icons.warning_amber_rounded,
                'Seek immediate medical care if you notice infection or severe pain.',
                true,
              ),
            ];
          case 'third':
            return [
              _buildTipCard(
                colors,
                'Emergency',
                Icons.emergency,
                'This is a medical emergency requiring immediate professional care.',
                true,
              ),
              const SizedBox(height: _spacingSmall),
              _buildTipCard(
                colors,
                'Critical Don\'ts',
                Icons.dangerous,
                "Don't remove stuck clothing\nDon't apply any ointments\nDon't attempt home treatment\nDon't delay medical care",
                false,
                isBulletList: true,
              ),
              const SizedBox(height: _spacingSmall),
              _buildTipCard(
                colors,
                'While Waiting',
                Icons.access_time_filled,
                'Keep victim warm and watch for signs of shock while waiting for emergency services.',
                true,
              ),
            ];
          default:
            return [
              _buildTipCard(
                colors,
                'Select Severity',
                Icons.touch_app,
                'Please select burn severity to see specific treatment tips.',
                false,
              ),
            ];
        }
      case 'chemical':
        return [
          _buildTipCard(
            colors,
            'Initial Response',
            Icons.cleaning_services,
            'Remove contaminated clothing immediately while protecting yourself. Brush off dry chemicals before rinsing.',
            false,
          ),
          const SizedBox(height: _spacingSmall),
          _buildTipCard(
            colors,
            'What Not to Do',
            Icons.cancel_outlined,
            "Don't try to neutralize the chemical\nDon't apply any creams or ointments\nDon't delay water irrigation\nDon't cover the burn tightly",
            false,
            isBulletList: true,
          ),
          const SizedBox(height: _spacingSmall),
          _buildTipCard(
            colors,
            'Important',
            Icons.warning_amber_rounded,
            'All chemical burns require professional medical attention. Bring the chemical container or name to the hospital.',
            true,
          ),
        ];
      case 'electrical':
        return [
          _buildTipCard(
            colors,
            'Safety First',
            Icons.security,
            "Ensure the power source is off before approaching. Never touch the person if they're still in contact with the electrical source.",
            false,
          ),
          const SizedBox(height: _spacingSmall),
          _buildTipCard(
            colors,
            'What Not to Do',
            Icons.cancel_outlined,
            "Don't move the person unless in immediate danger\nDon't touch the burn areas directly\nDon't remove clothing stuck to burns\nDon't apply any creams or ice",
            false,
            isBulletList: true,
          ),
          const SizedBox(height: _spacingSmall),
          _buildTipCard(
            colors,
            'Critical Warning',
            Icons.warning_amber_rounded,
            'All electrical burns require immediate emergency care. Internal damage may be more severe than visible burns.',
            true,
          ),
        ];
      default:
        return [];
    }
  }

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
                    style: TextStyle(color: colors.text200, fontSize: 14),
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
                style: TextStyle(color: colors.text200, fontSize: 14),
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
  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
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
