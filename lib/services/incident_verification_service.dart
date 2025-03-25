import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class IncidentVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _cachedIncidents = [];

  /// Cache incidents when service is initialized
  Future<void> cacheIncidents() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('incident_reports')
          .orderBy('timestamp', descending: true)
          .get();
      
      _cachedIncidents = snapshot.docs;
    } catch (e) {
      print('Error caching incidents: $e');
    }
  }

  /// Checks for existing similar incidents using cached data
  Future<Map<String, dynamic>?> checkExistingIncident({
    required String incidentType,
    required double latitude,
    required double longitude,
    required String timestamp,
  }) async {
    try {
      final DateTime reportTime = DateTime.parse(timestamp);
      final DateTime oneHourAgo = reportTime.subtract(const Duration(hours: 1));
      
      // Filter cached incidents
      for (final doc in _cachedIncidents) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check incident type
        if (data['incidentType'] != incidentType) continue;
        
        // Check timestamp
        final DateTime incidentTime = DateTime.parse(data['timestamp'] as String);
        if (incidentTime.isBefore(oneHourAgo)) continue;
        
        // Check location
        if (data['latitude'] == null || data['longitude'] == null) continue;
        
        final double distanceInMeters = Geolocator.distanceBetween(
          latitude, 
          longitude, 
          data['latitude'] as double, 
          data['longitude'] as double
        );
        
        if (distanceInMeters <= 1000) {
          return {
            'id': doc.id,
            ...data,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error checking for existing incidents: $e');
      return null;
    }
  }
  
  /// Updates an existing incident with new information
  Future<void> updateExistingIncident({
    required String incidentId,
    required String userId,
    required double latitude,
    required double longitude,
    required String severity,
    required String description,
    required List<String> photoPaths,
  }) async {
    try {
      // Get the current incident data
      final DocumentSnapshot doc = await _firestore
          .collection('incident_reports')
          .doc(incidentId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Incident not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Prepare updated data
      final List<String> userList = List<String>.from(data['userList'] ?? []);
      final List<Map<String, dynamic>> locationList = 
          List<Map<String, dynamic>>.from(data['locationList'] ?? []);
      
      // Add user to userList if not already included
      if (!userList.contains(userId)) {
        userList.add(userId);
      }
      
      // Add location to locationList
      final newLocation = {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };
      locationList.add(newLocation);
      
      // Update verification count
      final int verifyNum = (data['verifyNum'] ?? 0) + 1;
      
      // Update status if verified by 2 or more users
      String status = data['status'] ?? 'pending';
      if (verifyNum >= 2) {
        status = 'happening';
      }
      
      // Update the incident
      await _firestore.collection('incident_reports').doc(incidentId).update({
        'severity': severity, // Use latest severity
        'description': description, // Use latest description
        'photoPaths': photoPaths, // Use latest photos
        'userList': userList,
        'locationList': locationList,
        'verifyNum': verifyNum,
        'status': status,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating existing incident: $e');
      throw Exception('Failed to update incident: $e');
    }
  }
}