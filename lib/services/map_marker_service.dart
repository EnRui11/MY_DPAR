import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydpar/services/sos_alert_service.dart';
import 'package:mydpar/officer/services/shelter_and_resource_service.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/services/user_information_service.dart';

/// Service to manage map markers for different data types
class MapMarkerService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SOSAlertService _sosService = SOSAlertService();
  final ShelterService _shelterService = ShelterService();
  final DisasterService _disasterService = DisasterService();
  final UserInformationService _userService = UserInformationService();

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _sosSubscription;
  StreamSubscription<QuerySnapshot>? _shelterSubscription;
  StreamSubscription<QuerySnapshot>? _disasterSubscription;

  // Marker data
  List<Map<String, dynamic>> _sosMarkers = [];
  List<Map<String, dynamic>> _shelterMarkers = [];
  List<Map<String, dynamic>> _disasterMarkers = [];

  // Filter state
  final Set<String> _activeFilters = {'SOS', 'Disasters', 'Shelters'};

  // Getters
  List<Map<String, dynamic>> get sosMarkers => _sosMarkers;
  List<Map<String, dynamic>> get shelterMarkers => _shelterMarkers;
  List<Map<String, dynamic>> get disasterMarkers => _disasterMarkers;
  Set<String> get activeFilters => _activeFilters;

  // Initialize the service
  MapMarkerService() {
    debugPrint('Initializing MapMarkerService');
    _initializeStreams();
  }

  /// Initialize all marker streams
  void _initializeStreams() {
    debugPrint('Initializing marker streams');

    // Listen to SOS alerts
    _sosSubscription = _firestore
        .collection('alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      debugPrint('Received SOS update: ${snapshot.docs.length} alerts');

      List<Map<String, dynamic>> updatedMarkers = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['uid'] as String?;
        final alertId = doc.id;

        // Fetch complete alert details using SOSAlertService
        final alertDetails = await _sosService.getAlertDetails(alertId);
        if (alertDetails == null) continue;

        // Fetch user information if userId exists
        Map<String, dynamic> userInfo = {};
        if (userId != null) {
          try {
            final userDoc =
                await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              userInfo = {
                'firstName': userData['firstName'],
                'lastName': userData['lastName'],
                'phoneNumber': userData['phoneNumber'],
                'photoUrl': userData['photoUrl'],
                'createdAt': userData['createdAt'],
              };
            }
          } catch (e) {
            debugPrint('Error fetching user info: $e');
          }
        }

        // Create marker with combined information
        updatedMarkers.add({
          'id': alertId,
          'type': 'SOS',
          'position': LatLng(
            (data['location'] as GeoPoint).latitude,
            (data['location'] as GeoPoint).longitude,
          ),
          'title': 'SOS Alert',
          'description': data['description'] ?? '',
          'location': data['address'] ?? '',
          'timestamp': data['alertStartTime'],
          'severity': 'high',
          'userId': userId ?? '',
          // User information from users collection
          'firstName': userInfo['firstName'] ?? '',
          'lastName': userInfo['lastName'] ?? '',
          'userPhone': userInfo['phoneNumber'] ?? '',
          'userPhotoUrl': userInfo['photoUrl'],
          'userCreatedAt': userInfo['createdAt'],
          // Alert information
          'emergencyContacts': data['emergencyContacts'] ?? [],
          'isActive': data['isActive'] ?? true,
          'emergencyType': 'Emergency Alert',
          'status': data['isActive'] ? 'Active' : 'Inactive',
          'latestUpdateTime': data['latestUpdateTime'],
          'cancelTime': data['cancelTime'],
          'address': data['address'],
          'alertStartTime': data['alertStartTime'],
        });
      }

      _sosMarkers = updatedMarkers;
      notifyListeners();
    });

    // Listen to shelters
    _shelterSubscription =
        _firestore.collection('shelters').snapshots().listen((snapshot) async {
      debugPrint('Received shelter update: ${snapshot.docs.length} shelters');
      List<Map<String, dynamic>> updatedMarkers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final creatorId = data['createdBy'] as String?;

        // Fetch creator information if creatorId exists
        Map<String, dynamic> creatorInfo = {};
        if (creatorId != null) {
          try {
            final userDoc =
                await _firestore.collection('users').doc(creatorId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              creatorInfo = {
                'firstName': userData['firstName'] ?? '',
                'lastName': userData['lastName'] ?? '',
                'phoneNumber': userData['phoneNumber'] ?? '',
                'photoUrl': userData['photoUrl'],
                'role': userData['role'] ?? 'normal',
                'createdAt': userData['createdAt'],
              };
            }
          } catch (e) {
            debugPrint('Error fetching creator info: $e');
          }
        }

        updatedMarkers.add({
          'id': doc.id,
          'type': 'Shelter',
          'position': LatLng(
            (data['location'] as GeoPoint).latitude,
            (data['location'] as GeoPoint).longitude,
          ),
          'name': data['name'] ?? 'Shelter',
          'status': data['status'] ?? 'unknown',
          'locationName': data['locationName'] ?? '',
          'capacity': data['capacity'] ?? 0,
          'currentOccupancy': data['currentOccupancy'] ?? 0,
          'demographics': data['demographics'] ??
              {
                'adults': 0,
                'children': 0,
                'elderly': 0,
              },
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'createdBy': creatorId,
          'creatorName':
              '${creatorInfo['firstName']} ${creatorInfo['lastName']}'.trim(),
          'creatorPhone': creatorInfo['phoneNumber'],
          'creatorPhotoUrl': creatorInfo['photoUrl'],
          'creatorCreatedAt': creatorInfo['createdAt'],
          'creatorRole': creatorInfo['role'],
        });
      }

      _shelterMarkers = updatedMarkers;
      notifyListeners();
    });

    // Listen to disasters
    _disasterService.fetchDisasters().then((_) {
      _disasterMarkers = _disasterService.disasters
          .map((disaster) => {
                'id': disaster.id,
                'type': 'Disaster',
                'position': LatLng(
                  disaster.coordinates?.latitude ?? 0,
                  disaster.coordinates?.longitude ?? 0,
                ),
                'title': disaster.disasterType,
                'description': disaster.description,
                'location': disaster.location,
                'disasterType': disaster.disasterType,
                'otherDisasterType': disaster.otherDisasterType,
                'severity': disaster.severity,
                'timestamp': disaster.timestamp,
                'status': disaster.status,
                'verificationCount': disaster.verificationCount,
                'userId': disaster.userId,
                'photoPaths': disaster.photoPaths,
                'userList': disaster.userList,
                'locationList': disaster.locationList,
              })
          .toList();
      notifyListeners();
    });
  }

  /// Toggle a filter on/off
  void toggleFilter(String filter) {
    if (_activeFilters.contains(filter)) {
      _activeFilters.remove(filter);
    } else {
      _activeFilters.add(filter);
    }
    notifyListeners();
  }

  /// Get all visible markers based on active filters
  List<Map<String, dynamic>> getVisibleMarkers() {
    List<Map<String, dynamic>> visibleMarkers = [];

    if (_activeFilters.contains('SOS')) {
      visibleMarkers.addAll(_sosMarkers);
    }
    if (_activeFilters.contains('Disasters')) {
      visibleMarkers.addAll(_disasterMarkers);
    }
    if (_activeFilters.contains('Shelters')) {
      visibleMarkers.addAll(_shelterMarkers);
    }

    return visibleMarkers;
  }

  /// Get icon for a marker type
  IconData getMarkerIcon(String type, {String? disasterType}) {
    switch (type) {
      case 'SOS':
        return Icons.emergency;
      case 'Shelter':
        return Icons.home;
      case 'Disaster':
        return DisasterService.getDisasterIcon(disasterType ?? 'other');
      default:
        return Icons.place;
    }
  }

  /// Get color for a marker type
  Color getMarkerColor(String type,
      {String? severity, required AppColorTheme colors}) {
    switch (type) {
      case 'SOS':
        return colors.warning;
      case 'Shelter':
        return colors.accent200;
      case 'Disaster':
        return DisasterService.getSeverityColor(severity ?? 'low', colors);
      default:
        return colors.text200;
    }
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    _shelterSubscription?.cancel();
    _disasterSubscription?.cancel();
    super.dispose();
  }
}
