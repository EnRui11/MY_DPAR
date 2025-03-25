import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mydpar/screens/report_incident/select_location_screen.dart';
import 'package:mydpar/services/incident_verification_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

/// Model representing an incident report.
class IncidentReport {
  final String id;
  final String userId;
  final String incidentType;
  final String? otherIncidentType;
  final String severity;
  final String location;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> photoPaths;
  final String timestamp;
  final String status;
  final List<String>? userList;
  final List<Map<String, dynamic>>? locationList;
  final int? verifyNum;

  IncidentReport({
    String? id,
    required this.userId,
    required this.incidentType,
    this.otherIncidentType,
    required this.severity,
    required this.location,
    this.latitude,
    this.longitude,
    required this.description,
    required this.photoPaths,
    required this.timestamp,
    this.status = 'pending',
    this.userList,
    this.locationList,
    this.verifyNum,
  }) : id = id ?? _generateId(incidentType);

  /// Generates a unique ID for the incident.
  static String _generateId(String incidentType) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final randomStr = (Random().nextInt(9000) + 1000).toString();
    final typeStr = _getIncidentTypeShortForm(incidentType);
    return 'INC_${typeStr}_${dateStr}_${timeStr}_$randomStr';
  }

  /// Converts incident type to a short form.
  static String _getIncidentTypeShortForm(String type) {
    const map = {
      'heavy rain': 'RAIN',
      'flood': 'FLD',
      'fire': 'FIRE',
      'landslide': 'LAND',
      'haze': 'HAZE',
      'other': 'OTH',
    };
    return map[type.toLowerCase()] ?? type.substring(0, 4).toUpperCase();
  }

  /// Converts the report to a JSON map for Firestore.
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'incidentType': incidentType,
    'otherIncidentType': otherIncidentType,
    'severity': severity,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'photoPaths': photoPaths,
    'timestamp': timestamp,
    'status': status,
    'userList': userList ?? [userId],
    'locationList': locationList ?? [],
    'verifyNum': verifyNum ?? 1,
  };
}

