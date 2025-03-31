import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

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
  final String timestamp;
  final String status;
  final List<String>? userList;
  final List<Map<String, dynamic>>? locationList;
  final int verificationCount;

  DisasterModel({
    required this.id,
    required this.userId,
    required this.disasterType,
    this.otherDisasterType,
    required this.severity,
    required this.location,
    this.coordinates,
    required this.description,
    this.photoPaths,  // Added this parameter
    required this.timestamp,
    required this.status,
    this.userList,
    this.locationList,
    required this.verificationCount,
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
      photoPaths: (data['photoPaths'] as List<dynamic>?)?.cast<String>(),  // Added this conversion
      timestamp: data['timestamp'] ?? '',
      status: data['status'] ?? 'happening',
      userList: (data['userList'] as List<dynamic>?)?.cast<String>(),
      locationList: (data['locationList'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      verificationCount: data['verifyNum'] ?? 0,
    );
  }

  /// Check if the disaster is currently happening
  bool get isHappening {
    try {
      // Consider a disaster as "happening" if its status is "happening"
      return status.toLowerCase() == 'happening';
    } catch (e) {
      // If there's an error, default to not showing the disaster
      return false;
    }
  }

  /// Convert to a formatted time string (e.g., "2 hours ago")
  String get formattedTime {
    try {
      final DateTime disasterTime = DateTime.parse(timestamp);  // Changed from time to timestamp
      final Duration difference = DateTime.now().difference(disasterTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return timestamp;  // Changed from time to timestamp
    }
  }

  /// Convert to a map for JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'severity': severity,
    'location': location,
    'timestamp': timestamp,  // Changed from time to timestamp
    'disasterType': disasterType,
    'coordinates': coordinates != null
        ? {
            'latitude': coordinates!.latitude,
            'longitude': coordinates!.longitude
          }
        : null,
    'verificationCount': verificationCount,
    'status': status,
  };
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
      final doc = await _firestore.collection('disaster_reports').doc(disasterId).get();
      if (!doc.exists) return null;
      return DisasterModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching disaster: $e');
      _error = 'Failed to load disaster: $e';
      return null;
    }
  }
}