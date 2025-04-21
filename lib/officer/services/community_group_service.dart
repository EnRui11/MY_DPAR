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
      final docRef = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('group_events')
          .add({
        'title': title,
        'description': description,
        'event_time': Timestamp.fromDate(eventTime),
        'created_by': currentUserId,
        'participants': [currentUserId],
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
}
