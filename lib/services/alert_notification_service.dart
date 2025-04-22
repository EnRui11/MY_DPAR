import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:mydpar/screens/main/map_screen.dart';
import 'package:mydpar/localization/app_localizations.dart';

/// Service for sending alert notifications to nearby users when disasters or SOS alerts are reported
class AlertNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Distance threshold in meters (5km)
  static const double _proximityThreshold = 5000;

  /// Sends alert notifications to users near a disaster
  Future<void> alertNearbyUsers({
    required BuildContext context,
    required String disasterId,
    required String disasterType,
    required double latitude,
    required double longitude,
    required String severity,
    required String location,
    required String description,
  }) async {
    final l = AppLocalizations.of(context);
    try {
      debugPrint(
          'Starting alertNearbyUsers for disaster $disasterId at ($latitude, $longitude)');

      // Get current user info
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No current user found, aborting notification process');
        return;
      }

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final reporterName = userDoc.data()?['lastName'] ?? l.translate('a_user');
      debugPrint('Reporter name: $reporterName');

      // Step 1: Retrieve all user IDs and their locations from the "user_locations" collection
      final userLocationsSnapshot =
          await _firestore.collection('user_locations').get();
      debugPrint(
          'Found ${userLocationsSnapshot.docs.length} total user locations');

      // Step 2 & 3: Compare each user's location with the disaster location and filter nearby users
      final List<String> nearbyUserIds = [];
      final List<String> skippedUsers = [];
      final List<String> invalidLocations = [];

      for (final doc in userLocationsSnapshot.docs) {
        // Skip the current user (reporter)
        if (doc.id == currentUser.uid) {
          debugPrint('Skipping reporter: ${doc.id}');
          continue;
        }

        final data = doc.data();

        // Check if user is online
        final bool isOnline = data['isOnline'] ?? false;
        if (!isOnline) {
          skippedUsers.add('${doc.id} (${l.translate('offline')})');
          continue;
        }

        // Check if location data exists
        final GeoPoint? userLocation = data['location'] as GeoPoint?;
        if (userLocation != null) {
          // Calculate distance between disaster and user
          final distance = Geolocator.distanceBetween(latitude, longitude,
              userLocation.latitude, userLocation.longitude);

          debugPrint(
              'User ${doc.id} is ${distance.toStringAsFixed(2)}m from disaster');

          // If user is within threshold distance
          if (distance <= _proximityThreshold) {
            nearbyUserIds.add(doc.id);
            debugPrint(
                'Added ${doc.id} to nearby users list (${distance.toStringAsFixed(2)}m away)');
          }
        } else {
          invalidLocations.add(doc.id);
          debugPrint('Invalid location data for user: ${doc.id}');
        }
      }

      debugPrint('Found ${nearbyUserIds.length} nearby users');
      debugPrint('Skipped users: ${skippedUsers.join(', ')}');
      debugPrint('Invalid locations: ${invalidLocations.join(', ')}');

      // Step 5: Proceed with alerting nearby users using the filtered list
      int successCount = 0;
      int failureCount = 0;

      for (final userId in nearbyUserIds) {
        try {
          await _sendNotification(
            context: context,
            userId: userId,
            reporterName: reporterName,
            disasterType: disasterType,
            severity: severity,
            location: location,
            description: description,
            disasterId: disasterId,
            type: 'disaster',
          );
          successCount++;
          debugPrint('Successfully sent notification to user: $userId');
        } catch (e) {
          failureCount++;
          debugPrint('Failed to send notification to user $userId: $e');
        }
      }

      debugPrint('Notification summary:\n'
          'Total nearby users: ${nearbyUserIds.length}\n'
          'Successful notifications: $successCount\n'
          'Failed notifications: $failureCount');
    } catch (e) {
      debugPrint('Error in alertNearbyUsers: $e');
    }
  }

  /// Sends alert notifications to users near an SOS alert
  Future<void> alertNearbyUsersForSOS({
    required BuildContext context,
    required String alertId,
    required String userName,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final l = AppLocalizations.of(context);
    try {
      debugPrint('Starting SOS alert notification process for alert $alertId');

      // Get current user info
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No current user found, aborting notification process');
        return;
      }

      // Step 1: Retrieve all user IDs and their locations from the "user_locations" collection
      debugPrint('Fetching user locations...');
      final userLocationsSnapshot =
          await _firestore.collection('user_locations').get();
      debugPrint('Found ${userLocationsSnapshot.docs.length} total users');

      // Step 2 & 3: Compare each user's location with the SOS location and filter nearby users
      final List<String> nearbyUserIds = [];
      final List<String> skippedUsers = [];
      final List<String> invalidLocations = [];

      for (final doc in userLocationsSnapshot.docs) {
        // Skip the current user (reporter)
        if (doc.id == currentUser.uid) {
          skippedUsers.add(doc.id);
          continue;
        }

        final data = doc.data();

        // Check if location data exists
        final GeoPoint? userLocation = data['location'] as GeoPoint?;
        if (userLocation == null) {
          invalidLocations.add(doc.id);
          continue;
        }

        // Calculate distance between SOS and user
        final distance = Geolocator.distanceBetween(
            latitude, longitude, userLocation.latitude, userLocation.longitude);

        // If user is within threshold distance
        if (distance <= _proximityThreshold) {
          nearbyUserIds.add(doc.id);
          debugPrint(
              'User ${doc.id} is within range (${distance.toStringAsFixed(2)}m)');
        }
      }

      debugPrint('Found ${nearbyUserIds.length} nearby users');
      debugPrint('Skipped users: ${skippedUsers.join(', ')}');
      debugPrint('Invalid locations: ${invalidLocations.join(', ')}');

      // Step 5: Send notifications to nearby users
      int successCount = 0;
      int failureCount = 0;

      for (final userId in nearbyUserIds) {
        try {
          await _sendNotification(
            context: context,
            userId: userId,
            reporterName: userName,
            alertId: alertId,
            address: address,
            type: 'sos',
          );
          successCount++;
          debugPrint('Successfully sent SOS notification to user: $userId');
        } catch (e) {
          failureCount++;
          debugPrint('Failed to send SOS notification to user $userId: $e');
        }
      }

      debugPrint('SOS Notification summary:\n'
          'Total nearby users: ${nearbyUserIds.length}\n'
          'Successful notifications: $successCount\n'
          'Failed notifications: $failureCount');
    } catch (e) {
      debugPrint('Error in alertNearbyUsersForSOS: $e');
      rethrow;
    }
  }

  /// Sends a notification to a specific user
  Future<void> _sendNotification({
    required BuildContext context,
    required String userId,
    required String reporterName,
    String? disasterType,
    String? severity,
    String? location,
    String? description,
    String? disasterId,
    String? alertId,
    String? address,
    required String type,
  }) async {
    final l = AppLocalizations.of(context);
    try {
      // Get user's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        debugPrint('No FCM token found for user $userId');
        return;
      }

      // Create notification data based on type
      final Map<String, dynamic> notificationData;

      if (type == 'disaster') {
        final title = l.translate('disaster_alert_title', {
          'severity': severity,
          'type': l.translate('disaster_type_${disasterType?.toLowerCase()}'),
        });

        final body = l.translate('disaster_alert_body', {
          'name': reporterName,
          'severity': severity,
          'type': l.translate('disaster_type_${disasterType?.toLowerCase()}'),
          'location': location,
        });

        notificationData = {
          'userId': userId,
          'title': title,
          'body': body,
          'type': 'disaster_alert',
          'disasterId': disasterId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        };
      } else {
        final title = l.translate('sos_alert_title');
        final body = l.translate('sos_alert_body', {
          'name': reporterName,
          'address': address,
        });

        notificationData = {
          'userId': userId,
          'title': title,
          'body': body,
          'type': 'sos_alert',
          'alertId': alertId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        };
      }

      // Save notification to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      // Send FCM notification using Cloud Functions
      await _firestore.collection('notification_queue').add({
        'token': fcmToken,
        'notification': {
          'title': notificationData['title'],
          'body': notificationData['body'],
        },
        'data': {
          'type': notificationData['type'],
          'id': disasterId ?? alertId ?? '',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('Notification queued for user $userId with token $fcmToken');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Sets up notification handlers for when the app is in the foreground
  void setupForegroundNotificationHandlers(BuildContext context) {
    final l = AppLocalizations.of(context);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.data}');

      // Handle the notification based on its type
      final String? type = message.data['type'];
      final String? id = message.data['disasterId'] ?? message.data['alertId'];

      if (type != null && id != null) {
        // Show a local notification
        _showLocalNotification(message);
      }
    });

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.data}');
      _handleNotificationTap(context, message.data);
    });
  }

  /// Shows a local notification when the app is in the foreground
  void _showLocalNotification(RemoteMessage message) {
    // This would be implemented with flutter_local_notifications
    // For now, we'll just log the notification
    debugPrint('Showing local notification: ${message.notification?.title}');
  }

  /// Handles navigation when a notification is tapped
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? id = data['disasterId'] ?? data['alertId'];

    if (type == null || id == null) return;

    // Navigate to the map screen with the appropriate marker selected
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          initialMarkerId: id,
          initialMarkerType: type == 'disaster_alert' ? 'Disaster' : 'SOS',
        ),
      ),
    );
  }
}
