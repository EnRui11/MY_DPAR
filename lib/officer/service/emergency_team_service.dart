import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydpar/services/user_information_service.dart';

class EmergencyTeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserInformationService _userInformationService =
      UserInformationService();

  Future<String> createTeam({
    required String name,
    required String type,
    required String description,
    required String locationText,
    required String specialization,
    LatLng? location,
  }) async {
    try {
      // Get user information from the UserInformationService
      final String leaderId =
          _userInformationService.userId ?? 'default_leader_id';
      final String contact =
          _userInformationService.phoneNumber ?? 'default_contact';
      final String firstName = _userInformationService.firstName ?? '';
      final String lastName = _userInformationService.lastName ?? '';
  
      // Use provided location or default to Kuala Lumpur
      final LatLng teamLocation = location ?? LatLng(3.1390, 101.6869);
  
      final docRef = await _firestore.collection('emergency_teams').add({
        'name': name,
        'type': type,
        'description': description,
        'leader_id': leaderId,
        'contact': contact,
        'location': GeoPoint(teamLocation.latitude, teamLocation.longitude),
        'location_text': locationText,
        'specialization': specialization,
        'status': 'standby',
        'task_count': 0,
        'member_count': 1, 
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
  
      // Add creator as official member
      await _firestore
          .collection('emergency_teams')
          .doc(docRef.id)
          .collection('official_members')
          .doc(leaderId)
          .set({
        'joined_at': FieldValue.serverTimestamp(),
        'name': '$firstName $lastName',
        'contact': contact,
        'role': 'leader',
      });
  
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create emergency team: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAllTeams() {
    return _firestore
        .collection('emergency_teams')
        .orderBy('created_at', descending: true)
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

  Future<Map<String, dynamic>?> getTeam(String teamId) async {
    try {
      final doc =
          await _firestore.collection('emergency_teams').doc(teamId).get();
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
      throw Exception('Failed to get emergency team: $e');
    }
  }

  Future<void> updateTeam({
    required String teamId,
    String? name,
    String? type,
    String? description,
    String? leaderId,
    String? contact,
    LatLng? location,
    String? status,
    String? specialization,
    String? locationText,
    int? taskCount,
    int? memberCount,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (description != null) 'description': description,
        if (leaderId != null) 'leader_id': leaderId,
        if (contact != null) 'contact': contact,
        if (location != null)
          'location': GeoPoint(location.latitude, location.longitude),
        if (status != null) 'status': status,
        if (specialization != null) 'specialization': specialization,
        if (locationText != null) 'location_text': locationText,
        if (taskCount != null) 'task_count': taskCount,
        if (memberCount != null) 'member_count': memberCount,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update emergency team: $e');
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await _firestore.collection('emergency_teams').doc(teamId).delete();
    } catch (e) {
      throw Exception('Failed to delete emergency team: $e');
    }
  }

  // Team Members Collection
  Future<String> addTeamMember({
    required String teamId,
    required String userId,
    required String name,
    required String type,
    required String role,
    required String contact,
    required List<String> skills,
  }) async {
    try {
      final docRef = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_members')
          .add({
        'user_id': userId,
        'name': name,
        'type': type,
        'role': role,
        'contact': contact,
        'skills': skills,
        'status': 'active',
        'applied_at': FieldValue.serverTimestamp(),
        'approved_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add team member: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getTeamMembers(String teamId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_members')
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<void> updateTeamMember({
    required String teamId,
    required String memberId,
    String? name,
    String? type,
    String? role,
    String? contact,
    List<String>? skills,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (role != null) 'role': role,
        if (contact != null) 'contact': contact,
        if (skills != null) 'skills': skills,
        if (status != null) 'status': status,
      };

      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_members')
          .doc(memberId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  Future<void> removeTeamMember(String teamId, String memberId) async {
    try {
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_members')
          .doc(memberId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove team member: $e');
    }
  }

  // Team Tasks Collection
  Future<String> createTeamTask({
    required String teamId,
    required String title,
    required String description,
    required LatLng location,
  }) async {
    try {
      final docRef = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .add({
        'title': title,
        'description': description,
        'location': GeoPoint(location.latitude, location.longitude),
        'status': 'pending',
        'assigned_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create team task: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getTeamTasks(String teamId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_tasks')
        .orderBy('assigned_at', descending: true)
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

  Future<void> updateTaskStatus({
    required String teamId,
    required String taskId,
    required String status,
    String? feedback,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        if (feedback != null) 'feedback': feedback,
        if (status == 'in_progress') 'started_at': FieldValue.serverTimestamp(),
        if (status == 'completed') 'completed_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .doc(taskId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  // Team Resources Collection
  Future<String> addTeamResource({
    required String teamId,
    required String resourceType,
    required String description,
    required int quantity,
    required String unit,
  }) async {
    try {
      final docRef = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_resources')
          .add({
        'resource_type': resourceType,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add team resource: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getTeamResources(String teamId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_resources')
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<void> updateResourceQuantity({
    required String teamId,
    required String resourceId,
    required int quantity,
  }) async {
    try {
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_resources')
          .doc(resourceId)
          .update({
        'quantity': quantity,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update resource quantity: $e');
    }
  }

  // Volunteer Applications Collection
  Future<String> submitVolunteerApplication({
    required String userId,
    required String teamId,
  }) async {
    try {
      final docRef = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('volunteer_applications')
          .add({
        'user_id': userId,
        'status': 'pending',
        'applied_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit volunteer application: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getVolunteerApplications(String teamId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('volunteer_applications')
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<void> reviewVolunteerApplication({
    required String teamId,
    required String applicationId,
    required String status,
    required String reviewerId,
  }) async {
    try {
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('volunteer_applications')
          .doc(applicationId)
          .update({
        'status': status,
        'reviewer_id': reviewerId,
        'reviewed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to review volunteer application: $e');
    }
  }

  Future<void> quitTeam(String teamId, String userId, String userRole) async {
    try {
      String collectionName = userRole == 'officer' ? 'official_members' : 'volunteer_members';
      
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection(collectionName)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to quit team: $e');
    }
  }

  Future<void> joinTeam(String teamId) async {
    try {
      final userId = _userInformationService.userId;
      final userRole = _userInformationService.role;
  
      if (userId == null) {
        throw Exception('User not logged in');
      }
  
      // Check if team exists
      final teamDoc =
          await _firestore.collection('emergency_teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }
  
      // Check if user is already the leader
      final isLeader = teamDoc.data()?['leader_id'] == userId;
      if (isLeader) {
        throw Exception('You are already the leader of this team');
      }
  
      // Check if user is already an official member
      final officialMemberDoc = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('official_members')
          .doc(userId)
          .get();
  
      if (officialMemberDoc.exists) {
        throw Exception('You are already an official member of this team');
      }
  
      // Check if user is already a volunteer member
      final volunteerMemberDoc = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('volunteer_members')
          .doc(userId)
          .get();
  
      if (volunteerMemberDoc.exists) {
        throw Exception('You are already a volunteer member of this team');
      }
  
      // Add user to the appropriate subcollection
      if (userRole == 'officer') {
        await _firestore
            .collection('emergency_teams')
            .doc(teamId)
            .collection('official_members')
            .doc(userId)
            .set({
          'joined_at': FieldValue.serverTimestamp(),
          'name':
              '${_userInformationService.firstName} ${_userInformationService.lastName}',
          'contact': _userInformationService.phoneNumber,
        });
      } else {
        await _firestore
            .collection('emergency_teams')
            .doc(teamId)
            .collection('volunteer_members')
            .doc(userId)
            .set({
          'joined_at': FieldValue.serverTimestamp(),
          'name':
              '${_userInformationService.firstName} ${_userInformationService.lastName}',
          'contact': _userInformationService.phoneNumber,
        });
      }
  
      // Recalculate total members from both subcollections
      final officialMembers = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('official_members')
          .get();
  
      final volunteerMembers = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('volunteer_members')
          .get();
  
      final totalMembers = officialMembers.size + volunteerMembers.size;
  
      // Update the member count
      await _firestore.collection('emergency_teams').doc(teamId).update({
        'member_count': totalMembers,
      });
    } catch (e) {
      throw Exception('Failed to join team: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserTeams() {
    final userId = _userInformationService.userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('emergency_teams')
        .snapshots()
        .asyncMap((snapshot) async {
      final teams = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final teamId = doc.id;

        // Check if the user is the leader
        if (data['leader_id'] == userId) {
          teams.add({
            'id': teamId,
            ...data,
            'location': LatLng(
              (data['location'] as GeoPoint).latitude,
              (data['location'] as GeoPoint).longitude,
            ),
            'is_leader': true,
          });
          continue;
        }

        // Check if the user is an official member
        final officialMemberDoc = await _firestore
            .collection('emergency_teams')
            .doc(teamId)
            .collection('official_members')
            .doc(userId)
            .get();

        if (officialMemberDoc.exists) {
          teams.add({
            'id': teamId,
            ...data,
            'location': LatLng(
              (data['location'] as GeoPoint).latitude,
              (data['location'] as GeoPoint).longitude,
            ),
            'is_leader': false,
          });
        }
      }

      return teams;
    });
  }
}
