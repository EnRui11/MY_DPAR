import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for verifying and managing disaster reports in Firestore.
class DisasterVerificationService {
  final FirebaseFirestore _firestore;
  List<DocumentSnapshot> _cachedDisasters = [];

  /// Constructs the services with an optional Firestore instance for testing.
  DisasterVerificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initializes timezone data for Malaysia (UTC+8).
  static Future<void> initializeTimeZone() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
  }

  /// Returns the current timestamp as a Firestore Timestamp.
  static Timestamp getCurrentTimestamp() {
    return Timestamp.now();
  }

  /// Converts a Firestore Timestamp to DateTime.
  static DateTime convertToLocalTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  /// Caches recent disaster reports from Firestore.
  Future<void> cacheDisasters() async {
    try {
      final snapshot = await _firestore
          .collection('disaster_reports')
          .orderBy('timestamp', descending: true)
          .get();
      _cachedDisasters = snapshot.docs;
    } catch (e) {
      debugPrint('Error caching disasters: $e');
      rethrow; // Allow consumers to handle caching errors
    }
  }

  /// Checks for a similar existing disaster within 1km and 1 hour.
  Future<Map<String, dynamic>?> checkExistingDisaster({
    required String disasterType,
    required double latitude,
    required double longitude,
    required Timestamp timestamp,
  }) async {
    try {
      final reportTime = timestamp.toDate();

      for (final doc in _cachedDisasters) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert status to lowercase before checking
        final status = (data['status'] as String?)?.toLowerCase() ?? '';
        if (status == 'past') continue;

        if (!_isMatchingDisaster(
            data, disasterType, reportTime, latitude, longitude)) {
          continue;
        }

        return {
          'id': doc.id,
          ...data,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error checking existing disasters: $e');
      return null;
    }
  }

  /// Updates an existing disaster with new verification data.
  Future<void> updateExistingDisaster({
    required String disasterId,
    required String userId,
    required double latitude,
    required double longitude,
    required String severity,
    required String description,
    required List<String> photoPaths,
    required String disasterType,
    required Timestamp timestamp,
  }) async {
    try {
      final docRef = _firestore.collection('disaster_reports').doc(disasterId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create new disaster instead of throwing error
        await createNewDisaster(
          disasterType: disasterType,
          userId: userId,
          latitude: latitude,
          longitude: longitude,
          severity: severity,
          description: description,
          photoPaths: photoPaths,
          timestamp: timestamp,
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Ensure first reporter's location is in locationList
      if ((data['locationList'] as List<dynamic>?)?.isEmpty ?? true) {
        data['locationList'] = [
          {
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'timestamp': data['timestamp'],
          }
        ];
      }

      final updatedData = _prepareUpdatedDisasterData(
        data,
        userId,
        latitude,
        longitude,
        severity,
        description,
        photoPaths,
      );

      await docRef.update(updatedData);
    } catch (e) {
      debugPrint('Error updating existing disaster: $e');
      throw Exception('Failed to update disaster: $e');
    }
  }

  /// Checks if a disaster matches the criteria for type, time, and proximity.
  bool _isMatchingDisaster(
    Map<String, dynamic> data,
    String disasterType,
    DateTime reportTime,
    double latitude,
    double longitude,
  ) {
    if (data['disasterType'] != disasterType) return false;

    final lat = data['latitude'] as double?;
    final lon = data['longitude'] as double?;
    if (lat == null || lon == null) return false;

    final distance = Geolocator.distanceBetween(latitude, longitude, lat, lon);
    return distance <= 5000; // 5km radius
  }

  /// Prepares data for updating an existing disaster.
  Map<String, dynamic> _prepareUpdatedDisasterData(
    Map<String, dynamic> existingData,
    String userId,
    double latitude,
    double longitude,
    String severity,
    String description,
    List<String> photoPaths,
  ) {
    final userList = List<String>.from(existingData['userList'] ?? []);
    final locationList =
        List<Map<String, dynamic>>.from(existingData['locationList'] ?? []);
    final isNewUser = !userList.contains(userId);

    if (isNewUser) userList.add(userId);
    locationList.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': getCurrentTimestamp(),
    });

    final verifyNum = (existingData['verifyNum'] ?? 0) + (isNewUser ? 1 : 0);
    final status =
        verifyNum >= 2 ? 'Happening' : existingData['status'] ?? 'pending';

    return {
      'severity': severity,
      'description': description,
      'photoPaths': photoPaths,
      'userList': userList,
      'locationList': locationList,
      'verifyNum': verifyNum,
      'status': status,
      'lastUpdated': getCurrentTimestamp(),
    };
  }

  /// Creates a new disaster report with initial data
  Future<void> createNewDisaster({
    required String disasterType,
    required String userId,
    required double latitude,
    required double longitude,
    required String severity,
    required String description,
    required List<String> photoPaths,
    required Timestamp timestamp,
  }) async {
    try {
      final locationList = [
        {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': timestamp,
        }
      ];

      await _firestore.collection('disaster_reports').add({
        'disasterType': disasterType,
        'userList': [userId],
        'locationList': locationList,
        'verifyNum': 1,
        'status': 'pending',
        'severity': severity,
        'description': description,
        'photoPaths': photoPaths,
        'timestamp': timestamp,
        'lastUpdated': timestamp,
        'latitude': latitude, // store initial location
        'longitude': longitude,
      });
    } catch (e) {
      debugPrint('Error creating new disaster: $e');
      throw Exception('Failed to create disaster: $e');
    }
  }
}