/// Screen for reporting a new incident or updating an existing one.
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  // Form and state management
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final MapController _mapController;
  final _picker = ImagePicker();
  final _verificationService = IncidentVerificationService();
  List<File> _selectedPhotos = [];
  String? _selectedIncidentType;
  String? _otherIncidentType;
  String? _selectedSeverity;
  String? _selectedLocation;
  LatLng? _currentLocation;
  LatLng? _selectedMapLocation;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  // Constants
  static const _incidentTypes = ['Heavy Rain', 'Flood', 'Fire', 'Landslide', 'Haze', 'Other'];
  static const _severities = ['Low', 'Medium', 'High'];
  static const _defaultLocation = LatLng(3.1390, 101.6869); // Kuala Lumpur
  static const _padding = 24.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 16.0;
  static const _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _mapController = MapController();
    _initializeServices();
    _updateCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Initializes timezone and caches incidents.
  Future<void> _initializeServices() async {
    await IncidentVerificationService.initializeTimeZone();
    await _verificationService.cacheIncidents();
  }

  /// Updates the current location of the user.
  Future<void> _updateCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      if (!await _checkLocationPermission()) return;

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 15);
      });
    } catch (e) {
      //_showSnackBar('Failed to get current location: $e', Colors.red);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Checks and requests location permissions.
  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showSnackBar('Location services are disabled', Colors.red);
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied', Colors.red);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permission permanently denied', Colors.red);
      return false;
    }
    return true;
  }

  /// Handles form submission by creating or updating an incident.
  Future<void> _submitReport(AppColorTheme colors) async {
    if (!_isFormValid()) {
      _showValidationErrors(colors);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final photoUrls = await _uploadPhotos(colors);
      final timestamp = IncidentVerificationService.getCurrentTimestamp();

      if (_selectedMapLocation != null) {
        final existingIncident = await _verificationService.checkExistingIncident(
          incidentType: _selectedIncidentType!,
          latitude: _selectedMapLocation!.latitude,
          longitude: _selectedMapLocation!.longitude,
          timestamp: timestamp,
        );

        if (existingIncident != null) {
          await _verificationService.updateExistingIncident(
            incidentId: existingIncident['id'],
            userId: user.uid,
            latitude: _selectedMapLocation!.latitude,
            longitude: _selectedMapLocation!.longitude,
            severity: _selectedSeverity!,
            description: _descriptionController.text,
            photoPaths: photoUrls,
          );
          _showSnackBar('Incident updated successfully!', colors.accent200);
          _resetForm();
          return;
        }
      }

      final report = IncidentReport(
        userId: user.uid,
        incidentType: _selectedIncidentType!,
        otherIncidentType: _otherIncidentType,
        severity: _selectedSeverity!,
        location: _selectedLocation!,
        latitude: _selectedMapLocation?.latitude,
        longitude: _selectedMapLocation?.longitude,
        description: _descriptionController.text,
        photoPaths: photoUrls,
        timestamp: timestamp,
      );

      await FirebaseFirestore.instance.collection('incident_reports').doc(report.id).set(report.toJson());
      await _verificationService.cacheIncidents(); // Refresh cache
      _showSnackBar('New incident reported successfully!', colors.accent200);
      _resetForm();
    } catch (e) {
      _showSnackBar('Failed to submit report: $e', colors.warning);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Uploads selected photos to Firebase Storage.
  Future<List<String>> _uploadPhotos(AppColorTheme colors) async {
    try {
      return await Future.wait(_selectedPhotos.map((photo) async {
        final ref = FirebaseStorage.instance
            .ref()
            .child('incident_photos')
            .child('${DateTime.now().millisecondsSinceEpoch}_${photo.path.split('/').last}');
        await ref.putFile(photo);
        return await ref.getDownloadURL();
      }));
    } catch (e) {
      _showSnackBar('Failed to upload photos: $e', Colors.red);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(colors),
            _buildMainContent(colors),
          ],
        ),
      ),
    );
  }

  /// Builds the status bar with back button and title.
  Widget _buildStatusBar(AppColorTheme colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: _spacingMedium - 4),
    decoration: _cardDecoration(colors),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          'Report Incident',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
        ),
      ],
    ),
  );

  /// Builds the scrollable main content area.
  Widget _buildMainContent(AppColorTheme colors) => Expanded(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(_padding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncidentTypeSection(colors),
            const SizedBox(height: _spacingLarge),
            _buildSeveritySection(colors),
            const SizedBox(height: _spacingLarge),
            _buildLocationSection(colors),
            const SizedBox(height: _spacingLarge),
            _buildDescriptionSection(colors),
            const SizedBox(height: _spacingLarge),
            _buildPhotoSection(colors),
            const SizedBox(height: _spacingLarge),
            _buildSubmitButton(colors),
          ],
        ),
      ),
    ),
  );

  /// Builds the incident type selection section.
  Widget _buildIncidentTypeSection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel('Incident Type', colors, isRequired: true),
      const SizedBox(height: _spacingSmall),
      _buildIncidentTypeDropdown(colors),
      if (_selectedIncidentType == 'Other') ...[
        const SizedBox(height: _spacingMedium),
        _buildLabel('Specify Incident Type', colors, isRequired: true),
        const SizedBox(height: _spacingSmall),
        _buildOtherIncidentField(colors),
      ],
    ],
  );

  /// Builds the severity selection section.
  Widget _buildSeveritySection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel('Severity Level', colors, isRequired: true),
      const SizedBox(height: _spacingSmall),
      _buildSeverityButtons(colors),
    ],
  );

  /// Builds the location selection section with map preview.
  Widget _buildLocationSection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel('Location', colors, isRequired: true),
      const SizedBox(height: _spacingSmall),
      _buildLocationSelector(colors),
    ],
  );

  /// Builds the description input section.
  Widget _buildDescriptionSection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel('Description', colors),
      const SizedBox(height: _spacingSmall),
      _buildDescriptionField(colors),
    ],
  );

  /// Builds the photo upload section.
  Widget _buildPhotoSection(AppColorTheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel('Add Photos', colors),
      const SizedBox(height: _spacingSmall),
      _buildPhotoUploader(colors),
    ],
  );

  /// Builds a label with an optional required indicator.
  Widget _buildLabel(String text, AppColorTheme colors, {bool isRequired = false}) => Row(
    children: [
      Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.primary300)),
      if (isRequired)
        Text(' *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.warning)),
    ],
  );

  /// Builds the incident type dropdown.
  Widget _buildIncidentTypeDropdown(AppColorTheme colors) => Container(
    decoration: _fieldDecoration(colors),
    child: DropdownButtonFormField<String>(
      value: _selectedIncidentType,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: 12),
        border: InputBorder.none,
      ),
      dropdownColor: colors.bg100,
      style: TextStyle(color: colors.text200, fontSize: 16),
      hint: Text('Select incident type', style: TextStyle(color: colors.text200)),
      items: _incidentTypes
          .map((value) => DropdownMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(_getDisasterIcon(value), color: colors.accent200, size: 20),
            const SizedBox(width: 8),
            Text(value),
          ],
        ),
      ))
          .toList(),
      onChanged: (value) => setState(() => _selectedIncidentType = value),
    ),
  );

  /// Builds the field for specifying other incident type.
  Widget _buildOtherIncidentField(AppColorTheme colors) => Container(
    decoration: _fieldDecoration(colors),
    child: TextField(
      onChanged: (value) => _otherIncidentType = value,
      style: TextStyle(color: colors.text200),
      decoration: InputDecoration(
        hintText: 'Please specify the incident type',
        hintStyle: TextStyle(color: colors.text200.withOpacity(0.7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: 12),
        border: InputBorder.none,
      ),
    ),
  );

  /// Builds the severity selection buttons.
  Widget _buildSeverityButtons(AppColorTheme colors) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: _severities.map((severity) {
      final isSelected = _selectedSeverity == severity;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            onPressed: () => setState(() => _selectedSeverity = severity),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? colors.accent200 : colors.bg100.withOpacity(0.7),
              foregroundColor: isSelected ? colors.bg100 : colors.text200,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.bg300.withOpacity(0.2)),
              ),
            ),
            child: Text(severity),
          ),
        ),
      );
    }).toList(),
  );

  /// Builds the location selector with map preview.
  Widget _buildLocationSelector(AppColorTheme colors) => Column(
    children: [
      Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedLocation == null ? colors.warning : colors.bg300.withOpacity(0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (_isLoadingLocation)
                Center(child: CircularProgressIndicator(color: colors.accent200))
              else
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _selectedMapLocation ?? _currentLocation ?? _defaultLocation,
                    zoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.mydpar.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentLocation != null && _selectedMapLocation == null)
                          Marker(
                            point: _currentLocation!,
                            builder: (_) => Icon(Icons.my_location, color: Colors.blue, size: 30),
                          ),
                        if (_selectedMapLocation != null)
                          Marker(
                            point: _selectedMapLocation!,
                            builder: (_) => Icon(Icons.location_pin, color: colors.warning, size: 40),
                          ),
                        if (_currentLocation == null && _selectedMapLocation == null)
                          Marker(
                            point: _defaultLocation,
                            builder: (_) => Icon(Icons.location_pin, color: Colors.grey, size: 30),
                          ),
                      ],
                    ),
                  ],
                ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: () => _selectLocation(context)),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_selectedLocation != null) ...[
        const SizedBox(height: _spacingSmall),
        Container(
          decoration: _fieldDecoration(colors),
          child: TextField(
            enabled: false,
            controller: TextEditingController(text: _selectedLocation),
            style: TextStyle(color: colors.text200),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ],
  );

  /// Builds the description text field.
  Widget _buildDescriptionField(AppColorTheme colors) => Container(
    decoration: _fieldDecoration(colors),
    child: TextField(
      controller: _descriptionController,
      style: TextStyle(color: colors.text200),
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Describe the incident...',
        hintStyle: TextStyle(color: colors.text200.withOpacity(0.7)),
        contentPadding: const EdgeInsets.all(_spacingMedium),
        border: InputBorder.none,
      ),
    ),
  );

  /// Builds the photo uploader section.
  Widget _buildPhotoUploader(AppColorTheme colors) => Column(
    children: [
      Container(
        decoration: _fieldDecoration(colors),
        child: MaterialButton(
          onPressed: _pickPhotos,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _spacingLarge),
            child: Column(
              children: [
                Icon(Icons.upload_outlined, color: colors.accent200, size: 32),
                const SizedBox(height: _spacingSmall),
                Text(
                  _selectedPhotos.isEmpty
                      ? 'Tap to upload photo'
                      : 'Tap to add more photos (${_selectedPhotos.length} selected)',
                  style: TextStyle(color: colors.text200),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_selectedPhotos.isNotEmpty) ...[
        const SizedBox(height: _spacingMedium),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedPhotos.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: _spacingSmall),
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: FileImage(_selectedPhotos[index]), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPhotos.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: colors.bg100, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 16, color: colors.warning),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );

  /// Builds the submit button.
  Widget _buildSubmitButton(AppColorTheme colors) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isLoading ? null : () => _submitReport(colors),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent200,
        foregroundColor: colors.bg100,
        padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.bg100),
        ),
      )
          : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );

  /// Selects a location via the SelectLocationScreen.
  Future<void> _selectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SelectLocationScreen(initialLocation: _selectedMapLocation)),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedMapLocation = LatLng(result['latitude'] as double, result['longitude'] as double);
        _selectedLocation = result['locationName'] as String? ?? 'Location selected';
        _mapController.move(_selectedMapLocation!, 15);
      });
    }
  }

  /// Picks photos from gallery or camera.
  Future<void> _pickPhotos() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      );

      if (source == null) return;

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() => _selectedPhotos.add(File(pickedFile.path)));
      }
    } catch (e) {
      _showSnackBar('Failed to pick photo: $e', Colors.red);
    }
  }

  /// Validates the form data.
  bool _isFormValid() {
    return _selectedIncidentType != null &&
        (_selectedIncidentType != 'Other' || (_otherIncidentType?.isNotEmpty ?? false)) &&
        _selectedSeverity != null &&
        _selectedLocation != null;
  }

  /// Resets the form to its initial state.
  void _resetForm() {
    setState(() {
      _selectedIncidentType = null;
      _otherIncidentType = null;
      _selectedSeverity = null;
      _selectedLocation = null;
      _selectedMapLocation = null;
      _descriptionController.clear();
      _selectedPhotos.clear();
    });
  }

  /// Shows validation errors if the form is incomplete.
  void _showValidationErrors(AppColorTheme colors) {
    final missingFields = <String>[];
    if (_selectedIncidentType == null) missingFields.add('Incident Type');
    if (_selectedIncidentType == 'Other' && (_otherIncidentType?.isEmpty ?? true)) {
      missingFields.add('Other Incident Type specification');
    }
    if (_selectedSeverity == null) missingFields.add('Severity Level');
    if (_selectedLocation == null) missingFields.add('Location');

    if (missingFields.isNotEmpty) {
      _showSnackBar('Please fill in: ${missingFields.join(", ")}', colors.warning);
    }
  }

  /// Displays a snackbar with a message.
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 3)),
    );
  }

  /// Reusable field decoration.
  BoxDecoration _fieldDecoration(AppColorTheme colors) => BoxDecoration(
    color: colors.bg100.withOpacity(0.7),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colors.bg300.withOpacity(0.2)),
  );

  /// Reusable card decoration.
  BoxDecoration _cardDecoration(AppColorTheme colors) => BoxDecoration(
    color: colors.bg100.withOpacity(0.7),
    border: Border.all(color: colors.bg300.withOpacity(0.2)),
  );

  /// Returns an icon based on the disaster type.
  IconData _getDisasterIcon(String type) {
    const flood = IconData(0xf07a3, fontFamily: 'MaterialIcons');
    const tsunami = IconData(0xf07cf, fontFamily: 'MaterialIcons');

    switch (type.toLowerCase()) {
      case 'heavy rain':
        return Icons.thunderstorm_outlined;
      case 'flood':
        return flood;
      case 'fire':
        return Icons.local_fire_department;
      case 'landslide':
        return Icons.landslide;
      case 'haze':
        return Icons.air;
      case 'other':
        return Icons.warning_amber_rounded;
      default:
        return Icons.error_outline;
    }
  }
}