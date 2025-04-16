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
      // Convert resources list to map with auto-generated IDs
      final resourcesMap = {
        for (var i = 0; i < resources.length; i++)
          'resource_$i': {
            'type': resources[i]['type'],
            'description': resources[i]['description'],
            'currentStock': resources[i]['currentStock'],
            'minThreshold': resources[i]['minThreshold'],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
      };

      final docRef = await _firestore.collection(_collection).add({
        'name': name,
        'status': status,
        'location': GeoPoint(location.latitude, location.longitude),
        'locationName': locationName,
        'capacity': capacity,
        'currentOccupancy': 0,
        'createdBy': createdBy,
        'resources': resourcesMap,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

  // Update resource stock
  Future<void> updateResourceStock(
    String shelterId,
    String resourceId,
    int newStock,
  ) async {
    try {
      await _firestore.collection(_collection).doc(shelterId).update({
        'resources.$resourceId.currentStock': newStock,
        'resources.$resourceId.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update resource stock: $e');
    }
  }
}
