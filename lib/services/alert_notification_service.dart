import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Service for sending alert notifications to nearby users when incidents are reported
class AlertNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Distance threshold in meters (5km)
  static const double _proximityThreshold = 5000;

  /// Sends alert notifications to users near an incident
  Future<void> alertNearbyUsers({
    required String incidentId,
    required String incidentType,
    required double latitude,
    required double longitude,
    required String severity,
    required String location,
    required String description,
  }) async {
    try {
      // Get current user info
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final reporterName = userDoc.data()?['lastName'] ?? 'A user';

      // Step 1: Retrieve all user IDs and their locations from the "user_locations" collection
      final userLocationsSnapshot =
          await _firestore.collection('user_locations').get();

      // Step 2 & 3: Compare each user's location with the incident location and filter nearby users
      final List<String> nearbyUserIds = [];

      for (final doc in userLocationsSnapshot.docs) {
        // Skip the current user (reporter)
        if (doc.id == currentUser.uid) continue;

        final data = doc.data();

        // Check if location data exists
        final GeoPoint? userLocation = data['location'] as GeoPoint?;
        if (userLocation != null) {
          // Calculate distance between incident and user
          final distance = Geolocator.distanceBetween(latitude, longitude,
              userLocation.latitude, userLocation.longitude);

          // If user is within threshold distance
          if (distance <= _proximityThreshold) {
            // Step 4: Save nearby users into a list
            nearbyUserIds.add(doc.id);
          }
        }
      }

      // Step 5: Proceed with alerting nearby users using the filtered list
      for (final userId in nearbyUserIds) {
        await _sendNotification(
          userId: userId,
          reporterName: reporterName,
          incidentType: incidentType,
          severity: severity,
          location: location,
          description: description,
          incidentId: incidentId,
        );
      }

      debugPrint(
          'Alert sent to ${nearbyUserIds.length} nearby users: ${nearbyUserIds.join(", ")}');
    } catch (e) {
      debugPrint('Error alerting nearby users: $e');
    }
  }

  /// Sends a notification to a specific user
  Future<void> _sendNotification({
    required String userId,
    required String reporterName,
    required String incidentType,
    required String severity,
    required String location,
    required String description,
    required String incidentId,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) return;

      // Create notification data
      final notificationData = {
        'userId': userId,
        'title': '$severity $incidentType Reported Nearby',
        'body':
            '$reporterName reported a $severity $incidentType near $location',
        'type': 'incident_alert',
        'incidentId': incidentId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Save notification to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      // Send FCM notification (this would be handled by Cloud Functions in production)
      // For development purposes, we're just saving to Firestore
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
