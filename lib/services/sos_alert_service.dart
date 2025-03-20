import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mydpar/screens/sos_emergency/sos_emergency_screen.dart';

/// Manages SOS alert state and navigation based on active alerts.
class SOSAlertService extends ChangeNotifier {
  // State variables
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;

  /// Checks for an active alert and navigates to the SOS screen if necessary.
  Future<void> checkActiveAlert(BuildContext context) async {
    if (_isInitialized) return;

    final prefs = await _loadSharedPreferences();
    final alertState = _retrieveAlertState(prefs);

    if (alertState.isActive && alertState.alertId != null) {
      _navigateToSOSEmergencyScreen(context);
    }

    _markAsInitialized();
  }

  /// Loads SharedPreferences instance.
  Future<SharedPreferences> _loadSharedPreferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Failed to load SharedPreferences: $e');
      rethrow; // Consider custom handling in production
    }
  }

  /// Retrieves alert state from SharedPreferences.
  ({bool isActive, String? alertId}) _retrieveAlertState(SharedPreferences prefs) {
    return (
    isActive: prefs.getBool('is_alert_active') ?? false,
    alertId: prefs.getString('active_alert_id'),
    );
  }

  /// Navigates to the SOS emergency screen if the context is mounted.
  void _navigateToSOSEmergencyScreen(BuildContext context) {
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SOSEmergencyScreen()),
      );
    }
  }

  /// Marks the service as initialized and notifies listeners.
  void _markAsInitialized() {
    _isInitialized = true;
    notifyListeners();
  }
}