import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/cpr_audio_service.dart';

class CPRGuideScreen extends StatefulWidget {
  const CPRGuideScreen({super.key});

  @override
  State<CPRGuideScreen> createState() => _CPRGuideScreenState();
}

class _CPRGuideScreenState extends State<CPRGuideScreen> {
  // Constants for consistency and easy tweaking
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  late final CPRAudioService _audioService;
  bool _overlayAdded = false; // Tracks if overlay has been instantiated

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

  /// Updates local state based on service overlay visibility
  void _updateOverlayVisibility() {
    if (mounted) {
      setState(() {
        // Only update visibility, don’t recreate overlay
        if (!_audioService.isOverlayVisible) {
          _overlayAdded = false; // Reset when hidden
        }
      });
    }
  }

  /// Toggles the CPR rhythm audio and shows overlay if not already added
  Future<void> _toggleRhythm(BuildContext context) async {
    try {
      if (_audioService.isPlaying) {
        await _audioService.pauseAudio();
      } else {
        if (!_overlayAdded) {
          setState(() {
            _overlayAdded = true; // Mark overlay as added
            _audioService.setOverlayVisible(true);
          });
        }
        await _audioService.playAudio();
      }
    } catch (e) {
      _showSnackBar(
        context,
        'Failed to ${_audioService.isPlaying ? "pause" : "play"} rhythm: $e',
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: colors.bg200,
        body: SafeArea(
          child: Stack(
            children: [
              _buildContent(context, colors),
              _buildHeader(context, colors),
            ],
          ),
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
            Text(
              'CPR Guide',
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
            _buildEmergencyCall(context, colors),
            const SizedBox(height: _spacingLarge),
            _buildCPRSteps(context, colors),
          ],
        ),
      );

  /// Builds the emergency call section
  Widget _buildEmergencyCall(BuildContext context, AppColorTheme colors) =>
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
                  'Emergency Call',
                  style: TextStyle(
                    color: colors.bg100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingMedium),
            Text(
              'Call Emergency Services First!',
              style: TextStyle(
                color: colors.bg100,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Text(
              'Before starting CPR, ensure help is on the way',
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

  /// Builds the CPR steps section
  Widget _buildCPRSteps(BuildContext context, AppColorTheme colors) => Column(
        children: [
          _buildStep(
            context: context,
            colors: colors,
            stepNumber: 1,
            title: 'Check Response',
            icon: Icons.help_outline,
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
                        'Gently shake the person\'s shoulders and ask loudly:',
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
                          '"Are you okay?"',
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
          _buildStep(
            context: context,
            colors: colors,
            stepNumber: 2,
            title: 'Check Breathing',
            icon: Icons.air,
            content: Column(
              children: [
                _buildCheckItem(
                  icon: Icons.remove_red_eye,
                  text: 'Look for chest movement',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.hearing,
                  text: 'Listen for breathing sounds',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.wind_power,
                  text: 'Feel for breath on your cheek',
                  colors: colors,
                ),
              ],
            ),
          ),
          _buildStep(
            context: context,
            colors: colors,
            stepNumber: 3,
            title: 'Chest Compressions',
            icon: Icons.favorite,
            content: Column(
              children: [
                _buildCheckItem(
                  icon: Icons.gps_fixed,
                  text: 'Place hands in center of chest',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.speed,
                  text: 'Push hard and fast (100-120/min)',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.refresh,
                  text: 'Allow chest to fully recoil',
                  colors: colors,
                ),
                const SizedBox(height: _spacingMedium),
                Container(
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
                          Icon(Icons.music_note,
                              color: colors.accent200, size: 20),
                          const SizedBox(width: _spacingSmall),
                          Text(
                            'Compression Rhythm',
                            style: TextStyle(
                              color: colors.accent200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _spacingSmall),
                      Text(
                        'Follow the beat of "Stayin\' Alive" for perfect tempo!',
                        style: TextStyle(color: colors.text200, fontSize: 14),
                      ),
                      const SizedBox(height: _spacingMedium),
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<CPRAudioService>(
                              builder: (context, audioService, child) =>
                                  ElevatedButton.icon(
                                onPressed: () => _toggleRhythm(context),
                                icon: Icon(
                                  audioService.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  audioService.isPlaying
                                      ? 'Pause Rhythm'
                                      : 'Play Rhythm',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accent200,
                                  foregroundColor: colors.bg100,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: _spacingMedium),
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
                ),
                const SizedBox(height: _spacingMedium),
                _buildWarningBox(
                  colors: colors,
                  title: 'Important Notice',
                  message:
                      'Ribs may break during CPR, especially in older adults. This is normal—prioritize saving a life.',
                ),
              ],
            ),
          ),
          _buildStep(
            context: context,
            colors: colors,
            stepNumber: 4,
            title: 'Rescue Breaths',
            icon: Icons.air,
            content: Column(
              children: [
                _buildCheckItem(
                  icon: Icons.arrow_upward,
                  text: 'Tilt head back gently',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.pan_tool,
                  text: 'Pinch nose closed',
                  colors: colors,
                ),
                _buildCheckItem(
                  icon: Icons.air,
                  text: 'Give 2 breaths (1 sec each)',
                  colors: colors,
                ),
              ],
            ),
          ),
          _buildStep(
            context: context,
            colors: colors,
            stepNumber: 5,
            title: 'Continue CPR Cycles',
            icon: Icons.repeat,
            content: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(_paddingValue),
                  decoration: BoxDecoration(
                    color: colors.bg100.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_list_numbered,
                              color: colors.accent200, size: 20),
                          const SizedBox(width: _spacingSmall),
                          Text(
                            'CPR Cycle Pattern',
                            style: TextStyle(
                              color: colors.text200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: _spacingSmall),
                      _buildBulletPoint('30 chest compressions', colors),
                      _buildBulletPoint('2 rescue breaths', colors),
                      _buildBulletPoint('Repeat until help arrives', colors),
                    ],
                  ),
                ),
                const SizedBox(height: _spacingMedium),
                _buildWarningBox(
                  colors: colors,
                  title: 'Remember',
                  message:
                      'Your efforts can save a life. Stay calm and focused.',
                ),
              ],
            ),
          ),
        ],
      );

  /// Builds a single CPR step
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
                ),
                const SizedBox(width: _spacingMedium),
                Icon(icon, color: colors.accent200),
                const SizedBox(width: _spacingSmall),
                Text(
                  title,
                  style: TextStyle(
                    color: colors.primary300,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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

  /// Builds a check item for CPR steps
  Widget _buildCheckItem({
    required IconData icon,
    required String text,
    required AppColorTheme colors,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: _spacingSmall),
        padding: const EdgeInsets.all(_spacingMedium),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.accent200, size: 20),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.text200),
              ),
            ),
          ],
        ),
      );

  /// Builds a warning box
  Widget _buildWarningBox({
    required AppColorTheme colors,
    required String title,
    required String message,
  }) =>
      Container(
        padding: const EdgeInsets.all(_paddingValue),
        decoration: BoxDecoration(
          color: colors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.warning.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: colors.text200, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// Builds a bullet point for CPR cycle pattern
  Widget _buildBulletPoint(String text, AppColorTheme colors) => Padding(
        padding: const EdgeInsets.only(left: _spacingMedium, top: 4),
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
            const SizedBox(width: _spacingSmall),
            Text(
              text,
              style: TextStyle(color: colors.text200),
            ),
          ],
        ),
      );

  /// Initiates an emergency phone call
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
