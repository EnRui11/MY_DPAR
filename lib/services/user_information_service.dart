import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mydpar/services/background_location_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Model for emergency contact data
class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String? ?? 'Unknown',
        relation: json['relation'] as String? ?? 'Not specified',
        phone: json['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'phone': phone,
      };
}

class UserInformationService extends ChangeNotifier {
  String? _userId;
  String? _firstName;
  String? _lastName;
  String? _photoUrl;
  String? _email;
  String? _phoneNumber;
  List<EmergencyContact> _contacts = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _role;

  // Private Firebase instances for better encapsulation
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  String? get userId => _userId;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get photoUrl => _photoUrl;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  List<EmergencyContact> get contacts =>
      List.unmodifiable(_contacts); // Immutable list for safety
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _auth.currentUser != null;

  UserInformationService() {
    _initializeUser();
    setupTokenRefreshListener();
  }

  /// Initializes user data from Firebase Auth and Firestore.
  Future<void> _initializeUser() async {
    if (_isInitialized) return;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user signed in during initialization');
        return;
      }

      _userId = user.uid;
      _email = user.email;
      _photoUrl = user.photoURL;

      await _loadUserData();
      await updateFcmToken();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  String? get role => _role;

  /// Loads user data from Firestore.
  Future<void> _loadUserData() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _firstName = data['firstName'] as String?;
        _lastName = data['lastName'] as String? ?? 'User';
        _phoneNumber = data['phoneNumber'] as String?;
        _role = data['role'] as String? ?? 'normal';
        _contacts = (data['emergencyContacts'] as List<dynamic>? ?? [])
            .map((item) =>
                EmergencyContact.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Initialize default user document if it doesn't exist
        await _firestore.collection('users').doc(_userId).set({
          'firstName': _firstName,
          'lastName': _lastName ?? 'User',
          'email': _email,
          'phoneNumber': _phoneNumber,
          'emergencyContacts': [],
          'role': 'normal',
        }, SetOptions(merge: true));
        _lastName ??= 'User';
        _role = 'normal';
        _contacts = [];
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow; // Allow callers to handle errors if needed
    }
  }

  /// Refreshes user data from Firestore.
  Future<void> refreshUserData() async {
    try {
      await _loadUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      rethrow;
    }
  }

  /// Fetches user info from Firestore by userId.
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching user info: $e');
      return null;
    }
  }

  /// Register a new user with email and password
  Future<UserCredential> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    List<EmergencyContact> emergencyContacts = const [],
    String role = 'normal',
  }) async {
    _setLoading(true);
    try {
      // Create the user with Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Initialize user data
      _userId = credential.user!.uid;
      _firstName = firstName;
      _lastName = lastName;
      _email = email;
      _phoneNumber = phoneNumber;
      _contacts = List.from(emergencyContacts);

      await updateFcmToken();
      _isInitialized = true;
      notifyListeners();

      return credential;
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password
  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _userId = credential.user!.uid;
      _email = email;

      await _loadUserData();
      await updateFcmToken();
      _isInitialized = true;
      notifyListeners();

      return credential;
    } catch (e) {
      debugPrint('Error logging in: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates profile photo in Firebase Storage, Auth, and Firestore.
  Future<String> updateProfilePhoto(String filePath) async {
    if (_userId == null) throw Exception('No user signed in');
    _setLoading(true);

    try {
      final ref = _storage.ref().child('user_photos').child('$_userId.jpg');
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask.whenComplete(() {});
      final photoUrl = await snapshot.ref.getDownloadURL();

      await _auth.currentUser?.updatePhotoURL(photoUrl);
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({'photoUrl': photoUrl});

      _photoUrl = photoUrl;
      notifyListeners();
      return photoUrl;
    } catch (e) {
      debugPrint('Error updating profile photo: $e');
      throw Exception('Failed to update profile photo: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Adds an emergency contact to Firestore.
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    if (_userId == null) throw Exception('No user signed in');
    _setLoading(true);

    try {
      final docRef = _firestore.collection('users').doc(_userId);
      final doc = await docRef.get();
      final currentContacts = List<Map<String, dynamic>>.from(
          doc.data()?['emergencyContacts'] ?? []);
      currentContacts.add(contact.toJson());

      await docRef.update({'emergencyContacts': currentContacts});
      _contacts.add(contact);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      throw Exception('Failed to add emergency contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates an existing emergency contact in Firestore.
  Future<void> updateEmergencyContact(
      int index, EmergencyContact contact) async {
    if (_userId == null) throw Exception('No user signed in');
    if (index < 0 || index >= _contacts.length)
      throw Exception('Invalid contact index');
    _setLoading(true);

    try {
      final docRef = _firestore.collection('users').doc(_userId);
      final doc = await docRef.get();
      final currentContacts = List<Map<String, dynamic>>.from(
          doc.data()?['emergencyContacts'] ?? []);
      currentContacts[index] = contact.toJson();

      await docRef.update({'emergencyContacts': currentContacts});
      _contacts[index] = contact;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      throw Exception('Failed to update emergency contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes an emergency contact from Firestore.
  Future<void> deleteEmergencyContact(int index) async {
    if (_userId == null) throw Exception('No user signed in');
    if (index < 0 || index >= _contacts.length)
      throw Exception('Invalid contact index');
    _setLoading(true);

    try {
      final docRef = _firestore.collection('users').doc(_userId);
      final doc = await docRef.get();
      final currentContacts = List<Map<String, dynamic>>.from(
          doc.data()?['emergencyContacts'] ?? []);
      currentContacts.removeAt(index);

      await docRef.update({'emergencyContacts': currentContacts});
      _contacts.removeAt(index);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      throw Exception('Failed to delete emergency contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Update user's online status before logging out
      if (_userId != null) {
        await _firestore.collection('user_locations').doc(_userId).update({
          'isOnline': false,
          'lastUpdateTime': Timestamp.now(),
          'fcmToken': FieldValue.delete(),
        });
      }

      // Stop location updates
      BackgroundLocationService().stopLocationUpdates();

      await _auth.signOut();
      _resetState();
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out: $e');
      throw Exception('Failed to log out: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the first name in Firestore.
  Future<void> updateFirstName(String firstName) async {
    if (_userId == null) throw Exception('No user signed in');
    _setLoading(true);

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({'firstName': firstName});
      _firstName = firstName;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating first name: $e');
      throw Exception('Failed to update first name: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the last name in Firestore.
  Future<void> updateLastName(String lastName) async {
    if (_userId == null) throw Exception('No user signed in');
    _setLoading(true);

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({'lastName': lastName});
      _lastName = lastName;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating last name: $e');
      throw Exception('Failed to update last name: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the email in Firebase Auth and Firestore.
  Future<void> updateEmail(String email) async {
    if (_userId == null) throw Exception('No user signed in');
    _setLoading(true);

    try {
      await _auth.currentUser?.updateEmail(email);
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({'email': email});
      _email = email;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating email: $e');
      throw Exception('Failed to update email: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the phone number in Firestore.
  Future<void> updatePhoneNumber(String phoneNumber) async {
    if (_userId == null) throw Exception('No user signed in');
    _setLoading(true);

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({'phoneNumber': phoneNumber});
      _phoneNumber = phoneNumber;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating phone number: $e');
      throw Exception('Failed to update phone number: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Resets provider state after logout or error.
  void _resetState() {
    _userId = null;
    _firstName = null;
    _lastName = null;
    _photoUrl = null;
    _email = null;
    _phoneNumber = null;
    _role = null;
    _contacts = [];
    _isInitialized = false;
    _isLoading = false;
  }

  /// Explicitly set loading state
  void setLoading(bool loading) {
    _setLoading(loading);
  }

  /// Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Add public method to initialize user
  Future<void> initializeUser() async {
    await _initializeUser();
  }

  /// Updates the user's FCM token for push notifications
  Future<void> updateFcmToken() async {
    if (_userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(_userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Check if a user is currently logged in
  bool checkUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Sets up a listener for FCM token refreshes
  void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (_userId != null) {
        _firestore.collection('users').doc(_userId).update({
          'fcmToken': newToken,
        }).then((_) {
          debugPrint('FCM token refreshed and updated in Firestore');
        }).catchError((e) {
          debugPrint('Error updating refreshed FCM token: $e');
        });
      }
    });
  }

  /// Updates FCM token on app launch
  Future<void> updateTokenOnLaunch() async {
    if (_auth.currentUser != null && _userId != null) {
      await updateFcmToken();
      debugPrint('FCM token updated on app launch');
    }
  }

  /// Updates the user's FCM token with a specific value
  Future<void> updateFcmTokenWithValue(String token) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token updated successfully');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      throw Exception('Failed to update FCM token: $e');
    }
  }
}
