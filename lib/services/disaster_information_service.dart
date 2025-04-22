import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/localization/app_localizations.dart';

/// Model for disaster data with consistent structure across the app
class DisasterModel {
  final String id;
  final String userId;
  final String disasterType;
  final String? otherDisasterType;
  final String severity;
  final String location;
  final LatLng? coordinates;
  final String description;
  final List<String>? photoPaths;
  final Timestamp timestamp;
  final String status;
  final List<String>? userList;
  final List<Map<String, dynamic>>? locationList;
  final int verificationCount;
  final int verifyFalseNum;
  final Timestamp? lastUpdated;

  DisasterModel({
    required this.id,
    required this.userId,
    required this.disasterType,
    this.otherDisasterType,
    required this.severity,
    required this.location,
    this.coordinates,
    required this.description,
    this.photoPaths,
    required this.timestamp,
    required this.status,
    this.userList,
    this.locationList,
    required this.verificationCount,
    this.verifyFalseNum = 0,
    this.lastUpdated,
  });

  factory DisasterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisasterModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      disasterType: data['disasterType'] ?? '',
      otherDisasterType: data['otherDisasterType'],
      severity: data['severity'] ?? '',
      location: data['location'] ?? '',
      coordinates: data['latitude'] != null && data['longitude'] != null
          ? LatLng(data['latitude'], data['longitude'])
          : null,
      description: data['description'] ?? '',
      photoPaths: (data['photoPaths'] as List<dynamic>?)?.cast<String>(),
      timestamp: data['timestamp'] as Timestamp,
      status: data['status'] ?? 'happening',
      userList: (data['userList'] as List<dynamic>?)?.cast<String>(),
      locationList: (data['locationList'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      verificationCount: data['verifyNum'] ?? 0,
      verifyFalseNum: data['verifyFalseNum'] ?? 0,
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  /// Check if the disaster is currently happening
  bool get isHappening {
    try {
      return status.toLowerCase() == 'happening';
    } catch (e) {
      return false;
    }
  }

  /// Convert to a formatted time string (e.g., "2 hours ago")
  String get formattedTime {
    try {
      final DateTime disasterTime = timestamp.toDate();
      final Duration difference = DateTime.now().difference(disasterTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return timestamp.toString();
    }
  }

  /// Convert to a map for JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'disasterType': disasterType,
        'otherDisasterType': otherDisasterType,
        'description': description,
        'severity': severity,
        'location': location,
        'timestamp': timestamp,
        'status': status,
        'verifyNum': verificationCount,
        'verifyFalseNum': verifyFalseNum,
        'lastUpdated': lastUpdated,
        'userList': userList,
        'locationList': locationList,
        'photoPaths': photoPaths,
        'latitude': coordinates?.latitude,
        'longitude': coordinates?.longitude,
      };

  /// Create a copy of this model with updated fields
  DisasterModel copyWith({
    String? id,
    String? userId,
    String? disasterType,
    String? otherDisasterType,
    String? severity,
    String? location,
    LatLng? coordinates,
    String? description,
    List<String>? photoPaths,
    Timestamp? timestamp,
    String? status,
    List<String>? userList,
    List<Map<String, dynamic>>? locationList,
    int? verificationCount,
    int? verifyFalseNum,
    Timestamp? lastUpdated,
  }) {
    return DisasterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      disasterType: disasterType ?? this.disasterType,
      otherDisasterType: otherDisasterType ?? this.otherDisasterType,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      description: description ?? this.description,
      photoPaths: photoPaths ?? this.photoPaths,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      userList: userList ?? this.userList,
      locationList: locationList ?? this.locationList,
      verificationCount: verificationCount ?? this.verificationCount,
      verifyFalseNum: verifyFalseNum ?? this.verifyFalseNum,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Service for fetching and managing disaster data
class DisasterService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DisasterModel> _disasters = [];
  List<DisasterModel> _happeningDisasters = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DisasterModel> get disasters => _disasters;
  List<DisasterModel> get happeningDisasters => _happeningDisasters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Returns an icon based on the disaster type.
  static IconData getDisasterIcon(String type) {
    const flood = IconData(0xf07a3, fontFamily: 'MaterialIcons');
    const tsunami = IconData(0xf07cf, fontFamily: 'MaterialIcons');

    return switch (type.toLowerCase()) {
      'heavy_rain' => Icons.thunderstorm_outlined,
      'flood' => flood,
      'fire' => Icons.local_fire_department,
      'earthquake' => Icons.terrain,
      'landslide' => Icons.landslide,
      'tsunami' => tsunami,
      'haze' => Icons.air,
      'typhoon' => Icons.cyclone,
      'weather' => Icons.thunderstorm,
      'other' => Icons.warning_amber_rounded,
      _ => Icons.error_outline,
    };
  }

  /// Returns a color based on severity level.
  static Color getSeverityColor(String severity, AppColorTheme colors) {
    switch (severity.toLowerCase()) {
      case 'high':
        return colors.warning;
      case 'medium':
        return const Color(0xFFFF8C00); // Orange
      case 'low':
        return const Color(0xFF71C4EF); // Light blue
      default:
        return colors.text200;
    }
  }

  /// Fetch all disasters from Firestore
  Future<void> fetchDisasters({bool onlyHappening = false}) async {
    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('disaster_reports')
          .orderBy('timestamp', descending: true)
          .get();

      _disasters =
          snapshot.docs.map((doc) => DisasterModel.fromFirestore(doc)).toList();

      // Filter for happening disasters
      _happeningDisasters =
          _disasters.where((disaster) => disaster.isHappening).toList();

      _error = null;
    } catch (e) {
      debugPrint('Error fetching disasters: $e');
      _error = 'Failed to load disasters: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch recent disasters (limited number)
  Future<void> fetchRecentDisasters(
      {int limit = 5, bool onlyHappening = true}) async {
    _setLoading(true);
    try {
      // First, get more disasters than needed to ensure we have enough after filtering
      final int fetchLimit = onlyHappening ? limit * 2 : limit;

      final snapshot = await _firestore
          .collection('disaster_reports')
          .orderBy('timestamp', descending: true)
          .limit(fetchLimit)
          .get();

      _disasters =
          snapshot.docs.map((doc) => DisasterModel.fromFirestore(doc)).toList();

      // Filter for happening disasters
      _happeningDisasters =
          _disasters.where((disaster) => disaster.isHappening).toList();

      // Limit the happening disasters to the requested number
      if (_happeningDisasters.length > limit) {
        _happeningDisasters = _happeningDisasters.sublist(0, limit);
      }

      _error = null;
    } catch (e) {
      debugPrint('Error fetching recent disasters: $e');
      _error = 'Failed to load recent disasters: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch disasters by type
  Future<void> fetchDisastersByType(String disasterType,
      {bool onlyHappening = true}) async {
    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('disaster_reports')
          .where('disasterType', isEqualTo: disasterType)
          .orderBy('timestamp', descending: true)
          .get();

      _disasters =
          snapshot.docs.map((doc) => DisasterModel.fromFirestore(doc)).toList();

      // Filter for happening disasters
      if (onlyHappening) {
        _happeningDisasters =
            _disasters.where((disaster) => disaster.isHappening).toList();
      } else {
        _happeningDisasters = _disasters;
      }

      _error = null;
    } catch (e) {
      debugPrint('Error fetching disasters by type: $e');
      _error = 'Failed to load disasters: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Helper method to set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Fetch a specific disaster by ID
  Future<DisasterModel?> getDisasterById(String disasterId) async {
    try {
      final doc =
          await _firestore.collection('disaster_reports').doc(disasterId).get();
      if (!doc.exists) return null;
      return DisasterModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching disaster: $e');
      _error = 'Failed to load disaster: $e';
      return null;
    }
  }

  /// Create a new disaster report
  Future<String?> createDisaster({
    required String id,
    required String userId,
    required String disasterType,
    String? otherDisasterType,
    required String severity,
    required String location,
    LatLng? coordinates,
    required String description,
    required List<String> photoPaths,
    required Timestamp timestamp,
    required String status,
    required List<String> userList,
    required List<Map<String, dynamic>> locationList,
    required int verificationCount,
  }) async {
    _setLoading(true);
    try {
      final data = {
        'id': id,
        'userId': userId,
        'disasterType': disasterType,
        'otherDisasterType': otherDisasterType,
        'severity': severity,
        'location': location,
        'latitude': coordinates?.latitude,
        'longitude': coordinates?.longitude,
        'description': description,
        'photoPaths': photoPaths,
        'timestamp': timestamp,
        'status': status,
        'userList': userList,
        'locationList': locationList,
        'verifyNum': verificationCount,
      };

      // Use the custom ID instead of auto-generated ID
      await _firestore.collection('disaster_reports').doc(id).set(data);

      // Refresh the disaster lists
      await fetchDisasters();

      _error = null;
      return id;
    } catch (e) {
      debugPrint('Error creating disaster: $e');
      _error = 'Failed to create disaster: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing disaster report
  Future<bool> updateDisaster(DisasterModel disaster) async {
    _setLoading(true);
    try {
      await _firestore
          .collection('disaster_reports')
          .doc(disaster.id)
          .update(disaster.toJson());

      // Update local lists
      final index = _disasters.indexWhere((d) => d.id == disaster.id);
      if (index >= 0) {
        _disasters[index] = disaster;

        // Update happening disasters list if needed
        if (disaster.isHappening) {
          final happeningIndex =
              _happeningDisasters.indexWhere((d) => d.id == disaster.id);
          if (happeningIndex >= 0) {
            _happeningDisasters[happeningIndex] = disaster;
          } else {
            _happeningDisasters.add(disaster);
          }
        } else {
          _happeningDisasters.removeWhere((d) => d.id == disaster.id);
        }

        notifyListeners();
      }

      _error = null;
      return true;
    } catch (e) {
      debugPrint('Error updating disaster: $e');
      _error = 'Failed to update disaster: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a disaster report
  Future<bool> deleteDisaster(String disasterId) async {
    _setLoading(true);
    try {
      await _firestore.collection('disaster_reports').doc(disasterId).delete();

      // Update local lists
      _disasters.removeWhere((d) => d.id == disasterId);
      _happeningDisasters.removeWhere((d) => d.id == disasterId);

      notifyListeners();
      _error = null;
      return true;
    } catch (e) {
      debugPrint('Error deleting disaster: $e');
      _error = 'Failed to delete disaster: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change the status of a disaster (e.g., from 'happening' to 'past')
  Future<bool> updateDisasterStatus(String disasterId, String newStatus) async {
    try {
      final disaster = await getDisasterById(disasterId);
      if (disaster == null) return false;

      final updatedDisaster = disaster.copyWith(status: newStatus);
      return await updateDisaster(updatedDisaster);
    } catch (e) {
      debugPrint('Error updating disaster status: $e');
      _error = 'Failed to update disaster status: $e';
      return false;
    }
  }

  /// Search disasters by keyword in description or location
  Future<List<DisasterModel>> searchDisasters(String query) async {
    _setLoading(true);
    try {
      // Fetch all disasters first (we'll filter client-side)
      await fetchDisasters(onlyHappening: false);

      if (query.isEmpty) return _disasters;

      final lowercaseQuery = query.toLowerCase();
      final results = _disasters.where((disaster) {
        return disaster.description.toLowerCase().contains(lowercaseQuery) ||
            disaster.location.toLowerCase().contains(lowercaseQuery) ||
            disaster.disasterType.toLowerCase().contains(lowercaseQuery);
      }).toList();

      return results;
    } catch (e) {
      debugPrint('Error searching disasters: $e');
      _error = 'Failed to search disasters: $e';
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Check if a user is within verification range of a disaster
  Future<bool> isUserWithinRange(String disasterId, LatLng userLocation) async {
    try {
      final disaster = await getDisasterById(disasterId);
      if (disaster == null || disaster.coordinates == null) return false;

      // Calculate distance between user and disaster
      final Distance distance = const Distance();
      final meters = distance(
        userLocation,
        disaster.coordinates!,
      );

      // Return true if user is within 1000 meters (1km)
      return meters <= 1000;
    } catch (e) {
      debugPrint('Error checking user distance: $e');
      return false;
    }
  }

  /// Verify a disaster report
  Future<bool> verifyDisaster(
      String disasterId, String userId, LatLng userLocation) async {
    try {
      // Get the current disaster data
      final disaster = await getDisasterById(disasterId);
      if (disaster == null) return false;

      // Check if user is within range
      if (!await isUserWithinRange(disasterId, userLocation)) {
        throw Exception('User is not within verification range');
      }

      // Check if user has already verified
      if (disaster.userList?.contains(userId) ?? false) {
        throw Exception('User has already verified this disaster');
      }

      // Update the disaster with atomic operations
      await _firestore.collection('disaster_reports').doc(disasterId).update({
        'verifyNum': FieldValue.increment(1),
        'userList': FieldValue.arrayUnion([userId]),
        'locationList': FieldValue.arrayUnion([
          {
            'userId': userId,
            'latitude': userLocation.latitude,
            'longitude': userLocation.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
      });

      // Refresh the disaster data
      await fetchDisasters();
      return true;
    } catch (e) {
      debugPrint('Error verifying disaster: $e');
      _error = 'Failed to verify disaster: $e';
      return false;
    }
  }

  /// Mark a disaster as false alarm
  Future<bool> markAsFalseAlarm(
      String disasterId, String userId, LatLng userLocation) async {
    try {
      // Get the current disaster data
      final disaster = await getDisasterById(disasterId);
      if (disaster == null) return false;

      // Check if user is within range
      if (!await isUserWithinRange(disasterId, userLocation)) {
        throw Exception('User is not within verification range');
      }

      // Check if user has already verified
      if (disaster.userList?.contains(userId) ?? false) {
        throw Exception('User has already verified this disaster');
      }

      // Update the disaster with atomic operations
      await _firestore.collection('disaster_reports').doc(disasterId).update({
        'verifyFalseNum': FieldValue.increment(1),
        'userList': FieldValue.arrayUnion([userId]),
        'locationList': FieldValue.arrayUnion([
          {
            'userId': userId,
            'latitude': userLocation.latitude,
            'longitude': userLocation.longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'action': 'false_alarm',
          }
        ]),
        'lastUpdated': Timestamp.now(),
      });

      // Refresh the disaster data
      await fetchDisasters();
      return true;
    } catch (e) {
      debugPrint('Error marking as false alarm: $e');
      _error = 'Failed to mark as false alarm: $e';
      return false;
    }
  }

  /// Get verification status for a user
  Future<Map<String, dynamic>> getVerificationStatus(
      String disasterId, String userId, BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      final disaster = await getDisasterById(disasterId);
      if (disaster == null) {
        return {
          'canVerify': false,
          'hasVerified': false,
          'message': l.translate('disaster_not_found'),
        };
      }

      final hasVerified = disaster.userList?.contains(userId) ?? false;
      final isFalseAlarm = disaster.status.toLowerCase() == 'false_alarm';

      return {
        'canVerify': !hasVerified && !isFalseAlarm,
        'hasVerified': hasVerified,
        'verificationCount': disaster.verificationCount,
        'verifyFalseNum': disaster.verifyFalseNum,
        'isFalseAlarm': isFalseAlarm,
        'lastUpdated': disaster.lastUpdated,
        'message': isFalseAlarm
            ? l.translate('disaster_marked_false_alarm')
            : hasVerified
                ? l.translate('already_verified_disaster')
                : l.translate('can_verify_disaster'),
      };
    } catch (e) {
      debugPrint('Error getting verification status: $e');
      return {
        'canVerify': false,
        'hasVerified': false,
        'message': l.translate('error_checking_verification_status'),
      };
    }
  }
}
