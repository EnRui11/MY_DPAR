import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/screens/knowledge_base/first_aid_guide/cpr_guide_screen.dart';

/// A screen providing guidance on treating burns with multi-language support.
///
/// Displays burn type selection, severity assessment (for thermal burns), treatment steps,
/// and important tips, all localized using [AppLocalizations].
class BurnsGuideScreen extends StatefulWidget {
  const BurnsGuideScreen({super.key});

  @override
  State<BurnsGuideScreen> createState() => _BurnsGuideScreenState();
}

class _BurnsGuideScreenState extends State<BurnsGuideScreen> {
  // Constants for consistent padding and spacing
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  // State variables with minimal scope
  String _selectedBurnType = 'thermal';
  String _selectedSeverity = 'first';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: _BurnsGuideContent(
          colors: colors,
          selectedBurnType: _selectedBurnType,
          selectedSeverity: _selectedSeverity,
          onBurnTypeChanged: (type) => _updateBurnType(type),
          onSeverityChanged: (severity) => _updateSeverity(severity),
        ),
      ),
    );
  }

  /// Updates the selected burn type and resets severity if not thermal.
  void _updateBurnType(String type) {
    setState(() {
      _selectedBurnType = type;
      if (type != 'thermal') _selectedSeverity = 'first';
    });
  }

  /// Updates the selected severity for thermal burns.
  void _updateSeverity(String severity) {
    setState(() => _selectedSeverity = severity);
  }
}

/// Encapsulates the main content of the burns guide screen.
///
/// Separates UI logic from state management for better maintainability and testability.
class _BurnsGuideContent extends StatelessWidget {
  final AppColorTheme colors;
  final String selectedBurnType;
  final String selectedSeverity;
  final ValueChanged<String> onBurnTypeChanged;
  final ValueChanged<String> onSeverityChanged;

  const _BurnsGuideContent({
    required this.colors,
    required this.selectedBurnType,
    required this.selectedSeverity,
    required this.onBurnTypeChanged,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            _BurnsGuideScreenState._paddingValue,
            70,
            _BurnsGuideScreenState._paddingValue,
            _BurnsGuideScreenState._paddingValue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
              _EmergencyWarning(colors: colors),
              const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
              _BurnTypeSelection(
                colors: colors,
                selectedBurnType: selectedBurnType,
                selectedSeverity: selectedSeverity,
                onBurnTypeChanged: onBurnTypeChanged,
                onSeverityChanged: onSeverityChanged,
              ),
              const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
              if (selectedBurnType.isNotEmpty)
                _TreatmentContent(
                  colors: colors,
                  burnType: selectedBurnType,
                  severity: selectedSeverity,
                ),
              const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
              _ImportantTips(
                colors: colors,
                burnType: selectedBurnType,
                severity: selectedSeverity,
              ),
            ],
          ),
        ),
        _Header(colors: colors),
      ],
    );
  }
}

/// Displays the header with a back button and title.
class _Header extends StatelessWidget {
  final AppColorTheme colors;

