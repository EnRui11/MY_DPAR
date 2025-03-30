import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for verifying and managing disaster reports in Firestore.
class DisasterVerificationService {
  final FirebaseFirestore _firestore;
  List<DocumentSnapshot> _cachedDisasters = [];

  /// Constructs the service with an optional Firestore instance for testing.
  DisasterVerificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initializes timezone data for Malaysia (UTC+8).
  static Future<void> initializeTimeZone() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
  }

  /// Returns the current timestamp in Malaysia timezone as ISO 8601 string.
  static String getCurrentTimestamp() {
    return tz.TZDateTime.now(tz.local).toIso8601String();
  }

  /// Converts a UTC timestamp to Malaysia timezone.
  static DateTime convertToLocalTime(String timestamp) {
    final utcTime = DateTime.parse(timestamp);
    return tz.TZDateTime.from(utcTime, tz.local);
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
    required String timestamp,
  }) async {
    try {
      final reportTime = convertToLocalTime(timestamp);
      final oneHourAgo = reportTime.subtract(const Duration(hours: 1));

      for (final doc in _cachedDisasters) {
        final data = doc.data() as Map<String, dynamic>;
        if (!_isMatchingDisaster(data, disasterType, oneHourAgo, latitude, longitude)) {
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
  }) async {
    try {
      final docRef = _firestore.collection('disaster_reports').doc(disasterId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Disaster not found');
      }

      final data = doc.data() as Map<String, dynamic>;
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
      DateTime oneHourAgo,
      double latitude,
      double longitude,
      ) {
    if (data['disasterType'] != disasterType) return false;

    final disasterTime = convertToLocalTime(data['timestamp'] as String);
    if (disasterTime.isBefore(oneHourAgo)) return false;

    final lat = data['latitude'] as double?;
    final lon = data['longitude'] as double?;
    if (lat == null || lon == null) return false;

    final distance = Geolocator.distanceBetween(latitude, longitude, lat, lon);
    return distance <= 1000; // 1km radius
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
    final locationList = List<Map<String, dynamic>>.from(existingData['locationList'] ?? []);
    final isNewUser = !userList.contains(userId);

    if (isNewUser) userList.add(userId);
    locationList.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': getCurrentTimestamp(),
    });

    final verifyNum = (existingData['verifyNum'] ?? 0) + (isNewUser ? 1 : 0);
    final status = verifyNum >= 2 ? 'Happening' : existingData['status'] ?? 'pending';

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
}