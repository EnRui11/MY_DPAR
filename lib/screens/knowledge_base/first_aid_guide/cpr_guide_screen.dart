import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/cpr_audio_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

/// A screen providing a step-by-step CPR guide with multi-language support and audio rhythm.
///
/// Displays emergency call instructions, CPR steps, and integrates an audio services for compression rhythm.
class CPRGuideScreen extends StatefulWidget {
  const CPRGuideScreen({super.key});

  @override
  State<CPRGuideScreen> createState() => _CPRGuideScreenState();
}

class _CPRGuideScreenState extends State<CPRGuideScreen> {
  // Constants for consistent padding and spacing
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  late final CPRAudioService _audioService;
  bool _overlayAdded = false;

  @override
  void initState() {
    super.initState();
    _audioService = Provider.of<CPRAudioService>(context, listen: false);
    _audioService.addListener(_updateOverlayVisibility);
  }

  @override
  void dispose() {
    _audioService.removeListener(_updateOverlayVisibility);
    super.dispose();
  }

  /// Updates overlay visibility based on audio services state.
  void _updateOverlayVisibility() {
    if (mounted) {
      setState(() {
        if (!_audioService.isOverlayVisible) _overlayAdded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: colors.bg200,
        body: SafeArea(
          child: _CPRGuideContent(
            colors: colors,
            audioService: _audioService,
            onToggleRhythm: () => _toggleRhythm(context),
          ),
        ),
      ),
    );
  }

  /// Toggles the CPR rhythm audio and manages overlay visibility.
  Future<void> _toggleRhythm(BuildContext context) async {
    try {
      if (_audioService.isPlaying) {
        await _audioService.pauseAudio();
      } else {
        if (!_overlayAdded) {
          setState(() {
            _overlayAdded = true;
            _audioService.setOverlayVisible(true);
          });
        }
        await _audioService.playAudio();
      }
    } catch (e) {
      _showSnackBar(
        context,
        AppLocalizations.of(context).translate('error_with_code', {
          'message': _audioService.isPlaying ? 'pause' : 'play',
          'code': e.toString(),
        }),
        Colors.red,
      );
    }
  }

  /// Displays a snackbar with a localized message.
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

/// Encapsulates the main content of the CPR guide screen.
class _CPRGuideContent extends StatelessWidget {
  final AppColorTheme colors;
  final CPRAudioService audioService;
  final VoidCallback onToggleRhythm;

  const _CPRGuideContent({
    required this.colors,
    required this.audioService,
    required this.onToggleRhythm,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            _CPRGuideScreenState._paddingValue,
            70,
            _CPRGuideScreenState._paddingValue,
            _CPRGuideScreenState._paddingValue,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: _CPRGuideScreenState._spacingLarge),
              _EmergencyCall(colors: colors),
              const SizedBox(height: _CPRGuideScreenState._spacingLarge),
              _CPRSteps(colors: colors, onToggleRhythm: onToggleRhythm),
            ],
          ),
        ),
        _Header(colors: colors),
      ],
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
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _CPRGuideScreenState._paddingValue,
        vertical: _CPRGuideScreenState._paddingValue - 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: _CPRGuideScreenState._spacingSmall),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate('cpr_guide'),
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

/// Displays the emergency call section with a localized warning and call button.
class _EmergencyCall extends StatelessWidget {
  final AppColorTheme colors;

