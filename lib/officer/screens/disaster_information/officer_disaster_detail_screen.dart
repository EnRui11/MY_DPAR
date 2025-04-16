import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/officer/screens/disaster_information/officer_select_disaster_location_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/fire_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/flood_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/landslide_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/heavy_rain_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/haze_guide_screen.dart';

/// Screen for officers to view and edit disaster details.
class OfficerDisasterDetailScreen extends StatefulWidget {
  final String disasterId;

  const OfficerDisasterDetailScreen({super.key, required this.disasterId});

  @override
  State<OfficerDisasterDetailScreen> createState() =>
      _OfficerDisasterDetailScreenState();
}

class _OfficerDisasterDetailScreenState
    extends State<OfficerDisasterDetailScreen> {
  DisasterModel? _disaster;
  bool _isLoading = true;
  LatLng? _userLocation;
  String? _distanceText;
  final _descriptionController = TextEditingController();
  List<String> _photoPaths = [];
  String? _selectedStatus;
  String? _selectedSeverity;
  bool _isSaving = false;

  // Add temporary variables to store location changes
  LatLng? _tempCoordinates;
  String? _tempLocationName;

  // Constants for status and severity options
  static const _statusTypes = [
    'happening',
    'pending',
    'resolved',
    'false_alarm'
  ];
  static const _severityLevels = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _loadDisasterData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Fetches the user's current location using Geolocator.
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _calculateDistance();
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  /// Loads disaster data from the service using the provided disaster ID.
  Future<void> _loadDisasterData() async {
    final disasterService =
        Provider.of<DisasterService>(context, listen: false);
    try {
      final disaster = await disasterService.getDisasterById(widget.disasterId);
      setState(() {
        _disaster = disaster;
        _isLoading = false;
        _descriptionController.text = disaster?.description ?? '';
        _photoPaths = List<String>.from(disaster?.photoPaths ?? []);
        _selectedStatus = disaster?.status?.toLowerCase()?.replaceAll(' ', '_');
        _selectedSeverity = disaster?.severity?.toLowerCase();
        _calculateDistance();
      });
    } catch (e) {
      debugPrint('Error loading disaster: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Calculates the distance between the user and disaster location.
  void _calculateDistance() {
    if (_disaster?.coordinates == null || _userLocation == null) return;
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      _disaster!.coordinates!.latitude,
      _disaster!.coordinates!.longitude,
    );
    final localizations = AppLocalizations.of(context);
    setState(() {
      _distanceText = localizations
          .translate('distance_away')
          .replaceAll('{distance}', (distance / 1000).toStringAsFixed(1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Provider.of<ThemeProvider>(context, listen: true).currentTheme;
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colors.bg200,
      body: _isLoading
          ? _buildLoadingIndicator(colors)
          : _disaster == null
              ? _buildErrorMessage(localizations, colors)
              : SafeArea(
                  child: Stack(children: [
                  _buildContent(colors, localizations),
                  _buildGlassAppBar(colors, localizations),
                ])),
    );
  }

  /// Builds a loading indicator for initial data fetch.
  Widget _buildLoadingIndicator(AppColorTheme colors) =>
      Center(child: CircularProgressIndicator(color: colors.accent200));

  /// Builds an error message when disaster data fails to load.
  Widget _buildErrorMessage(
          AppLocalizations localizations, AppColorTheme colors) =>
      Center(
        child: Text(
          localizations.translate('error_loading_disaster'),
          style: TextStyle(color: colors.text200),
        ),
      );

  /// Builds the glass-effect app bar with back button and title.
  Widget _buildGlassAppBar(
          AppColorTheme colors, AppLocalizations localizations) =>
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border:
              Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
          boxShadow: [
            BoxShadow(color: colors.bg300.withOpacity(0.1), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.accent200),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              localizations.translate('disaster_details'),
              style: TextStyle(
                color: colors.accent200,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  /// Builds the scrollable content area.
  Widget _buildContent(AppColorTheme colors, AppLocalizations localizations) =>
      SingleChildScrollView(
        padding:
            const EdgeInsets.only(top: 72, bottom: 24, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertHeader(colors, localizations),
            const SizedBox(height: 16),
            _buildLocationSection(colors, localizations),
            const SizedBox(height: 16),
            _buildStatusSection(colors, localizations),
            const SizedBox(height: 16),
            _buildSeveritySection(colors, localizations),
            const SizedBox(height: 16),
            _buildDescriptionSection(colors, localizations),
            const SizedBox(height: 16),
            _buildPhotoSection(colors, localizations),
            const SizedBox(height: 24),
            _buildRelatedGuides(colors, localizations),
            const SizedBox(height: 24),
            _buildSaveButton(colors, localizations),
          ],
        ),
      );

  /// Builds the header with disaster type and severity.
  Widget _buildAlertHeader(
          AppColorTheme colors, AppLocalizations localizations) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  DisasterService.getSeverityColor(_disaster!.severity, colors)
                      .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              DisasterService.getDisasterIcon(_disaster!.disasterType),
              color:
                  DisasterService.getSeverityColor(_disaster!.severity, colors),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate(
                      'disaster_type_${_disaster!.disasterType.toLowerCase().replaceAll(' ', '_')}'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.text100,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DisasterService.getSeverityColor(
                            _disaster!.severity, colors),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        localizations.translate(
                            'severity_${_disaster!.severity.toLowerCase()}'),
                        style: TextStyle(color: colors.bg100, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_getLocalizedTimeAgo(context, DateTime.parse(_disaster!.timestamp))}',
                      style: TextStyle(color: colors.text200, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  /// Builds the location section with map and distance.
  Widget _buildLocationSection(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildGlassContainer(
        colors,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: colors.accent200, size: 20),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('location'),
                  style: TextStyle(
                      color: colors.text100, fontWeight: FontWeight.w600),
                ),
                if (_distanceText != null) ...[
                  const Spacer(),
                  _buildDistanceChip(colors),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(_disaster!.location, style: TextStyle(color: colors.text200)),
            if (_disaster!.coordinates != null) ...[
              const SizedBox(height: 8),
              _buildMap(colors),
              const SizedBox(height: 8),
              Text(
                localizations.translate('tap_map_to_edit_location'),
                style: TextStyle(
                  color: colors.text200.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );

  /// Builds the distance chip showing proximity to the disaster.
  Widget _buildDistanceChip(AppColorTheme colors) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.accent200.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.accent200.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.near_me, size: 14, color: colors.accent200),
            const SizedBox(width: 4),
            Text(
              _distanceText!,
              style: TextStyle(
                fontSize: 12,
                color: colors.accent200,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  /// Builds the interactive map with disaster and user markers.
  Widget _buildMap(AppColorTheme colors) => GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectDisasterLocationScreen(
                  initialLocation: _disaster!.coordinates),
            ),
          );
          if (result != null &&
              result is Map &&
              result['latitude'] != null &&
              result['longitude'] != null) {
            setState(() {
              // Store the new location in temporary variables instead of updating the disaster model
              _tempCoordinates =
                  LatLng(result['latitude'], result['longitude']);
              _tempLocationName = result['locationName'] ?? _disaster!.location;

              // Show a snackbar to indicate that changes need to be saved
              _showSnackBar(
                AppLocalizations.of(context).translate('location_updated'),
                backgroundColor: Colors.blue,
              );
            });
          }
        },
        child: Stack(
          children: [
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    center: _disaster!.coordinates,
                    zoom: 13,
                    interactiveFlags: InteractiveFlag.none,
                  ),
                  children: [
                    TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _disaster!.coordinates!,
                          builder: (_) => Icon(
                            Icons.location_pin,
                            color: DisasterService.getSeverityColor(
                                _disaster!.severity, colors),
                            size: 40,
                          ),
                        ),
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            builder: (_) => Container(
                              decoration: BoxDecoration(
                                color: colors.accent200.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.my_location,
                                  color: colors.accent200,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent200.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_location, color: colors.bg100, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context).translate('edit_location'),
                      style: TextStyle(
                        color: colors.bg100,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  /// Builds the status dropdown section.
  Widget _buildStatusSection(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildGlassContainer(
        colors,
        Row(
          children: [
            Icon(Icons.info_outline, color: colors.accent200, size: 20),
            const SizedBox(width: 8),
            Text(
              localizations.translate('status'),
              style:
                  TextStyle(color: colors.text100, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedStatus,
              items: _statusTypes
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(localizations
                            .translate('status_${status.toLowerCase()}')),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
          ],
        ),
      );

  /// Builds the severity dropdown section.
  Widget _buildSeveritySection(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildGlassContainer(
        colors,
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: colors.accent200, size: 20),
            const SizedBox(width: 8),
            Text(
              localizations.translate('severity_level'),
              style:
                  TextStyle(color: colors.text100, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedSeverity,
              items: _severityLevels
                  .map((severity) => DropdownMenuItem(
                        value: severity,
                        child: Text(localizations
                            .translate('severity_${severity.toLowerCase()}')),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSeverity = value),
            ),
          ],
        ),
      );

  /// Builds the editable description section.
  Widget _buildDescriptionSection(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildGlassContainer(
        colors,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: colors.accent200, size: 20),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('description'),
                  style: TextStyle(
                      color: colors.text100, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: null,
              style: TextStyle(color: colors.text200),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: colors.bg200,
                hintText: localizations.translate('enter_description'),
              ),
            ),
          ],
        ),
      );

  /// Builds the photo section with upload and delete options.
  Widget _buildPhotoSection(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildGlassContainer(
        colors,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: colors.accent200, size: 20),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('photos'),
                  style: TextStyle(
                      color: colors.text100, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.photo_camera, color: colors.accent200),
                  onPressed: _takeAndAddPhoto,
                  tooltip: localizations.translate('take_photo'),
                ),
                IconButton(
                  icon: Icon(Icons.photo, color: colors.accent200),
                  onPressed: _pickAndAddPhoto,
                  tooltip: localizations.translate('add_photo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _photoPaths.isEmpty
                ? Text(localizations.translate('no_photos'),
                    style: TextStyle(color: colors.text200))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _photoPaths.length,
                    itemBuilder: (context, index) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _photoPaths[index].startsWith('http')
                              ? Image.network(
                                  _photoPaths[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Image.file(
                                  File(_photoPaths[index]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _photoPaths.removeAt(index)),
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      );

  /// Uploads a photo from the gallery to Firebase Storage.
  Future<void> _pickAndAddPhoto() async {
    final localizations = AppLocalizations.of(context);
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      await _uploadPhoto(pickedFile, localizations);
    } catch (e) {
      _showErrorSnackBar(localizations.translate('upload_failed'), e);
      debugPrint('Error uploading photo: $e');
    }
  }

  /// Captures and uploads a photo from the camera to Firebase Storage.
  Future<void> _takeAndAddPhoto() async {
    final localizations = AppLocalizations.of(context);
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      await _uploadPhoto(pickedFile, localizations);
    } catch (e) {
      _showErrorSnackBar(localizations.translate('upload_failed'), e);
      debugPrint('Error uploading photo: $e');
    }
  }

  /// Uploads a photo file to Firebase Storage and updates photo paths.
  Future<void> _uploadPhoto(
      XFile pickedFile, AppLocalizations localizations) async {
    setState(() => _isSaving = true);
    try {
      final uuid = const Uuid().v4();
      final ext = path.extension(pickedFile.path);
      final fileName = '$uuid$ext';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('disaster_photos')
          .child(_disaster!.id)
          .child(fileName);
      final uploadTask = storageRef.putFile(File(pickedFile.path));
      _showSnackBar(localizations.translate('uploading_photo'),
          duration: const Duration(seconds: 2));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _photoPaths.add(downloadUrl);
        _isSaving = false;
      });
      _showSnackBar(localizations.translate('photo_uploaded'),
          backgroundColor: Colors.green);
    } catch (e) {
      setState(() => _isSaving = false);
      rethrow;
    }
  }

  /// Builds the related guides section with navigation to safety tips.
  Widget _buildRelatedGuides(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('safety_tips'),
            style: TextStyle(
                color: colors.text100,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildGuideButton(
            colors,
            title:
                '${localizations.translate('disaster_type_${_disaster!.disasterType.toLowerCase().replaceAll(' ', '_')}')} ${localizations.translate('safety_tips')}',
            description:
                '${localizations.translate('learn_handle')} ${localizations.translate('disaster_type_${_disaster!.disasterType.toLowerCase().replaceAll(' ', '_')}')} ${localizations.translate('situations')}',
            icon: DisasterService.getDisasterIcon(_disaster!.disasterType),
            onTap: () => _navigateToGuide(
                context, _disaster!.disasterType, localizations),
          ),
        ],
      );

  /// Builds a guide button for navigating to safety tips.
  Widget _buildGuideButton(
    AppColorTheme colors, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bg100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.bg300.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accent200.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.accent200),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          color: colors.text100, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: colors.text200, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: colors.accent200, size: 16),
            ],
          ),
        ),
      );

  /// Builds the save button for persisting changes.
  Widget _buildSaveButton(
          AppColorTheme colors, AppLocalizations localizations) =>
      Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: Text(localizations.translate('save_changes')),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent200,
            foregroundColor: colors.bg100,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          onPressed: _isSaving ? null : () => _saveChanges(),
        ),
      );

  /// Saves updated disaster data to the service.
  Future<void> _saveChanges() async {
    if (_disaster == null) return;
    setState(() => _isSaving = true);
    final localizations = AppLocalizations.of(context);
    try {
      final disasterService =
          Provider.of<DisasterService>(context, listen: false);

      // Create a copy of the disaster model with all changes
      final updated = DisasterModel(
        id: _disaster!.id,
        userId: _disaster!.userId,
        disasterType: _disaster!.disasterType,
        otherDisasterType: _disaster!.otherDisasterType,
        severity: _selectedSeverity != null
            ? _selectedSeverity!.substring(0, 1).toUpperCase() +
                _selectedSeverity!.substring(1)
            : _disaster!.severity,
        // Use temporary location values if they exist, otherwise use current values
        location: _tempLocationName ?? _disaster!.location,
        coordinates: _tempCoordinates ?? _disaster!.coordinates,
        description: _descriptionController.text,
        photoPaths: _photoPaths,
        timestamp: _disaster!.timestamp,
        status: _selectedStatus != null
            ? _selectedStatus!
                .replaceAll('_', ' ')
                .split(' ')
                .map((w) => w[0].toUpperCase() + w.substring(1))
                .join(' ')
            : _disaster!.status,
        userList: _disaster!.userList,
        locationList: _disaster!.locationList,
        verificationCount: _disaster!.verificationCount,
      );

      await disasterService.updateDisaster(updated);

      // Clear temporary variables after successful save
      setState(() {
        _tempCoordinates = null;
        _tempLocationName = null;
      });

      _showSnackBar(localizations.translate('changes_saved'));
      await _loadDisasterData();
    } catch (e) {
      _showErrorSnackBar(localizations.translate('failed_to_save'), e);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Navigates to the appropriate guide screen based on disaster type.
  void _navigateToGuide(BuildContext context, String disasterType,
      AppLocalizations localizations) {
    Widget? screen;
    switch (disasterType.toLowerCase()) {
      case 'fire':
        screen = const FireGuideScreen();
        break;
      case 'flood':
        screen = const FloodGuideScreen();
        break;
      case 'landslide':
        screen = const LandslideGuideScreen();
        break;
      case 'heavy_rain':
        screen = const HeavyRainGuideScreen();
        break;
      case 'haze':
        screen = const HazeGuideScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    } else {
      _showSnackBar(localizations.translate('safety_guide_not_available'));
    }
  }

  /// Builds a glass-effect container for sections.
  Widget _buildGlassContainer(AppColorTheme colors, Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.bg300.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  /// Shows a snackbar with a message and optional background color.
  void _showSnackBar(String message,
      {Color? backgroundColor, Duration? duration}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration ?? const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Shows an error snackbar with a message and error details.
  void _showErrorSnackBar(String message, Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$message: $error'), backgroundColor: Colors.red),
      );
    }
  }
}

/// Returns a localized string indicating how long ago a timestamp occurred.
String _getLocalizedTimeAgo(BuildContext context, DateTime timestamp) {
  final localizations = AppLocalizations.of(context);
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return years == 1
        ? localizations.translate('time_year_ago')
        : localizations
            .translate('time_years_ago')
            .replaceAll('{count}', years.toString());
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return months == 1
        ? localizations.translate('time_month_ago')
        : localizations
            .translate('time_months_ago')
            .replaceAll('{count}', months.toString());
  } else if (difference.inDays > 0) {
    return difference.inDays == 1
        ? localizations.translate('time_day_ago')
        : localizations
            .translate('time_days_ago')
            .replaceAll('{count}', difference.inDays.toString());
  } else if (difference.inHours > 0) {
    return difference.inHours == 1
        ? localizations.translate('time_hour_ago')
        : localizations
            .translate('time_hours_ago')
            .replaceAll('{count}', difference.inHours.toString());
  } else if (difference.inMinutes > 0) {
    return difference.inMinutes == 1
        ? localizations.translate('time_minute_ago')
        : localizations
            .translate('time_minutes_ago')
            .replaceAll('{count}', difference.inMinutes.toString());
  } else {
    return localizations.translate('time_just_now');
  }
}
