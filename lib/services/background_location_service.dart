import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Manages background location updates for authenticated users, storing data in Firestore.
class BackgroundLocationService {
  // Singleton pattern
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
  factory BackgroundLocationService() => _instance;

  // Dependencies
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Timer? _locationTimer;

  // Constants
  static const _updateInterval = Duration(seconds: 1);
  static const _defaultLocation = GeoPoint(3.1390, 101.6869); // Kuala Lumpur

  /// Private constructor for singleton initialization with default dependencies.
  BackgroundLocationService._internal(this._auth, this._firestore);

  /// Constructs the services with optional Firebase dependencies for testing.
  BackgroundLocationService.withDependencies({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Starts periodic location updates.
  void startLocationUpdates() {
    _locationTimer?.cancel(); // Prevent multiple timers
    _locationTimer = Timer.periodic(_updateInterval, (_) => _updateLocation());
  }

  /// Stops location updates and cancels the timer.
  void stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Updates the user's location in Firestore if authenticated and permissions are granted.
  Future<void> _updateLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!await _checkLocationPermission()) return;

    try {
      final position = await _fetchCurrentPosition();
      final address = await _getAddressFromPosition(position);
      await _saveLocationToFirestore(user.uid, position, address);
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  /// Fetches the current position with high accuracy.
  Future<Position> _fetchCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Retrieves an address from a given position.
  Future<String> _getAddressFromPosition(Position position) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      return placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : 'Unnamed Location';
    } catch (e) {
      debugPrint('Error geocoding position: $e');
      return 'Unknown Location';
    }
  }

  /// Formats a placemark into a readable address string.
  String _formatAddress(Placemark place) {
    return [
      place.street,
      place.locality,
      place.administrativeArea,
      place.postalCode,
    ].where((e) => e != null && e.isNotEmpty).join(', ').trim();
  }

  /// Checks and requests location permissions, returning true if granted.
  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('Location services are disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Saves the user's location data to Firestore.
  Future<void> _saveLocationToFirestore(
      String uid, Position position, String address) async {
    final updateData = {
      'userId': uid,
      'lastUpdateTime': Timestamp.now(),
      'location': GeoPoint(position.latitude, position.longitude),
      'address': address,
      'isOnline': true,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'heading': position.heading,
      'timestamp': Timestamp.now(),
      'locationUpdateStatus': 'success',
    };

    try {
      // Use set with merge to ensure the document exists
      await _firestore.collection('user_locations').doc(uid).set(
            updateData,
            SetOptions(merge: true),
          );

      // Update the user's main document to show they're active
      await _firestore.collection('users').doc(uid).update({
        'lastActive': Timestamp.now(),
        'isOnline': true,
      });

      debugPrint('Location updated successfully for user $uid');
    } catch (e) {
      debugPrint('Failed to update Firestore: $e');

      // Try to update the error status
      try {
        await _firestore.collection('user_locations').doc(uid).set({
          'locationUpdateStatus': 'error',
          'lastError': e.toString(),
          'lastErrorTime': Timestamp.now(),
        }, SetOptions(merge: true));
      } catch (innerE) {
        debugPrint('Failed to update error status: $innerE');
      }

      throw Exception('Failed to save location: $e');
    }
  }

  /// Returns the default location as a GeoPoint.
  GeoPoint get defaultLocation => _defaultLocation;
}
