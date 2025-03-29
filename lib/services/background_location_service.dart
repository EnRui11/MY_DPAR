import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _locationTimer;
  static const _defaultLocation = GeoPoint(3.1390, 101.6869);

  void startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateLocation(),
    );
  }

  void stopLocationUpdates() {
    _locationTimer?.cancel();
  }

  Future<void> _updateLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!await _checkLocationPermission()) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      final address = placemarks.isNotEmpty
          ? _formatAddress(placemarks.first)
          : 'Unnamed Location';

      await _updateFirestore(user.uid, position, address);
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  String _formatAddress(Placemark place) {
    return [
      place.street,
      place.locality,
      place.administrativeArea,
      place.postalCode,
    ].where((e) => e != null && e.isNotEmpty).join(', ').trim();
  }

  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _updateFirestore(String uid, Position position, String address) async {
    final updateData = {
      'userId': uid,
      'lastUpdateTime': Timestamp.now(),
      'location': GeoPoint(position.latitude, position.longitude),
      'address': address,
      'isOnline': true,
    };

    try {
      await _firestore.collection('user_locations').doc(uid).set(updateData);
    } catch (e) {
      debugPrint('Failed to update location in Firestore: $e');
    }
  }
}