  const _EmergencyCall({required this.colors});

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
              const SizedBox(width: _CPRGuideScreenState._spacingSmall),
              Text(
                l.translate('emergency_warning'),
                style: TextStyle(
                  color: colors.bg100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: _CPRGuideScreenState._spacingMedium),
          Text(
            l.translate('call_emergency_services'),
            style: TextStyle(
              color: colors.bg100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _CPRGuideScreenState._spacingSmall),
          Text(
            l.translate('call_before_cpr'),
            style: TextStyle(color: colors.bg100.withOpacity(0.8)),
          ),
          const SizedBox(height: _CPRGuideScreenState._spacingLarge),
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
                padding: const EdgeInsets.symmetric(vertical: _CPRGuideScreenState._spacingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  /// Initiates an emergency call with error handling.
  Future<void> _makeEmergencyCall(BuildContext context) async {
    const emergencyNumber = 'tel:999';
    final url = Uri.parse(emergencyNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showErrorSnackBar(context, AppLocalizations.of(context).translate('call_error_no_launch'));
      }
    } catch (e) {
      _showErrorSnackBar(context, AppLocalizations.of(context).translate('call_error', {'error': e.toString()}));
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

/// Displays the CPR steps with localized content and rhythm audio toggle.
class _CPRSteps extends StatelessWidget {
  final AppColorTheme colors;
  final VoidCallback onToggleRhythm;

  const _CPRSteps({required this.colors, required this.onToggleRhythm});

  @override
  Widget build(BuildContext context) {
    final steps = _CPRStepsProvider.getSteps(context, colors, onToggleRhythm);
    return Column(
      children: steps
          .asMap()
          .entries
          .map((entry) => entry.value.animate().fadeIn(
        duration: 400.ms,
        delay: (entry.key * 100).ms,
      ))
          .toList(),
    );
  }
}

/// A single CPR step card with localized title and content.
class _CPRStepCard extends StatelessWidget {
  final AppColorTheme colors;
  final int stepNumber;
  final String titleKey;
  final IconData icon;
  final Widget content;

  const _CPRStepCard({
    required this.colors,
    required this.stepNumber,
    required this.titleKey,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: _CPRGuideScreenState._spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepNumber(),
              const SizedBox(width: _CPRGuideScreenState._spacingMedium),
              Icon(icon, color: colors.accent200),
              const SizedBox(width: _CPRGuideScreenState._spacingSmall),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate(titleKey),
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
              top: _CPRGuideScreenState._spacingMedium,
              bottom: _CPRGuideScreenState._spacingMedium,
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
  }

  Widget _buildStepNumber() => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: colors.accent200,
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
}

/// A reusable card widget for consistent styling with gradient background.
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_CPRGuideScreenState._paddingValue),
      child: child,
    );
  }
}

/// A reusable check item widget for CPR steps.
class _CheckItem extends StatelessWidget {
  final AppColorTheme colors;
  final IconData icon;
  final String textKey;

  const _CheckItem({
    required this.colors,
    required this.icon,
    required this.textKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: _CPRGuideScreenState._spacingSmall),
      padding: const EdgeInsets.all(_CPRGuideScreenState._spacingMedium),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.accent200, size: 20),
          const SizedBox(width: _CPRGuideScreenState._spacingSmall),
          Expanded(
            child: Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyle(color: colors.text200),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable warning box widget with localized content.
class _WarningBox extends StatelessWidget {
  final AppColorTheme colors;
  final String titleKey;
  final String messageKey;

  const _WarningBox({
    required this.colors,
    required this.titleKey,
    required this.messageKey,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(_CPRGuideScreenState._paddingValue),
      decoration: BoxDecoration(
        color: colors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
          const SizedBox(width: _CPRGuideScreenState._spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.translate(titleKey),
                  style: TextStyle(
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.translate(messageKey),
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Provides CPR steps with localized content and rhythm toggle integration.
class _CPRStepsProvider {
  static List<Widget> getSteps(
      BuildContext context,
      AppColorTheme colors,
      VoidCallback onToggleRhythm,
      ) {
    final l = AppLocalizations.of(context);
    return [
      _CPRStepCard(
        colors: colors,
        stepNumber: 1,
        titleKey: 'check_response',
        icon: Icons.help_outline,
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(_CPRGuideScreenState._paddingValue),
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.translate('shake_and_ask'),
                    style: TextStyle(color: colors.text200),
                  ),
                  const SizedBox(height: _CPRGuideScreenState._spacingSmall),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(_CPRGuideScreenState._paddingValue),
                    decoration: BoxDecoration(
                      color: colors.bg100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.translate('are_you_okay'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.accent200,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _CPRStepCard(
        colors: colors,
        stepNumber: 2,
        titleKey: 'check_breathing',
        icon: Icons.air,
        content: Column(
          children: [
            _CheckItem(colors: colors, icon: Icons.remove_red_eye, textKey: 'look_chest_movement'),
            _CheckItem(colors: colors, icon: Icons.hearing, textKey: 'listen_breathing'),
            _CheckItem(colors: colors, icon: Icons.wind_power, textKey: 'feel_breath'),
          ],
        ),
      ),
      _CPRStepCard(
        colors: colors,
        stepNumber: 3,
        titleKey: 'chest_compressions',
        icon: Icons.favorite,
        content: Column(
          children: [
            _CheckItem(colors: colors, icon: Icons.gps_fixed, textKey: 'place_hands_center'),
            _CheckItem(colors: colors, icon: Icons.speed, textKey: 'push_hard_fast'),
            _CheckItem(colors: colors, icon: Icons.refresh, textKey: 'allow_chest_recoil'),
            const SizedBox(height: _CPRGuideScreenState._spacingMedium),
            _buildRhythmSection(context, colors, onToggleRhythm),
            const SizedBox(height: _CPRGuideScreenState._spacingMedium),
            _WarningBox(
              colors: colors,
              titleKey: 'important_notice',
              messageKey: 'ribs_may_break',
            ),
          ],
        ),
      ),
      _CPRStepCard(
        colors: colors,
        stepNumber: 4,
        titleKey: 'rescue_breaths',
        icon: Icons.air,
        content: Column(
          children: [
            _CheckItem(colors: colors, icon: Icons.arrow_upward, textKey: 'tilt_head_back'),
            _CheckItem(colors: colors, icon: Icons.pan_tool, textKey: 'pinch_nose'),
            _CheckItem(colors: colors, icon: Icons.air, textKey: 'give_two_breaths'),
          ],
        ),
      ),
      _CPRStepCard(
        colors: colors,
        stepNumber: 5,
        titleKey: 'continue_cpr',
        icon: Icons.repeat,
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(_CPRGuideScreenState._paddingValue),
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_list_numbered, color: colors.accent200, size: 20),
                      const SizedBox(width: _CPRGuideScreenState._spacingSmall),
                      Text(
                        l.translate('cpr_cycle_pattern'),
                        style: TextStyle(
                          color: colors.text200,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _CPRGuideScreenState._spacingSmall),
                  _buildBulletPoint(l.translate('thirty_compressions'), colors),
                  _buildBulletPoint(l.translate('two_rescue_breaths'), colors),
                  _buildBulletPoint(l.translate('repeat_until_help'), colors),
                ],
              ),
            ),
            const SizedBox(height: _CPRGuideScreenState._spacingMedium),
            _WarningBox(
              colors: colors,
              titleKey: 'remember',
              messageKey: 'stay_calm_focused',
            ),
          ],
        ),
      ),
    ];
  }

  static Widget _buildRhythmSection(
      BuildContext context,
      AppColorTheme colors,
      VoidCallback onToggleRhythm,
      ) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(_CPRGuideScreenState._paddingValue),
      decoration: BoxDecoration(
        color: colors.primary100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: colors.accent200, size: 20),
              const SizedBox(width: _CPRGuideScreenState._spacingSmall),
              Text(
                l.translate('compression_rhythm'),
                style: TextStyle(
                  color: colors.accent200,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: _CPRGuideScreenState._spacingSmall),
          Text(
            l.translate('follow_stayin_alive'),
            style: TextStyle(color: colors.text200, fontSize: 14),
          ),
          const SizedBox(height: _CPRGuideScreenState._spacingMedium),
          Row(
            children: [
              Expanded(
                child: Consumer<CPRAudioService>(
                  builder: (context, audioService, child) => ElevatedButton.icon(
                    onPressed: onToggleRhythm,
                    icon: Icon(
                      audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: colors.bg100,
                    ),
                    label: Text(
                      audioService.isPlaying
                          ? l.translate('pause_rhythm')
                          : l.translate('play_rhythm'),
                      style: TextStyle(color: colors.bg100),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent200,
                      padding: const EdgeInsets.symmetric(vertical: _CPRGuideScreenState._spacingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildBulletPoint(String text, AppColorTheme colors) => Padding(
    padding: const EdgeInsets.only(left: _CPRGuideScreenState._spacingMedium, top: 4),
    child: Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors.text200,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: _CPRGuideScreenState._spacingSmall),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colors.text200),
          ),
        ),
      ],
    ),
  );
}