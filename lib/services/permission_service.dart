import 'dart:io'; // Add this for Platform check
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Add this for Geolocator
import 'package:permission_handler/permission_handler.dart';

/// Manages requesting and handling initial app permissions.
class PermissionService extends ChangeNotifier {
  /// Requests all required initial permissions for the app.
  Future<void> requestInitialPermissions() async {
    // Existing permissions
    await _requestPermission(Permission.locationWhenInUse, 'Location');
    await _requestPermission(Permission.notification, 'Notification');
    await _requestPermission(Permission.camera, 'Camera');
    await _requestStoragePermissions();

    // Add Geolocator-based location permission handling
    LocationPermission geoPermission = await Geolocator.checkPermission();
    if (geoPermission == LocationPermission.denied) {
      geoPermission = await Geolocator.requestPermission();
      notifyListeners(); // Notify listeners on permission change
    }

    // On Android 10+ (API 29+), request background location permission
    if (Platform.isAndroid) {
      if (geoPermission == LocationPermission.whileInUse) {
        // Request background location permission using permission_handler
        await _requestPermission(
            Permission.locationAlways, 'Background Location');
        debugPrint(
            'Background location permission requested for emergency features');
      }
    }
  }

  /// Requests a single permission and notifies listeners on status change.
  Future<void> _requestPermission(
      Permission permission, String permissionName) async {
    final status = await permission.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('$permissionName permission denied');
      // Consider notifying user via UI in production
    }
    notifyListeners();
  }

  /// Requests storage-related permissions if denied.
  Future<void> _requestStoragePermissions() async {
    if (await Permission.storage.isDenied) {
      await _requestPermission(Permission.storage, 'Storage');
    }
    if (await Permission.photos.isDenied) {
      await _requestPermission(Permission.photos, 'Photos');
    }
  }
}