  const _Header({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _BurnsGuideScreenState._paddingValue,
        vertical: _BurnsGuideScreenState._paddingValue - 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: _BurnsGuideScreenState._spacingSmall),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('burns_treatment'),
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

/// Displays an emergency warning with a call button.
class _EmergencyWarning extends StatelessWidget {
  final AppColorTheme colors;

  const _EmergencyWarning({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.warning, colors.warning.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(_BurnsGuideScreenState._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWarningHeader(context),
          const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
          _buildWarningDetails(context),
          const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
          _buildEmergencyButton(context),
        ],
      ),
    );
  }

  Widget _buildWarningHeader(BuildContext context) => Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.bg100, size: 28),
          const SizedBox(width: _BurnsGuideScreenState._spacingMedium),
          Text(
            AppLocalizations.of(context).translate('emergency_warning'),
            style: TextStyle(
              color: colors.bg100,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _buildWarningDetails(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(_BurnsGuideScreenState._paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('seek_immediate_help'),
              style: TextStyle(
                color: colors.bg100,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingMedium),
            _buildWarningItem(context, 'burns_cover_large_areas'),
            _buildWarningItem(context, 'burns_on_sensitive_areas'),
            _buildWarningItem(context, 'chemical_or_electrical_burns'),
            _buildWarningItem(context, 'difficulty_breathing_or_severe_pain'),
          ],
        ),
      );

  Widget _buildWarningItem(BuildContext context, String key) => Padding(
        padding:
            const EdgeInsets.only(bottom: _BurnsGuideScreenState._spacingSmall),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(
                  right: _BurnsGuideScreenState._spacingSmall, top: 4),
            ),
            Expanded(
              child: Text(
                AppLocalizations.of(context).translate(key),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmergencyButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _makeEmergencyCall(context),
          icon: Icon(Icons.phone, color: colors.warning),
          label: Text(
            AppLocalizations.of(context).translate('call_emergency'),
            style: TextStyle(color: colors.warning, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.bg100,
            padding: const EdgeInsets.symmetric(
                vertical: _BurnsGuideScreenState._spacingMedium),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  Future<void> _makeEmergencyCall(BuildContext context) async {
    const emergencyNumber = 'tel:999';
    final url = Uri.parse(emergencyNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showErrorSnackBar(context, 'Could not launch emergency call');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to make call: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Allows selection of burn type and severity (for thermal burns).
class _BurnTypeSelection extends StatelessWidget {
  final AppColorTheme colors;
  final String selectedBurnType;
  final String selectedSeverity;
  final ValueChanged<String> onBurnTypeChanged;
  final ValueChanged<String> onSeverityChanged;

  const _BurnTypeSelection({
    required this.colors,
    required this.selectedBurnType,
    required this.selectedSeverity,
    required this.onBurnTypeChanged,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBurnTypeSection(context),
        if (selectedBurnType == 'thermal') ...[
          const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
          _buildSeveritySection(context),
        ],
      ],
    );
  }

  Widget _buildBurnTypeSection(BuildContext context) => _Card(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'burn_assessment',
              Icons.local_fire_department,
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingMedium),
            Text(
              AppLocalizations.of(context).translate('select_burn_type'),
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingMedium),
            _BurnTypeOption(
              colors: colors,
              burnType: 'thermal',
              titleKey: 'thermal_burns',
              descKey: 'thermal_burns_desc',
              indicatorColor: Colors.red,
              icon: Icons.local_fire_department,
              isSelected: selectedBurnType == 'thermal',
              onTap: onBurnTypeChanged,
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
            _BurnTypeOption(
              colors: colors,
              burnType: 'chemical',
              titleKey: 'chemical_burns',
              descKey: 'chemical_burns_desc',
              indicatorColor: Colors.orange,
              icon: Icons.science,
              isSelected: selectedBurnType == 'chemical',
              onTap: onBurnTypeChanged,
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
            _BurnTypeOption(
              colors: colors,
              burnType: 'electrical',
              titleKey: 'electrical_burns',
              descKey: 'electrical_burns_desc',
              indicatorColor: Colors.yellow,
              icon: Icons.bolt,
              isSelected: selectedBurnType == 'electrical',
              onTap: onBurnTypeChanged,
            ),
          ],
        ),
      );

  Widget _buildSeveritySection(BuildContext context) => _Card(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'burn_severity',
              Icons.local_fire_department,
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingMedium),
            Text(
              AppLocalizations.of(context).translate('assess_burn_severity'),
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingMedium),
            _SeverityOption(
              colors: colors,
              severity: 'first',
              textKey: 'first_degree',
              indicatorColor: Colors.green,
              isSelected: selectedSeverity == 'first',
              onTap: onSeverityChanged,
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
            _SeverityOption(
              colors: colors,
              severity: 'second',
              textKey: 'second_degree',
              indicatorColor: Colors.orange,
              isSelected: selectedSeverity == 'second',
              onTap: onSeverityChanged,
            ),
            const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
            _SeverityOption(
              colors: colors,
              severity: 'third',
              textKey: 'third_degree',
              indicatorColor: Colors.red,
              isSelected: selectedSeverity == 'third',
              onTap: onSeverityChanged,
            ),
          ],
        ),
      );

  Widget _buildSectionHeader(
    BuildContext context,
    String titleKey,
    IconData icon,
  ) =>
      Row(
        children: [
          Icon(icon, color: colors.accent200),
          const SizedBox(width: _BurnsGuideScreenState._spacingMedium),
          Text(
            AppLocalizations.of(context).translate(titleKey),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.primary300,
            ),
          ),
        ],
      );
}

/// A selectable burn type option with animation.
class _BurnTypeOption extends StatelessWidget {
  final AppColorTheme colors;
  final String burnType;
  final String titleKey;
  final String descKey;
  final Color indicatorColor;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _BurnTypeOption({
    required this.colors,
    required this.burnType,
    required this.titleKey,
    required this.descKey,
    required this.indicatorColor,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(burnType),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? indicatorColor.withOpacity(0.1)
              : colors.bg100.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? indicatorColor : colors.bg300.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(_BurnsGuideScreenState._spacingMedium),
        transform:
            isSelected ? Matrix4.identity().scaled(1.02) : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: indicatorColor, size: 20),
                const SizedBox(width: _BurnsGuideScreenState._spacingMedium),
                Text(
                  AppLocalizations.of(context).translate(titleKey),
                  style: TextStyle(
                    color: colors.text200,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  AppLocalizations.of(context).translate(descKey),
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
  }
}

/// A selectable severity option with animation.
class _SeverityOption extends StatelessWidget {
  final AppColorTheme colors;
  final String severity;
  final String textKey;
  final Color indicatorColor;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _SeverityOption({
    required this.colors,
    required this.severity,
    required this.textKey,
    required this.indicatorColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(severity),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? indicatorColor.withOpacity(0.1)
              : colors.bg100.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? indicatorColor : colors.bg300.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(_BurnsGuideScreenState._spacingMedium),
        transform:
            isSelected ? Matrix4.identity().scaled(1.02) : Matrix4.identity(),
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
            const SizedBox(width: _BurnsGuideScreenState._spacingMedium),
            Expanded(
              child: Text(
                AppLocalizations.of(context).translate(textKey),
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
  }
}

/// Displays treatment steps based on burn type and severity.
class _TreatmentContent extends StatelessWidget {
  final AppColorTheme colors;
  final String burnType;
  final String severity;

  const _TreatmentContent({
    required this.colors,
    required this.burnType,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getTypeIcon(burnType),
                  color: getTypeColor(burnType, severity)),
              const SizedBox(width: _BurnsGuideScreenState._spacingMedium),
              Text(
                AppLocalizations.of(context).translate('treatment_steps'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          const SizedBox(height: _BurnsGuideScreenState._spacingLarge),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Column(
              key: ValueKey('$burnType-$severity'),
              children: _buildSteps(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(BuildContext context) {
    final steps = _TreatmentStepsProvider.getSteps(context, burnType, severity);
    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      return _TreatmentStepCard(
        colors: colors,
        stepNumber: index + 1,
        title: step.title,
        description: step.description,
        icon: _getStepIcon(index),
        typeColor: getTypeColor(burnType, severity),
        showCprButton: burnType == 'electrical' &&
            step.title ==
                AppLocalizations.of(context).translate('check_vital_signs'),
      ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms);
    }).toList();
  }

  IconData _getTypeIcon(String burnType) {
    return switch (burnType) {
      'thermal' => Icons.local_fire_department,
      'chemical' => Icons.science,
      'electrical' => Icons.bolt,
      _ => Icons.healing,
    };
  }

  // Changed from private to public method
  Color getTypeColor(String burnType, String severity) {
    return switch (burnType) {
      'thermal' => switch (severity) {
          'first' => Colors.green,
          'second' => Colors.orange,
          'third' => Colors.red,
          _ => Colors.red,
        },
      'chemical' => Colors.orange,
      'electrical' => Colors.yellow,
      _ => Colors.grey,
    };
  }

  IconData _getStepIcon(int stepIndex) {
    const icons = [
      Icons.healing,
      Icons.water_drop,
      Icons.medical_services,
      Icons.monitor_heart,
    ];
    return icons[stepIndex % icons.length];
  }
}

/// A single treatment step card with optional CPR button.
class _TreatmentStepCard extends StatelessWidget {
  final AppColorTheme colors;
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color typeColor;
  final bool showCprButton;

  const _TreatmentStepCard({
    required this.colors,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.typeColor,
    required this.showCprButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: _BurnsGuideScreenState._spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepNumber(),
              const SizedBox(width: _BurnsGuideScreenState._spacingMedium),
              Icon(icon, color: typeColor),
              const SizedBox(width: _BurnsGuideScreenState._spacingSmall),
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
          _buildStepContent(context),
        ],
      ),
    );
  }

  Widget _buildStepNumber() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: typeColor,
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
      );

  Widget _buildStepContent(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 16),
        padding: const EdgeInsets.only(
          left: 24,
          top: _BurnsGuideScreenState._spacingMedium,
          bottom: _BurnsGuideScreenState._spacingMedium,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: typeColor.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
            if (showCprButton) ...[
              const SizedBox(height: _BurnsGuideScreenState._spacingMedium),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CPRGuideScreen()),
                ),
                icon: const Icon(Icons.medical_services),
                label: Text(
                    AppLocalizations.of(context).translate('view_cpr_guide')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary300,
                  foregroundColor: colors.bg100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _BurnsGuideScreenState._paddingValue,
                    vertical: _BurnsGuideScreenState._spacingSmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Displays important tips based on burn type and severity.
class _ImportantTips extends StatelessWidget {
  final AppColorTheme colors;
  final String burnType;
  final String severity;

  const _ImportantTips({
    required this.colors,
    required this.burnType,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: colors.accent200),
              const SizedBox(width: _BurnsGuideScreenState._spacingMedium),
              Text(
                AppLocalizations.of(context).translate('important_tips'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          const SizedBox(height: _BurnsGuideScreenState._spacingMedium),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Column(
              key: ValueKey('$burnType-$severity-tips'),
              children: burnType.isNotEmpty
                  ? _TipsProvider.getTips(context, colors, burnType, severity)
                  : [
                      _TipCard(
                        colors: colors,
                        title: AppLocalizations.of(context)
                            .translate('select_burn_type'),
                        icon: Icons.touch_app,
                        content:
                            'Please select a burn type above to see specific treatment tips.',
                        isWarning: false,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single tip card with optional bullet list formatting.
class _TipCard extends StatelessWidget {
  final AppColorTheme colors;
  final String title;
  final IconData icon;
  final String content;
  final bool isWarning;
  final bool isBulletList;

  const _TipCard({
    required this.colors,
    required this.title,
    required this.icon,
    required this.content,
    required this.isWarning,
    this.isBulletList = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_BurnsGuideScreenState._paddingValue),
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
              const SizedBox(width: _BurnsGuideScreenState._spacingSmall),
              Text(
                title,
                style: TextStyle(
                  color: isWarning ? colors.warning : colors.text200,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
          isBulletList
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content
                      .split('\n')
                      .map((line) => _buildBulletPoint(line))
                      .toList(),
                )
              : Text(
                  content,
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) => Padding(
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
}

/// A reusable card widget for consistent styling.
class _Card extends StatelessWidget {
  final AppColorTheme colors;
  final Widget child;

  const _Card({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
      ),
      padding: const EdgeInsets.all(_BurnsGuideScreenState._paddingValue),
      child: child,
    );
  }
}

/// Provides treatment steps based on burn type and severity.
///
/// Centralizes step data for consistency and reusability.
class _TreatmentStepsProvider {
  static List<TreatmentStep> getSteps(
      BuildContext context, String burnType, String severity) {
    final l = AppLocalizations.of(context);
    return switch (burnType) {
      'thermal' => switch (severity) {
          'first' => [
              TreatmentStep(
                  l.translate('cool_burn'), l.translate('cool_burn_first')),
              TreatmentStep(
                  l.translate('clean_area'), l.translate('clean_area_first')),
              TreatmentStep(l.translate('apply_moisturizer'),
                  l.translate('apply_moisturizer_first')),
              TreatmentStep(l.translate('protect_burn'),
                  l.translate('protect_burn_first')),
            ],
          'second' => [
              TreatmentStep(
                  l.translate('cool_burn'), l.translate('cool_burn_second')),
              TreatmentStep(l.translate('clean_assess'),
                  l.translate('clean_assess_second')),
              TreatmentStep(
                  l.translate('cover_burn'), l.translate('cover_burn_second')),
              TreatmentStep(l.translate('monitor_healing'),
                  l.translate('monitor_healing_second')),
            ],
          'third' => [
              TreatmentStep(l.translate('emergency_action'),
                  l.translate('emergency_action_third')),
              TreatmentStep(l.translate('protect_area'),
                  l.translate('protect_area_third')),
              TreatmentStep(l.translate('monitor_vital_signs'),
                  l.translate('monitor_vital_signs_third')),
              TreatmentStep(l.translate('wait_for_help'),
                  l.translate('wait_for_help_third')),
            ],
          _ => const [],
        },
      'chemical' => [
          TreatmentStep(
            l.translate('remove_chemical_source'),
            l.translate('remove_chemical_source_chemical'),
          ),
          TreatmentStep(l.translate('continue_rinsing'),
              l.translate('continue_rinsing_chemical')),
          TreatmentStep(
            l.translate('remove_contaminated_items'),
            l.translate('remove_contaminated_items_chemical'),
          ),
          TreatmentStep(l.translate('seek_medical_help'),
              l.translate('seek_medical_help_chemical')),
        ],
      'electrical' => [
          TreatmentStep(l.translate('ensure_safety'),
              l.translate('ensure_safety_electrical')),
          TreatmentStep(l.translate('check_vital_signs'),
              l.translate('check_vital_signs_electrical')),
          TreatmentStep(l.translate('cool_any_burns'),
              l.translate('cool_any_burns_electrical')),
          TreatmentStep(l.translate('cover_and_monitor'),
              l.translate('cover_and_monitor_electrical')),
        ],
      _ => const [],
    };
  }
}

/// Provides important tips based on burn type and severity.
///
/// Centralizes tip data for consistency and reusability.
class _TipsProvider {
  static List<Widget> getTips(
    BuildContext context,
    AppColorTheme colors,
    String burnType,
    String severity,
  ) {
    final l = AppLocalizations.of(context);
    return switch (burnType) {
      'thermal' => switch (severity) {
          'first' => [
              _TipCard(
                colors: colors,
                title: l.translate('home_treatment'),
                icon: Icons.home,
                content: l.translate('home_treatment_first'),
                isWarning: false,
              ),
              const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
              _TipCard(
                colors: colors,
                title: l.translate('what_not_to_do'),
                icon: Icons.cancel_outlined,
                content: l.translate('what_not_to_do_thermal_first'),
                isWarning: false,
                isBulletList: true,
              ),
              const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
              _TipCard(
                colors: colors,
                title: l.translate('when_to_seek_help'),
                icon: Icons.medical_services,
                content: l.translate('when_to_seek_help_first'),
                isWarning: false,
              ),
            ],
          'second' => [
              _TipCard(
                colors: colors,
                title: l.translate('medical_attention'),
                icon: Icons.local_hospital,
                content: l.translate('medical_attention_second'),
                isWarning: false,
              ),
              const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
              _TipCard(
                colors: colors,
                title: l.translate('critical_donts'),
                icon: Icons.dangerous,
                content: l.translate('important_warnings_second'),
                isWarning: false,
                isBulletList: true,
              ),
              const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
              _TipCard(
                colors: colors,
                title: l.translate('critical_signs'),
                icon: Icons.warning_amber_rounded,
                content: l.translate('critical_signs_second'),
                isWarning: true,
              ),
            ],
          'third' => [
              _TipCard(
                colors: colors,
                title: l.translate('emergency'),
                icon: Icons.emergency,
                content: l.translate('emergency_third'),
                isWarning: true,
              ),
              const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
              _TipCard(
                colors: colors,
                title: l.translate('critical_donts'),
                icon: Icons.dangerous,
                content: l.translate('critical_donts_third'),
                isWarning: false,
                isBulletList: true,
              ),
              const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
              _TipCard(
                colors: colors,
                title: l.translate('while_waiting'),
                icon: Icons.access_time_filled,
                content: l.translate('while_waiting_third'),
                isWarning: true,
              ),
            ],
          _ => const [],
        },
      'chemical' => [
          _TipCard(
            colors: colors,
            title: l.translate('initial_response'),
            icon: Icons.cleaning_services,
            content: l.translate('initial_response_chemical'),
            isWarning: false,
          ),
          const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
          _TipCard(
            colors: colors,
            title: l.translate('what_not_to_do'),
            icon: Icons.cancel_outlined,
            content: l.translate('what_not_to_do_chemical'),
            isWarning: false,
            isBulletList: true,
          ),
          const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
          _TipCard(
            colors: colors,
            title: l.translate('important_chemical'),
            icon: Icons.warning_amber_rounded,
            content: l.translate('important_chemical_desc'),
            isWarning: true,
          ),
        ],
      'electrical' => [
          _TipCard(
            colors: colors,
            title: l.translate('safety_first'),
            icon: Icons.security,
            content: l.translate('safety_first_electrical'),
            isWarning: false,
          ),
          const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
          _TipCard(
            colors: colors,
            title: l.translate('what_not_to_do'),
            icon: Icons.cancel_outlined,
            content: l.translate('what_not_to_do_electrical'),
            isWarning: false,
            isBulletList: true,
          ),
          const SizedBox(height: _BurnsGuideScreenState._spacingSmall),
          _TipCard(
            colors: colors,
            title: l.translate('critical_warning'),
            icon: Icons.warning_amber_rounded,
            content: l.translate('critical_warning_electrical'),
            isWarning: true,
          ),
        ],
      _ => const [],
    };
  }
}

/// Represents a single treatment step with a title and description.
class TreatmentStep {
  final String title;
  final String description;

  const TreatmentStep(this.title, this.description);
}
