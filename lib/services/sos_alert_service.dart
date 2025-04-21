import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydpar/screens/sos_emergency/sos_emergency_screen.dart';

/// Manages SOS alert state and navigation based on active alerts.
class SOSAlertService extends ChangeNotifier {
  // State variables
  bool _isInitialized = false;
  List<Map<String, dynamic>> _activeAlerts = [];
  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get activeAlerts => _activeAlerts;
  int get activeAlertsCount => _activeAlerts.length;

  SOSAlertService() {
    _initializeAlertsListener();
  }

  /// Initialize real-time listener for active alerts
  void _initializeAlertsListener() {
    _alertsSubscription = _firestore
        .collection('alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _activeAlerts = snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
      notifyListeners();
    });
  }

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

  /// Get alert details by ID
  Future<Map<String, dynamic>?> getAlertDetails(String alertId) async {
    try {
      final doc = await _firestore.collection('alerts').doc(alertId).get();
      if (doc.exists) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching alert details: $e');
      return null;
    }
  }

  /// Loads SharedPreferences instance.
  Future<SharedPreferences> _loadSharedPreferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Failed to load SharedPreferences: $e');
      rethrow;
    }
  }

  /// Retrieves alert state from SharedPreferences.
  ({bool isActive, String? alertId}) _retrieveAlertState(
      SharedPreferences prefs) {
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

  /// Marks the services as initialized and notifies listeners.
  void _markAsInitialized() {
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
