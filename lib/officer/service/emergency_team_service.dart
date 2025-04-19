import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyTeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserInformationService _userInformationService =
      UserInformationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<String> createTeam({
    required String name,
    required String type,
    required String description,
    required String locationText,
    required String specialization,
  }) async {
    try {
      // Get user information from the UserInformationService
      final String leaderId =
          _userInformationService.userId ?? 'default_leader_id';
      final String contact =
          _userInformationService.phoneNumber ?? 'default_contact';
      final String firstName = _userInformationService.firstName ?? '';
      final String lastName = _userInformationService.lastName ?? '';

      final docRef = await _firestore.collection('emergency_teams').add({
        'name': name,
        'type': type,
        'description': description,
        'leader_id': leaderId,
        'contact': contact,
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

  /// Gets the current user's member information in a team
  Future<Map<String, dynamic>?> getUserMemberInfo(String teamId) async {
    try {
      final userId = _userInformationService.userId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get team data to determine type
      final teamDoc =
          await _firestore.collection('emergency_teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data()!;
      final teamType = teamData['type'] as String? ?? 'official';

      // Check if user is in official_members
      final officialMemberDoc = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('official_members')
          .doc(userId)
          .get();

      if (officialMemberDoc.exists) {
        return {
          'id': officialMemberDoc.id,
          'collection': 'official_members',
          ...officialMemberDoc.data()!,
        };
      }

      // If team is volunteer type, also check volunteer_members
      if (teamType == 'volunteer') {
        final volunteerMemberDoc = await _firestore
            .collection('emergency_teams')
            .doc(teamId)
            .collection('volunteer_members')
            .doc(userId)
            .get();

        if (volunteerMemberDoc.exists) {
          return {
            'id': volunteerMemberDoc.id,
            'collection': 'volunteer_members',
            ...volunteerMemberDoc.data()!,
          };
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user member info: $e');
    }
  }

  /// Gets all team members based on team type
  Stream<List<Map<String, dynamic>>> getTeamMembers(String teamId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .snapshots()
        .asyncMap((teamDoc) async {
      if (!teamDoc.exists) {
        return [];
      }

      final teamData = teamDoc.data()!;
      final teamType = teamData['type'] as String? ?? 'official';
      final List<Map<String, dynamic>> members = [];

      // Get official members
      final officialMembersSnapshot = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('official_members')
          .get();

      for (var doc in officialMembersSnapshot.docs) {
        members.add({
          'id': doc.id,
          'collection': 'official_members',
          ...doc.data(),
        });
      }

      // If team is volunteer type, also get volunteer members
      if (teamType == 'volunteer') {
        final volunteerMembersSnapshot = await _firestore
            .collection('emergency_teams')
            .doc(teamId)
            .collection('volunteer_members')
            .get();

        for (var doc in volunteerMembersSnapshot.docs) {
          members.add({
            'id': doc.id,
            'collection': 'volunteer_members',
            ...doc.data(),
          });
        }
      }

      return members;
    });
  }

  /// Updates the current user's role in a team
  Future<void> updateUserRole({
    required String teamId,
    required String role,
  }) async {
    try {
      final userId = _userInformationService.userId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get user member info to determine which collection to update
      final memberInfo = await getUserMemberInfo(teamId);
      if (memberInfo == null) {
        throw Exception('User is not a member of this team');
      }

      final collection = memberInfo['collection'] as String;

      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection(collection)
          .doc(userId)
          .update({
        'role': role,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Updates the current user's duty status in a team
  Future<void> updateUserDutyStatus({
    required String teamId,
    required bool isOnDuty,
  }) async {
    try {
      final userId = _userInformationService.userId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get user member info to determine which collection to update
      final memberInfo = await getUserMemberInfo(teamId);
      if (memberInfo == null) {
        throw Exception('User is not a member of this team');
      }

      final collection = memberInfo['collection'] as String;

      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection(collection)
          .doc(userId)
          .update({
        'status': isOnDuty ? 'active' : 'inactive',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user duty status: $e');
    }
  }

  /// Adds a new member to the team
  Future<void> addTeamMember({
    required String teamId,
    required String userId,
    required String name,
    required String contact,
    required String role,
    required String memberType, // 'official' or 'volunteer'
  }) async {
    try {
      // Get team data to determine type
      final teamDoc =
          await _firestore.collection('emergency_teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data()!;
      final teamType = teamData['type'] as String? ?? 'official';

      // Determine which collection to use
      String collection;
      if (teamType == 'official') {
        collection = 'official_members';
      } else {
        // For volunteer teams, use the specified member type
        collection =
            memberType == 'official' ? 'official_members' : 'volunteer_members';
      }

      // Check if user is already a member
      final existingMemberDoc = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection(collection)
          .doc(userId)
          .get();

      if (existingMemberDoc.exists) {
        throw Exception('User is already a member of this team');
      }

      // Add the member
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection(collection)
          .doc(userId)
          .set({
        'name': name,
        'contact': contact,
        'role': role,
        'status': 'active',
        'joined_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update member count
      await _updateMemberCount(teamId);
    } catch (e) {
      throw Exception('Failed to add team member: $e');
    }
  }

  /// Updates a team member's information
  Future<void> updateTeamMember({
    required String teamId,
    required String userId,
    required String collection, // 'official_members' or 'volunteer_members'
    String? name,
    String? role,
    String? contact,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (role != null) 'role': role,
        if (contact != null) 'contact': contact,
        if (status != null) 'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection(collection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  /// Removes a team member
  Future<void> removeTeamMember({
    required String teamId,
    required String userId,
    required String collection, // 'official_members' or 'volunteer_members'
  }) async {
    try {
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection(collection)
          .doc(userId)
          .delete();

      // Update member count
      await _updateMemberCount(teamId);
    } catch (e) {
      throw Exception('Failed to remove team member: $e');
    }
  }

  /// Helper method to update the member count
  Future<void> _updateMemberCount(String teamId) async {
    try {
      // Get counts from both collections
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
      throw Exception('Failed to update member count: $e');
    }
  }

  // Team Tasks Collection
  Future<String> createTeamTask({
    required String teamId,
    required String taskName,
    required String description,
    required DateTime startDate,
    required String priority,
    required LatLng startLocation,
    LatLng? endLocation,
    Map<String, dynamic>? membersAssigned,
    DateTime? expectedEndDate,
  }) async {
    try {
      final docRef = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .add({
        'task_name': taskName,
        'description': description,
        'start_date': Timestamp.fromDate(startDate),
        'completed_date': null,
        'expected_end_date': expectedEndDate != null
            ? Timestamp.fromDate(expectedEndDate)
            : null,
        'priority': priority,
        'status': 'pending',
        'members_assigned': membersAssigned ?? {},
        'start_location':
            GeoPoint(startLocation.latitude, startLocation.longitude),
        'end_location': endLocation != null
            ? GeoPoint(endLocation.latitude, endLocation.longitude)
            : null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Add initial status to status_history
      final user = _auth.currentUser;
      await docRef.collection('status_history').add({
        'status': 'pending',
        'changed_at': FieldValue.serverTimestamp(),
        'changed_by': user?.uid ?? '',
        'changed_by_name':
            '${_userInformationService.firstName ?? ''} ${_userInformationService.lastName ?? ''}',
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
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'start_location': LatLng(
            (data['start_location'] as GeoPoint).latitude,
            (data['start_location'] as GeoPoint).longitude,
          ),
          'end_location': data['end_location'] != null
              ? LatLng(
                  (data['end_location'] as GeoPoint).latitude,
                  (data['end_location'] as GeoPoint).longitude,
                )
              : null,
          'start_date': (data['start_date'] as Timestamp).toDate(),
          'completed_date': data['completed_date'] != null
              ? (data['completed_date'] as Timestamp).toDate()
              : null,
          'expected_end_date': data['expected_end_date'] != null
              ? (data['expected_end_date'] as Timestamp).toDate()
              : null,
        };
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> getTeamTask(
      String teamId, String taskId) async {
    try {
      final doc = await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .doc(taskId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': doc.id,
        ...data,
        'start_location': LatLng(
          (data['start_location'] as GeoPoint).latitude,
          (data['start_location'] as GeoPoint).longitude,
        ),
        'end_location': data['end_location'] != null
            ? LatLng(
                (data['end_location'] as GeoPoint).latitude,
                (data['end_location'] as GeoPoint).longitude,
              )
            : null,
        'start_date': (data['start_date'] as Timestamp).toDate(),
        'completed_date': data['completed_date'] != null
            ? (data['completed_date'] as Timestamp).toDate()
            : null,
        'expected_end_date': data['expected_end_date'] != null
            ? (data['expected_end_date'] as Timestamp).toDate()
            : null,
      };
    } catch (e) {
      throw Exception('Failed to get team task: $e');
    }
  }

  Future<void> updateTeamTask({
    required String teamId,
    required String taskId,
    String? taskName,
    String? description,
    DateTime? startDate,
    DateTime? completedDate,
    DateTime? expectedEndDate,
    String? priority,
    String? status,
    Map<String, dynamic>? membersAssigned,
    LatLng? startLocation,
    LatLng? endLocation,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (taskName != null) 'task_name': taskName,
        if (description != null) 'description': description,
        if (startDate != null) 'start_date': Timestamp.fromDate(startDate),
        if (completedDate != null)
          'completed_date': Timestamp.fromDate(completedDate),
        if (expectedEndDate != null)
          'expected_end_date': Timestamp.fromDate(expectedEndDate),
        if (priority != null) 'priority': priority,
        if (status != null) 'status': status,
        if (membersAssigned != null) 'members_assigned': membersAssigned,
        if (startLocation != null)
          'start_location':
              GeoPoint(startLocation.latitude, startLocation.longitude),
        if (endLocation != null)
          'end_location': GeoPoint(endLocation.latitude, endLocation.longitude),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .doc(taskId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update team task: $e');
    }
  }

  Future<void> deleteTeamTask(String teamId, String taskId) async {
    try {
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete team task: $e');
    }
  }

  Future<void> assignMembersToTask({
    required String teamId,
    required String taskId,
    required Map<String, dynamic> membersAssigned,
  }) async {
    try {
      await _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .doc(taskId)
          .update({
        'members_assigned': membersAssigned,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign members to task: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTaskStatusHistory(
      String teamId, String taskId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_tasks')
        .doc(taskId)
        .collection('status_history')
        .orderBy('changed_at', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTaskComments(
      String teamId, String taskId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> addTaskComment({
    required String teamId,
    required String taskId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final String firstName = _userInformationService.firstName ?? '';
    final String lastName = _userInformationService.lastName ?? '';
    final String userName = ('$firstName $lastName').trim();

    await _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_tasks')
        .doc(taskId)
        .collection('comments')
        .add({
      'message': message,
      'user_id': user.uid,
      'user_name': userName.isEmpty ? 'Anonymous' : userName,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Consolidated updateTaskStatus method
  Future<void> updateTaskStatus({
    required String teamId,
    required String taskId,
    required String status,
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final taskRef = _firestore
          .collection('emergency_teams')
          .doc(teamId)
          .collection('team_tasks')
          .doc(taskId);

      // Update task status
      final updates = <String, dynamic>{
        'status': status,
        if (feedback != null) 'feedback': feedback,
        if (status == 'in_progress') 'start_date': FieldValue.serverTimestamp(),
        if (status == 'completed')
          'completed_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      batch.update(taskRef, updates);

      // Add status history entry
      final historyRef = taskRef.collection('status_history').doc();
      batch.set(historyRef, {
        'status': status,
        'changed_at': FieldValue.serverTimestamp(),
        'changed_by': user.uid,
        'changed_by_name':
            '${_userInformationService.firstName} ${_userInformationService.lastName}',
        if (feedback != null) 'feedback': feedback,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getTeamTasksByStatus(
      String teamId, String status) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_tasks')
        .where('status', isEqualTo: status)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'start_location': LatLng(
            (data['start_location'] as GeoPoint).latitude,
            (data['start_location'] as GeoPoint).longitude,
          ),
          'end_location': data['end_location'] != null
              ? LatLng(
                  (data['end_location'] as GeoPoint).latitude,
                  (data['end_location'] as GeoPoint).longitude,
                )
              : null,
          'start_date': (data['start_date'] as Timestamp).toDate(),
          'completed_date': data['completed_date'] != null
              ? (data['completed_date'] as Timestamp).toDate()
              : null,
          'expected_end_date': data['expected_end_date'] != null
              ? (data['expected_end_date'] as Timestamp).toDate()
              : null,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getTeamTasksByPriority(
      String teamId, String priority) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_tasks')
        .where('priority', isEqualTo: priority)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'start_location': LatLng(
            (data['start_location'] as GeoPoint).latitude,
            (data['start_location'] as GeoPoint).longitude,
          ),
          'end_location': data['end_location'] != null
              ? LatLng(
                  (data['end_location'] as GeoPoint).latitude,
                  (data['end_location'] as GeoPoint).longitude,
                )
              : null,
          'start_date': (data['start_date'] as Timestamp).toDate(),
          'completed_date': data['completed_date'] != null
              ? (data['completed_date'] as Timestamp).toDate()
              : null,
          'expected_end_date': data['expected_end_date'] != null
              ? (data['expected_end_date'] as Timestamp).toDate()
              : null,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getMemberTasks(
      String teamId, String memberId) {
    return _firestore
        .collection('emergency_teams')
        .doc(teamId)
        .collection('team_tasks')
        .where('members_assigned.$memberId', isNull: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'start_location': LatLng(
            (data['start_location'] as GeoPoint).latitude,
            (data['start_location'] as GeoPoint).longitude,
          ),
          'end_location': data['end_location'] != null
              ? LatLng(
                  (data['end_location'] as GeoPoint).latitude,
                  (data['end_location'] as GeoPoint).longitude,
                )
              : null,
          'start_date': (data['start_date'] as Timestamp).toDate(),
          'completed_date': data['completed_date'] != null
              ? (data['completed_date'] as Timestamp).toDate()
              : null,
          'expected_end_date': data['expected_end_date'] != null
              ? (data['expected_end_date'] as Timestamp).toDate()
              : null,
        };
      }).toList();
    });
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
      String collectionName =
          userRole == 'officer' ? 'official_members' : 'volunteer_members';

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
            'is_leader': false,
          });
        }
      }
      return teams;
    });
  }
}
