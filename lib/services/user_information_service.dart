import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mydpar/screens/main/profile_screen.dart';

class UserInformationService with ChangeNotifier {
  String? _userId;
  String? _lastName;
  String? _photoUrl;
  String? _email;
  String? _phoneNumber;
  List<EmergencyContact> _contacts = [];
  bool _isInitialized = false;

  // Private Firebase instances for better encapsulation
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  String? get userId => _userId;
  String? get lastName => _lastName;
  String? get photoUrl => _photoUrl;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  List<EmergencyContact> get contacts =>
      List.unmodifiable(_contacts); // Immutable list for safety
  bool get isInitialized => _isInitialized;

  UserInformationService() {
    _initializeUser();
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
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  /// Loads user data from Firestore.
  Future<void> _loadUserData() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _lastName = data['lastName'] as String? ?? 'User';
        _phoneNumber = data['phoneNumber'] as String?;
        _contacts = (data['emergencyContacts'] as List<dynamic>? ?? [])
            .map((item) =>
                EmergencyContact.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Initialize default user document if it doesn't exist
        await _firestore.collection('users').doc(_userId).set({
          'lastName': _lastName ?? 'User',
          'email': _email,
          'phoneNumber': _phoneNumber,
          'emergencyContacts': [],
        }, SetOptions(merge: true));
        _lastName ??= 'User';
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

  /// Updates profile photo in Firebase Storage, Auth, and Firestore.
  Future<String> updateProfilePhoto(String filePath) async {
    if (_userId == null) throw Exception('No user signed in');

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
    }
  }

  /// Adds an emergency contact to Firestore.
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    if (_userId == null) throw Exception('No user signed in');

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
    }
  }

  /// Updates an existing emergency contact in Firestore.
  Future<void> updateEmergencyContact(
      int index, EmergencyContact contact) async {
    if (_userId == null) throw Exception('No user signed in');
    if (index < 0 || index >= _contacts.length)
      throw Exception('Invalid contact index');

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
    }
  }

  /// Deletes an emergency contact from Firestore.
  Future<void> deleteEmergencyContact(int index) async {
    if (_userId == null) throw Exception('No user signed in');
    if (index < 0 || index >= _contacts.length)
      throw Exception('Invalid contact index');

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
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _resetState();
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out: $e');
      throw Exception('Failed to log out: $e');
    }
  }

  /// Updates the last name in Firestore.
  Future<void> updateLastName(String lastName) async {
    if (_userId == null) throw Exception('No user signed in');

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
    }
  }

  /// Updates the email in Firebase Auth and Firestore.
  Future<void> updateEmail(String email) async {
    if (_userId == null) throw Exception('No user signed in');

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
    }
  }

  /// Resets provider state after logout or error.
  void _resetState() {
    _userId = null;
    _lastName = null;
    _photoUrl = null;
    _email = null;
    _phoneNumber = null;
    _contacts = [];
    _isInitialized = false;
  }

  /// Updates the phone number in Firestore.
  Future<void> updatePhoneNumber(String phoneNumber) async {
    // Add this method
    if (_userId == null) throw Exception('No user signed in');

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
    }
  }

  // Add public method to initialize user
  Future<void> initializeUser() async {
    await _initializeUser();
  }
}
