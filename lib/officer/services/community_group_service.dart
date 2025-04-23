import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mydpar/services/user_information_service.dart';

class CommunityGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserInformationService _userInformationService =
      UserInformationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Community Groups CRUD Operations
  Future<String> createCommunityGroup({
    required String name,
    required String description,
    required String communityName,
  }) async {
    try {
      final docRef = await _firestore.collection('community_groups').add({
        'name': name,
        'description': description,
        'created_by': currentUserId,
        'community_name': communityName,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Add creator as admin
      await _firestore
          .collection('community_groups')
          .doc(docRef.id)
          .collection('group_members')
          .doc(currentUserId)
          .set({
        'user_id': currentUserId,
        'role': 'admin',
        'joined_at': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create community group: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getCommunityGroups() {
    return _firestore
        .collection('community_groups')
        .orderBy('created_at', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final groups = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final groupId = doc.id;

        // Get member count
        final membersSnapshot = await _firestore
            .collection('community_groups')
            .doc(groupId)
            .collection('group_members')
            .get();
        final memberCount = membersSnapshot.docs.length;

        // Check if current user is a member and their role
        final memberDoc = await _firestore
            .collection('community_groups')
            .doc(groupId)
            .collection('group_members')
            .doc(currentUserId)
            .get();

        final isMember = memberDoc.exists;
        final isAdmin =
            memberDoc.exists && memberDoc.data()?['role'] == 'admin';

        groups.add({
          'id': groupId,
          ...data,
          'member_count': memberCount,
          'is_member': isMember,
          'is_admin': isAdmin,
        });
      }
      return groups;
    });
  }

  Future<Map<String, dynamic>?> getCommunityGroupById(String id) async {
    try {
      final doc = await _firestore.collection('community_groups').doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': doc.id,
        ...data,
      };
    } catch (e) {
      throw Exception('Failed to get community group: $e');
    }
  }

  Future<void> updateCommunityGroup({
    required String id,
    String? name,
    String? description,
    String? communityName,
  }) async {
    try {
      // Check if user has permission to update the group
      final isAdmin = await isUserAdmin(id);
      if (!isAdmin) {
        throw Exception('Only admins can update group details');
      }

      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (communityName != null) 'community_name': communityName,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('community_groups').doc(id).update(updates);
    } catch (e) {
      throw Exception('Failed to update community group: $e');
    }
  }

  Future<void> deleteCommunityGroup(String id) async {
    try {
      await _firestore.collection('community_groups').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete community group: $e');
    }
  }

  // Group Members CRUD Operations
  Future<void> addGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Check if user is already a member
      final existingMemberDoc = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_members')
          .doc(userId)
          .get();

      if (existingMemberDoc.exists) {
        throw Exception('User is already a member of this group');
      }

      // Determine user's role based on their user role
      final userRole = _userInformationService.role ?? 'normal';
      final groupRole = userRole == 'officer' ? 'admin' : 'member';

      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_members')
          .doc(userId)
          .set({
        'user_id': userId,
        'role': groupRole,
        'joined_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add group member: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getGroupMembers(String groupId) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('group_members')
        .orderBy('joined_at', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final members = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['user_id'] as String;

        try {
          // Get user information
          final userDoc =
              await _firestore.collection('users').doc(userId).get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            members.add({
              'id': doc.id,
              'user_id': userId,
              'firstName': userData['firstName'] ?? '',
              'lastName': userData['lastName'] ?? '',
              'email': userData['email'] ?? '',
              'photo_url': userData['photo_url'],
              'role': data['role'] ?? 'member',
              'joined_at': data['joined_at'],
            });
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }

      return members;
    });
  }

  Future<void> updateGroupMember({
    required String groupId,
    required String memberId,
    required String role,
  }) async {
    try {
      if (role != 'admin' && role != 'member') {
        throw Exception('Invalid role. Must be either "admin" or "member"');
      }

      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_members')
          .doc(memberId)
          .update({
        'role': role,
      });
    } catch (e) {
      throw Exception('Failed to update group member: $e');
    }
  }

  Future<void> removeGroupMember(String groupId, String memberId) async {
    try {
      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_members')
          .doc(memberId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove group member: $e');
    }
  }

  // Group Messages CRUD Operations
  Future<String> sendGroupMessage({
    required String groupId,
    required String content,
    required String messageType,
  }) async {
    try {
      if (messageType != 'text' && messageType != 'announcement') {
        throw Exception(
            'Invalid message type. Must be either "text" or "announcement"');
      }

      final docRef = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_messages')
          .add({
        'user_id': currentUserId,
        'content': content,
        'message_type': messageType,
        'created_at': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send group message: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getGroupMessages(String groupId) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('group_messages')
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

  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    try {
      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete group message: $e');
    }
  }

  // Group Events CRUD Operations
  Future<String> createGroupEvent({
    required String groupId,
    required String title,
    required String description,
    required DateTime eventTime,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      // Get all admin members
      final adminMembers = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_members')
          .where('role', isEqualTo: 'admin')
          .get();

      // Create list of participant IDs including all admins and the creator
      final participantIds = adminMembers.docs.map((doc) => doc.id).toList();
      if (!participantIds.contains(currentUserId)) {
        participantIds.add(currentUserId);
      }

      final docRef = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_events')
          .add({
        'title': title,
        'description': description,
        'event_time': Timestamp.fromDate(eventTime),
        'created_by': currentUserId,
        'participants': participantIds,
        'created_at': FieldValue.serverTimestamp(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationName != null) 'location_name': locationName,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create group event: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getGroupEvents(String groupId) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('group_events')
        .orderBy('event_time', descending: true)
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

  Future<void> updateGroupEvent({
    required String groupId,
    required String eventId,
    String? title,
    String? description,
    DateTime? eventTime,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (eventTime != null) 'event_time': Timestamp.fromDate(eventTime),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationName != null) 'location_name': locationName,
      };

      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_events')
          .doc(eventId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update group event: $e');
    }
  }

  Future<void> deleteGroupEvent(String groupId, String eventId) async {
    try {
      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_events')
          .doc(eventId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete group event: $e');
    }
  }

  // Helper method to check if user is admin
  Future<bool> isUserAdmin(String groupId) async {
    try {
      final memberDoc = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_members')
          .doc(currentUserId)
          .get();

      if (!memberDoc.exists) return false;

      final data = memberDoc.data();
      return data?['role'] == 'admin';
    } catch (e) {
      throw Exception('Failed to check admin status: $e');
    }
  }

  // Get a specific group event by ID
  Future<Map<String, dynamic>?> getGroupEventById(
      String groupId, String eventId) async {
    try {
      final doc = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_events')
          .doc(eventId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'id': doc.id,
        ...data,
      };
    } catch (e) {
      throw Exception('Failed to get group event: $e');
    }
  }

  // Get participants of a specific event
  Stream<List<Map<String, dynamic>>> getEventParticipants(
      String groupId, String eventId) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('group_events')
        .doc(eventId)
        .snapshots()
        .asyncMap((eventDoc) async {
      if (!eventDoc.exists) return [];

      final data = eventDoc.data()!;
      final participants = List<String>.from(data['participants'] ?? []);

      final participantsData = <Map<String, dynamic>>[];
      for (final userId in participants) {
        try {
          // Get user information
          final userDoc =
              await _firestore.collection('users').doc(userId).get();

          // Get member role from group_members subcollection
          final memberDoc = await _firestore
              .collection('community_groups')
              .doc(groupId)
              .collection('group_members')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            participantsData.add({
              'id': userId,
              'firstName': userData['firstName'] ?? '',
              'lastName': userData['lastName'] ?? '',
              'email': userData['email'] ?? '',
              'photo_url': userData['photo_url'],
              'role': memberDoc.exists
                  ? (memberDoc.data()?['role'] ?? 'member')
                  : 'member',
            });
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }

      return participantsData;
    });
  }

  // Get groups that the current user is a member of
  Stream<List<Map<String, dynamic>>> getUserGroups() {
    return _firestore
        .collection('community_groups')
        .snapshots()
        .asyncMap((snapshot) async {
      final groups = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final groupId = doc.id;

        // Check if current user is a member
        final memberSnapshot = await _firestore
            .collection('community_groups')
            .doc(groupId)
            .collection('group_members')
            .doc(currentUserId)
            .get();

        if (memberSnapshot.exists) {
          // User is a member of this group
          final membersSnapshot = await _firestore
              .collection('community_groups')
              .doc(groupId)
              .collection('group_members')
              .get();

          final membersList =
              membersSnapshot.docs.map((doc) => doc.id).toList();

          groups.add({
            'id': groupId,
            'name': data['name'] ?? 'Unnamed Group',
            'description': data['description'] ?? 'No description',
            'community_name': data['community_name'] ?? 'Community',
            'created_by': data['created_by'],
            'created_at': data['created_at'],
            'members': membersList,
          });
        }
      }

      return groups;
    });
  }

  // Get all community groups
  Stream<List<Map<String, dynamic>>> getAllCommunityGroups() {
    return _firestore
        .collection('community_groups')
        .snapshots()
        .asyncMap((snapshot) async {
      final groups = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final groupId = doc.id;

        // Get all members
        final membersSnapshot = await _firestore
            .collection('community_groups')
            .doc(groupId)
            .collection('group_members')
            .get();

        final membersList = membersSnapshot.docs.map((doc) => doc.id).toList();

        groups.add({
          'id': groupId,
          'name': data['name'] ?? 'Unnamed Group',
          'description': data['description'] ?? 'No description',
          'community_name': data['community_name'] ?? 'Community',
          'created_by': data['created_by'],
          'created_at': data['created_at'],
          'members': membersList,
        });
      }

      return groups;
    });
  }

  // Join a community group
  Future<void> joinCommunityGroup(String groupId) async {
    try {
      // Get user information
      final userInfo = await _userInformationService.getUserInfo(currentUserId);
      final firstName = userInfo?['firstName'] ?? '';
      final lastName = userInfo?['lastName'] ?? '';
      final phoneNumber = userInfo?['phoneNumber'] ?? '';

      // Add user to group members
      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_members')
          .doc(currentUserId)
          .set({
        'user_id': currentUserId,
        'role': 'member',
        'name': '$firstName $lastName',
        'contact': phoneNumber,
        'joined_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to join community group: $e');
    }
  }

  // Join a group event
  Future<void> joinGroupEvent(String groupId, String eventId) async {
    try {
      final eventRef = _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_events')
          .doc(eventId);

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data()!;
      final participants = List<String>.from(eventData['participants'] ?? []);

      // Check if user is already a participant
      if (participants.contains(currentUserId)) {
        throw Exception('Already joined this event');
      }

      // Add user to participants
      participants.add(currentUserId);
      await eventRef.update({'participants': participants});
    } catch (e) {
      throw Exception('Failed to join event: $e');
    }
  }

  // Leave a group event
  Future<void> leaveGroupEvent(String groupId, String eventId) async {
    try {
      final eventRef = _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_events')
          .doc(eventId);

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data()!;
      final participants = List<String>.from(eventData['participants'] ?? []);

      // Check if user is a participant
      if (!participants.contains(currentUserId)) {
        throw Exception('Not joined this event');
      }

      // Remove user from participants
      participants.remove(currentUserId);
      await eventRef.update({'participants': participants});
    } catch (e) {
      throw Exception('Failed to leave event: $e');
    }
  }
}
