import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydpar/services/user_information_service.dart';

class ShelterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'shelters';
  final UserInformationService _userInformationService =
      UserInformationService();

  // Create a new shelter with resources
  Future<String> createShelter({
    required String name,
    required String status,
    required LatLng location,
    required String locationName,
    required int capacity,
    required String createdBy,
    required List<Map<String, dynamic>> resources,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'name': name,
        'status': status,
        'location': GeoPoint(location.latitude, location.longitude),
        'locationName': locationName,
        'capacity': capacity,
        'currentOccupancy': 0,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add creator as member
      await _firestore
          .collection(_collection)
          .doc(docRef.id)
          .collection('members')
          .doc(createdBy)
          .set({
        'joined_at': FieldValue.serverTimestamp(),
        'name':
            '${_userInformationService.firstName} ${_userInformationService.lastName}',
        'contact': _userInformationService.phoneNumber,
        'role': 'admin',
      });

      // Add resources to the subcollection
      for (var resource in resources) {
        await _firestore
            .collection(_collection)
            .doc(docRef.id)
            .collection('resources')
            .add({
          'type': resource['type'],
          'description': resource['description'],
          'currentStock': resource['currentStock'],
          'minThreshold': resource['minThreshold'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create shelter: $e');
    }
  }

  // Get a shelter by ID
  Future<Map<String, dynamic>?> getShelter(String shelterId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(shelterId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': doc.id,
        ...data,
        'location': LatLng(
          (data['location'] as GeoPoint).latitude,
          (data['location'] as GeoPoint).longitude,
        ),
      };
    } catch (e) {
      throw Exception('Failed to get shelter: $e');
    }
  }

  // Get all shelters for the current user
  Stream<List<Map<String, dynamic>>> getUserShelters() {
    final userId = _userInformationService.userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .snapshots()
        .asyncMap((snapshot) async {
      final shelters = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final shelterId = doc.id;

        // Check if the user is a member
        final memberDoc = await _firestore
            .collection(_collection)
            .doc(shelterId)
            .collection('members')
            .doc(userId)
            .get();

        if (memberDoc.exists) {
          shelters.add({
            'id': shelterId,
            ...data,
            'location': LatLng(
              (data['location'] as GeoPoint).latitude,
              (data['location'] as GeoPoint).longitude,
            ),
            'role': memberDoc.data()?['role'] ?? 'member',
          });
        }
      }

      return shelters;
    });
  }

  // Join a shelter by ID
  Future<void> joinShelter(String shelterId) async {
    try {
      final userId = _userInformationService.userId;
      final userRole = _userInformationService.role;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Check if shelter exists
      final shelterDoc =
          await _firestore.collection(_collection).doc(shelterId).get();
      if (!shelterDoc.exists) {
        throw Exception('Shelter not found');
      }

      // Check if user is already a member
      final memberDoc = await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('members')
          .doc(userId)
          .get();

      if (memberDoc.exists) {
        throw Exception('You are already a member of this shelter');
      }

      // Add user to members subcollection
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('members')
          .doc(userId)
          .set({
        'joined_at': FieldValue.serverTimestamp(),
        'name':
            '${_userInformationService.firstName} ${_userInformationService.lastName}',
        'contact': _userInformationService.phoneNumber,
        'role': userRole == 'officer' ? 'officer' : 'member',
      });
    } catch (e) {
      throw Exception('Failed to join shelter: $e');
    }
  }

  // Get all shelters (for admin purposes)
  Stream<List<Map<String, dynamic>>> getAllShelters() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'location': LatLng(
            (data['location'] as GeoPoint).latitude,
            (data['location'] as GeoPoint).longitude,
          ),
        };
      }).toList();
    });
  }

  // Update a shelter
  Future<void> updateShelter({
    required String shelterId,
    String? name,
    String? status,
    LatLng? location,
    String? locationName,
    int? capacity,
    Map<String, dynamic>? resources,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (status != null) 'status': status,
        if (location != null)
          'location': GeoPoint(location.latitude, location.longitude),
        if (locationName != null) 'locationName': locationName,
        if (capacity != null) 'capacity': capacity,
        if (resources != null) 'resources': resources,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collection).doc(shelterId).update(updates);
    } catch (e) {
      throw Exception('Failed to update shelter: $e');
    }
  }

  // Delete a shelter
  Future<void> deleteShelter(String shelterId) async {
    try {
      await _firestore.collection(_collection).doc(shelterId).delete();
    } catch (e) {
      throw Exception('Failed to delete shelter: $e');
    }
  }

  // Update shelter occupancy
  Future<void> updateOccupancy(String shelterId, int newOccupancy) async {
    try {
      await _firestore.collection(_collection).doc(shelterId).update({
        'currentOccupancy': newOccupancy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update shelter occupancy: $e');
    }
  }

  // Get shelter resources
  Stream<List<Map<String, dynamic>>> getShelterResources(String shelterId) {
    return _firestore
        .collection(_collection)
        .doc(shelterId)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Add a new resource
  Future<String> addResource({
    required String shelterId,
    required String type,
    required String description,
    required int currentStock,
    required int minThreshold,
  }) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('resources')
          .add({
        'type': type,
        'description': description,
        'currentStock': currentStock,
        'minThreshold': minThreshold,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_collection).doc(shelterId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add resource: $e');
    }
  }

  // Updating resource details
  Future<void> updateResource(
    String shelterId,
    String resourceId, {
    String? description,
    int? currentStock,
    int? minThreshold,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (description != null) 'description': description,
        if (currentStock != null) 'currentStock': currentStock,
        if (minThreshold != null) 'minThreshold': minThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('resources')
          .doc(resourceId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update resource: $e');
    }
  }

  // Delete a resource
  Future<void> deleteResource(String shelterId, String resourceId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('resources')
          .doc(resourceId)
          .delete();

      await _firestore.collection(_collection).doc(shelterId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete resource: $e');
    }
  }

  // Update shelter demographics
  Future<void> updateDemographics({
    required String shelterId,
    required int elderlyCount,
    required int adultsCount,
    required int childrenCount,
  }) async {
    try {
      final totalOccupancy = elderlyCount + adultsCount + childrenCount;

      await _firestore.collection(_collection).doc(shelterId).update({
        'demographics': {
          'elderly': elderlyCount,
          'adults': adultsCount,
          'children': childrenCount,
        },
        'currentOccupancy': totalOccupancy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update shelter demographics: $e');
    }
  }

  // Get help requests for a shelter
  Stream<List<Map<String, dynamic>>> getHelpRequests(String shelterId) {
    return _firestore
        .collection(_collection)
        .doc(shelterId)
        .collection('help_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Create a new help request
  Future<String> createHelpRequest({
    required String shelterId,
    required String type,
    required String description,
    required String requestedBy,
  }) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('help_requests')
          .add({
        'type': type,
        'description': description,
        'status': 'pending',
        'requestedBy': requestedBy,
        'respondBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create help request: $e');
    }
  }

  // Updating help request status and description
  Future<void> updateHelpRequest({
    required String shelterId,
    required String requestId,
    required String status,
    required String description,
    required String requestedBy,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('help_requests')
          .doc(requestId)
          .update({
        'status': status,
        'description': description,
        'requestedBy': requestedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update help request: $e');
    }
  }

  // Delete help request
  Future<void> deleteHelpRequest({
    required String shelterId,
    required String requestId,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('help_requests')
          .doc(requestId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete help request: $e');
    }
  }

  // Get location history for a shelter
  Stream<List<Map<String, dynamic>>> getLocationHistory(String shelterId) {
    return _firestore
        .collection(_collection)
        .doc(shelterId)
        .collection('location_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'location': LatLng(
            (data['location'] as GeoPoint).latitude,
            (data['location'] as GeoPoint).longitude,
          ),
        };
      }).toList();
    });
  }

  // Add a new location history entry
  Future<void> addLocationHistory({
    required String shelterId,
    required LatLng location,
    required String locationName,
    String? notes,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('location_history')
          .add({
        'location': GeoPoint(location.latitude, location.longitude),
        'locationName': locationName,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the shelter's current location
      await _firestore.collection(_collection).doc(shelterId).update({
        'location': GeoPoint(location.latitude, location.longitude),
        'locationName': locationName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add location history: $e');
    }
  }

  // Delete a location history entry
  Future<void> deleteLocationHistory({
    required String shelterId,
    required String historyId,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('location_history')
          .doc(historyId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete location history: $e');
    }
  }
}
