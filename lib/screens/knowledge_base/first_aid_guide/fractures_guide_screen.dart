import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';

class FracturesGuideScreen extends StatelessWidget {
  const FracturesGuideScreen({super.key});

  // Constants for consistency and maintainability
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                _paddingValue,
                70, // Space for header
                _paddingValue,
                _paddingValue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _spacingLarge),
                  _EmergencyWarning(colors: colors),
                  const SizedBox(height: _spacingLarge),
                  _InitialAssessment(colors: colors),
                  const SizedBox(height: _spacingLarge),
                  _RiceMethod(colors: colors),
                  const SizedBox(height: _spacingLarge),
                  _AdditionalCare(colors: colors),
                  const SizedBox(height: _spacingLarge),
                  _WhenToSeekHelp(colors: colors),
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
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: FracturesGuideScreen._paddingValue,
        vertical: FracturesGuideScreen._paddingValue - 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: FracturesGuideScreen._spacingSmall),
          Expanded(
            child: Text(
              l.translate('fractures_sprains'),
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

class _EmergencyWarning extends StatelessWidget {
  final AppColorTheme colors;

  const _EmergencyWarning({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _buildCardDecoration(colors, isWarning: true),
      padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.bg100, size: 28),
              const SizedBox(width: FracturesGuideScreen._spacingMedium),
              Text(
                l.translate('emergency_warning'),
                style: TextStyle(
                  color: colors.bg100,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: FracturesGuideScreen._spacingLarge),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.translate('seek_immediate_help'),
                  style: TextStyle(
                    color: colors.bg100,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: FracturesGuideScreen._spacingMedium),
                _buildWarningItem(l.translate('suspected_spinal_neck_injury'), colors),
                _buildWarningItem(l.translate('bone_protruding'), colors),
                _buildWarningItem(l.translate('severe_deformity_pain'), colors),
                _buildWarningItem(l.translate('loss_pulse_sensation'), colors),
              ],
            ),
          ),
          const SizedBox(height: FracturesGuideScreen._spacingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _makeEmergencyCall(context),
              icon: Icon(Icons.phone, color: colors.warning),
              label: Text(
                l.translate('call_emergency'),
                style: TextStyle(color: colors.warning, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.bg100,
                padding: const EdgeInsets.symmetric(vertical: FracturesGuideScreen._spacingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildWarningItem(String text, AppColorTheme colors) => Padding(
    padding: const EdgeInsets.only(bottom: FracturesGuideScreen._spacingSmall),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(right: FracturesGuideScreen._spacingSmall, top: 4),
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

  Future<void> _makeEmergencyCall(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final Uri url = Uri.parse('tel:999');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showSnackBar(context, l.translate('call_error_no_launch'), Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, l.translate('call_error', {'error': e.toString()}), Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _InitialAssessment extends StatelessWidget {
  final AppColorTheme colors;

  const _InitialAssessment({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _buildCardDecoration(colors),
      padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.personal_injury, color: colors.accent200),
              const SizedBox(width: FracturesGuideScreen._spacingMedium),
              Text(
                l.translate('initial_assessment'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          const SizedBox(height: FracturesGuideScreen._spacingMedium),
          _buildAssessmentItem(
            colors,
            Icons.visibility,
            l.translate('look_for_signs'),
            l.translate('swelling_bruising_deformity_wounds'),
          ),
          const SizedBox(height: FracturesGuideScreen._spacingMedium),
          _buildAssessmentItem(
            colors,
            Icons.hearing,
            l.translate('listen_for'),
            l.translate('cracking_pain_description'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildAssessmentItem(AppColorTheme colors, IconData icon, String title, String content) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent200, size: 20),
          const SizedBox(width: FracturesGuideScreen._spacingMedium),
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
                const SizedBox(height: FracturesGuideScreen._spacingSmall),
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
}

class _RiceMethod extends StatelessWidget {
  final AppColorTheme colors;

  const _RiceMethod({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _buildCardDecoration(colors),
      padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, color: colors.accent200),
              const SizedBox(width: FracturesGuideScreen._spacingMedium),
              Text(
                l.translate('rice_method'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          const SizedBox(height: FracturesGuideScreen._spacingLarge),
          _buildStep(
            colors: colors,
            stepInitial: 'R',
            title: l.translate('rest'),
            icon: Icons.hotel,
            content: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
                  decoration: BoxDecoration(
                    color: colors.bg100.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.translate('stop_activity'),
                        style: TextStyle(color: colors.text200),
                      ),
                      const SizedBox(height: FracturesGuideScreen._spacingSmall),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
                        decoration: BoxDecoration(
                          color: colors.bg100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.translate('continuing_movement_warning'),
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
            colors: colors,
            stepInitial: 'I',
            title: l.translate('ice'),
            icon: Icons.ac_unit,
            content: Column(
              children: [
                _buildCheckItem(Icons.access_time, l.translate('apply_15_20_minutes'), colors),
                _buildCheckItem(Icons.wrap_text, l.translate('wrap_ice_pack'), colors),
                _buildCheckItem(Icons.update, l.translate('repeat_2_3_hours'), colors),
              ],
            ),
          ),
          _buildStep(
            colors: colors,
            stepInitial: 'C',
            title: l.translate('compression'),
            icon: Icons.compress,
            content: Column(
              children: [
                _buildCheckItem(Icons.medical_services, l.translate('use_elastic_bandage'), colors),
                _buildCheckItem(Icons.warning, l.translate('not_too_tight'), colors),
                Container(
                  margin: const EdgeInsets.only(top: FracturesGuideScreen._spacingMedium),
                  padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
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
                          const SizedBox(width: FracturesGuideScreen._spacingSmall),
                          Text(
                            l.translate('warning_signs'),
                            style: TextStyle(
                              color: colors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: FracturesGuideScreen._spacingMedium),
                      _buildSubItem(l.translate('numbness_tingling'), colors),
                      _buildSubItem(l.translate('increased_pain'), colors),
                      _buildSubItem(l.translate('cold_bluish_skin'), colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStep(
            colors: colors,
            stepInitial: 'E',
            title: l.translate('elevation'),
            icon: Icons.arrow_upward,
            content: Column(
              children: [
                _buildCheckItem(Icons.height, l.translate('above_heart_level'), colors),
                _buildCheckItem(Icons.timer, l.translate('maintain_24_48_hours'), colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required AppColorTheme colors,
    required String stepInitial,
    required String title,
    required IconData icon,
    required Widget content,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: FracturesGuideScreen._spacingLarge),
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
                const SizedBox(width: FracturesGuideScreen._spacingMedium),
                Icon(icon, color: colors.accent200),
                const SizedBox(width: FracturesGuideScreen._spacingSmall),
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
                top: FracturesGuideScreen._spacingMedium,
                bottom: FracturesGuideScreen._spacingMedium,
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
      ).animate().fadeIn(duration: 400.ms);

  Widget _buildCheckItem(IconData icon, String text, AppColorTheme colors) => Padding(
    padding: const EdgeInsets.only(bottom: FracturesGuideScreen._spacingMedium),
    child: Row(
      children: [
        Icon(icon, color: colors.accent200, size: 20),
        const SizedBox(width: FracturesGuideScreen._spacingMedium),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colors.text200),
          ),
        ),
      ],
    ),
  );

  Widget _buildSubItem(String text, AppColorTheme colors) => Padding(
    padding: const EdgeInsets.only(bottom: FracturesGuideScreen._spacingSmall),
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
  );
}

class _AdditionalCare extends StatelessWidget {
  final AppColorTheme colors;

  const _AdditionalCare({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _buildCardDecoration(colors),
      padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: colors.accent200),
              const SizedBox(width: FracturesGuideScreen._spacingMedium),
              Text(
                l.translate('additional_care'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          const SizedBox(height: FracturesGuideScreen._spacingLarge),
          Container(
            padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
            decoration: BoxDecoration(
              color: colors.bg100.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildCareItem(
                  colors,
                  Icons.medical_services,
                  l.translate('immobilization'),
                  l.translate('use_splints_slings'),
                ),
                const SizedBox(height: FracturesGuideScreen._spacingMedium),
                _buildCareItem(
                  colors,
                  Icons.medication,
                  l.translate('pain_management'),
                  l.translate('pain_relievers_info'),
                ),
                const SizedBox(height: FracturesGuideScreen._spacingMedium),
                _buildCareItem(
                  colors,
                  Icons.monitor_heart,
                  l.translate('monitor'),
                  l.translate('check_circulation'),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCareItem(AppColorTheme colors, IconData icon, String title, String description) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accent200, size: 20),
              const SizedBox(width: FracturesGuideScreen._spacingMedium),
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
            padding: const EdgeInsets.only(left: 32, top: FracturesGuideScreen._spacingSmall),
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
}

class _WhenToSeekHelp extends StatelessWidget {
  final AppColorTheme colors;

  const _WhenToSeekHelp({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent200.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: colors.accent200.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accent200.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_hospital, color: colors.accent200, size: 24),
              ),
              const SizedBox(width: FracturesGuideScreen._spacingMedium),
              Text(
                l.translate('when_to_seek_help'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          const SizedBox(height: FracturesGuideScreen._spacingLarge),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(FracturesGuideScreen._paddingValue),
            decoration: BoxDecoration(
              color: colors.bg200.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: colors.accent200,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpItem(colors, l.translate('unable_bear_weight')),
                _buildHelpItem(colors, l.translate('severe_pain_swelling')),
                _buildHelpItem(colors, l.translate('numbness_tingling')),
                _buildHelpItem(colors, l.translate('visible_deformity')),
                _buildHelpItem(colors, l.translate('open_wounds_bleeding')),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHelpItem(AppColorTheme colors, String text) => Padding(
    padding: const EdgeInsets.only(bottom: FracturesGuideScreen._spacingMedium),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: FracturesGuideScreen._spacingMedium, top: 6),
          decoration: BoxDecoration(
            color: colors.accent200,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.text100,
              height: 1.3,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );
}

// Utility function for card decoration
BoxDecoration _buildCardDecoration(AppColorTheme colors, {bool isWarning = false}) =>
    BoxDecoration(
      gradient: isWarning
          ? LinearGradient(
        colors: [colors.warning, colors.warning.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )
          : null,
      color: isWarning ? null : colors.bg100.withOpacity(0.85),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isWarning ? colors.warning.withOpacity(0.3) : colors.accent200.withOpacity(0.1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );