import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/services/cpr_audio_service.dart';

class CPRRhythmOverlay extends StatefulWidget {
  const CPRRhythmOverlay({
    super.key,
    required this.colors,
  });

  final AppColorTheme colors;

  @override
  State<CPRRhythmOverlay> createState() => _CPRRhythmOverlayState();
}

class _CPRRhythmOverlayState extends State<CPRRhythmOverlay>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(16, 16); // Initial position
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  // Constants for consistency and easy tweaking
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles the expanded state of the overlay
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final CPRAudioService audioService = Provider.of<CPRAudioService>(context);
    final Size screenSize = MediaQuery.of(context).size;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onPanUpdate: (details) => _updatePosition(details, screenSize),
              child: Container(
                width: _isExpanded ? 320 : 300,
                decoration: BoxDecoration(
                  color: widget.colors.accent200,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(audioService),
                    SizeTransition(
                      sizeFactor: _animation,
                      child: _buildExpandedContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Updates the overlay position within screen bounds
  void _updatePosition(DragUpdateDetails details, Size screenSize) {
    setState(() {
      final Offset newPosition = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
      _position = Offset(
        newPosition.dx.clamp(0, screenSize.width - (_isExpanded ? 320 : 300)),
        newPosition.dy.clamp(0, screenSize.height - (_isExpanded ? 200 : 80)),
      );
    });
  }

  /// Builds the header with controls
  Widget _buildHeader(CPRAudioService audioService) => Stack(
    children: [
      Container(
        padding: const EdgeInsets.all(_paddingValue),
        decoration: BoxDecoration(
          border: Border(
            bottom: _isExpanded
                ? BorderSide(color: widget.colors.bg100.withOpacity(0.1))
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.music_note, color: widget.colors.bg100),
            const SizedBox(width: _spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CPR Rhythm',
                    style: TextStyle(
                      color: widget.colors.bg100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Stayin\' Alive - 100-120 BPM',
                    style: TextStyle(
                      color: widget.colors.bg100.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: widget.colors.bg100,
              ),
              onPressed: _toggleExpanded,
            ),
            IconButton(
              icon: Icon(
                audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.colors.bg100,
              ),
              onPressed: () => _toggleAudio(audioService),
            ),
          ],
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            onTap: () => _hideOverlay(audioService),
            child: Container(
              padding: const EdgeInsets.all(_spacingSmall),
              decoration: BoxDecoration(
                color: widget.colors.bg100.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.close,
                color: widget.colors.bg100,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  /// Builds the expanded content with CPR tips
  Widget _buildExpandedContent() => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: _paddingValue,
      vertical: _spacingMedium,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: widget.colors.bg100, size: 16),
            const SizedBox(width: _spacingSmall),
            Text(
              'CPR Tips',
              style: TextStyle(
                color: widget.colors.bg100,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingSmall),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactTip(Icons.timer, '100-120 BPM'),
            const SizedBox(height: 4),
            _buildCompactTip(Icons.touch_app, 'Push 6 cm deep'),
            const SizedBox(height: 4),
            _buildCompactTip(Icons.refresh, 'Allow recoil'),
          ],
        ),
        const SizedBox(height: _spacingMedium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Drag to move overlay',
              style: TextStyle(
                color: widget.colors.bg100.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            Text(
              '• Tap arrows to expand/collapse',
              style: TextStyle(
                color: widget.colors.bg100.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            Text(
              '• Tap play/pause for rhythm',
              style: TextStyle(
                color: widget.colors.bg100.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// Builds a compact CPR tip row
  Widget _buildCompactTip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: widget.colors.bg100, size: 14),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          color: widget.colors.bg100.withOpacity(0.9),
          fontSize: 12,
        ),
      ),
    ],
  );

  /// Toggles audio playback
  Future<void> _toggleAudio(CPRAudioService audioService) async {
    try {
      if (audioService.isPlaying) {
        await audioService.pauseAudio();
      } else {
        await audioService.playAudio();
      }
    } catch (e) {
      _showSnackBar('Failed to control audio: $e');
    }
  }

  /// Hides the overlay without exiting the screen
  Future<void> _hideOverlay(CPRAudioService audioService) async {
    try {
      audioService.setOverlayVisible(false); // Stops audio and hides overlay (no await needed)
    } catch (e) {
      _showSnackBar('Failed to hide overlay: $e');
    }
  }

  /// Displays a snackbar with an error message
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}