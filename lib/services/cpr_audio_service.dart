import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// A singleton services to manage CPR audio playback and overlay visibility.
class CPRAudioService extends ChangeNotifier {
  // Singleton instance
  static final CPRAudioService _instance = CPRAudioService._internal();

  /// Factory constructor to return the singleton instance.
  factory CPRAudioService() => _instance;

  /// Private constructor for singleton pattern.
  CPRAudioService._internal() {
    _initializeAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isOverlayVisible = false;

  /// Whether the CPR rhythm audio is currently playing.
  bool get isPlaying => _isPlaying;

  /// Whether the CPR rhythm overlay is visible.
  bool get isOverlayVisible => _isOverlayVisible;

  /// The underlying audio player instance.
  AudioPlayer get audioPlayer => _audioPlayer;

  /// Initializes the audio player with default settings.
  void _initializeAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the CPR rhythm by default
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed && _isPlaying) {
        // Handle completion if needed; currently loops due to ReleaseMode.loop
      }
    });
  }

  /// Sets the playing state and notifies listeners.
  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  /// Sets the overlay visibility state and notifies listeners.
  void setOverlayVisible(bool visible) {
    _isOverlayVisible = visible;
    if (!visible) {
      _stopAudio(); // Stop audio when overlay is hidden
    }
    notifyListeners();
  }

  /// Plays the CPR rhythm audio from the specified asset.
  Future<void> playAudio({String assetPath = 'sounds/stayin-alive.mp3'}) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
      setPlaying(true);
    } catch (e) {
      debugPrint('Failed to play CPR audio: $e');
      setPlaying(false);
      rethrow; // Allow callers to handle the error if needed
    }
  }

  /// Pauses the CPR rhythm audio.
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      setPlaying(false);
    } catch (e) {
      debugPrint('Failed to pause CPR audio: $e');
      rethrow;
    }
  }

  /// Stops the CPR rhythm audio and resets the player.
  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      setPlaying(false);
    } catch (e) {
      debugPrint('Failed to stop CPR audio: $e');
      rethrow;
    }
  }

  /// Disposes of the audio player resources.
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}