import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class ShelterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'shelters';

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

  // Get all shelters
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

  // Update resource stock
  Future<void> updateResourceStock(
    String shelterId,
    String resourceId,
    int newStock,
  ) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('resources')
          .doc(resourceId)
          .update({
        'currentStock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_collection).doc(shelterId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update resource stock: $e');
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

  // Update help request status
  Future<void> updateHelpRequestStatus({
    required String shelterId,
    required String requestId,
    required String status,
    required String respondBy,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(shelterId)
          .collection('help_requests')
          .doc(requestId)
          .update({
        'status': status,
        'respondBy': FieldValue.arrayUnion([respondBy]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update help request status: $e');
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
}
