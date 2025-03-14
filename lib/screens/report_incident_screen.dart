import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mydpar/screens/select_location_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

// Model for incident report data, Firebase-ready
class IncidentReport {
  final String incidentType;
  final String? otherIncidentType;
  final String severity;
  final String location;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> photoPaths;
  final String timestamp;

  const IncidentReport({
    required this.incidentType,
    this.otherIncidentType,
    required this.severity,
    required this.location,
    this.latitude,
    this.longitude,
    required this.description,
    required this.photoPaths,
    required this.timestamp,
  });

  // Convert to JSON for Firebase writes
  Map<String, dynamic> toJson() => {
        'incidentType': incidentType,
        'otherIncidentType': otherIncidentType,
        'severity': severity,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'photoPaths': photoPaths,
        'timestamp': timestamp,
      };
}

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final MapController _mapController;
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedPhotos = [];

  String? _selectedIncidentType;
  String? _otherIncidentType;
  String? _selectedSeverity;
  String? _selectedLocation;
  LatLng? _currentLocation;
  LatLng? _selectedMapLocation;
  bool _isLoadingLocation = false;

  // Constants for consistency and easy tweaking
  static const List<String> _incidentTypes = [
    'Flood',
    'Fire',
    'Earthquake',
    'Landslide',
    'Tsunami',
    'Haze',
    'Typhoon',
    'Other',
  ];
  static const List<String> _severities = ['Low', 'Medium', 'High'];
  static const LatLng _defaultLocation =
      LatLng(3.1390, 101.6869); // Kuala Lumpur
  static const double _paddingValue = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Fetches the user's current location
  Future _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled', Colors.red);
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied', Colors.red);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission permanently denied', Colors.red);
        setState(() => _isLoadingLocation = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;

        // Ensure _currentLocation and _mapController are not null
        if (_currentLocation != null && _mapController != null) {
          _mapController.move(_currentLocation!, 15);
        } else {
          _showSnackBar(
              'Map controller or location not initialized', Colors.red);
        }
      });
    } catch (e) {
      //_showSnackBar('Failed to get current location: $e', Colors.red);
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Validates the form data
  bool _isFormValid() {
    return _selectedIncidentType != null &&
        (_selectedIncidentType != 'Other' ||
            (_otherIncidentType?.isNotEmpty ?? false)) &&
        _selectedSeverity != null &&
        _selectedLocation != null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme; // Updated type

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

  /// Builds the status bar with back button and title
  Widget _buildStatusBar(AppColorTheme colors) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _spacingMedium, vertical: _spacingMedium - 4),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border:
              Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.primary300),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              'Report Incident',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
          ],
        ),
      );

  /// Builds the scrollable main content area
  Widget _buildMainContent(AppColorTheme colors) => Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_paddingValue),
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

  /// Builds the incident type selection section
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

  /// Builds the severity selection section
  Widget _buildSeveritySection(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Severity Level', colors, isRequired: true),
          const SizedBox(height: _spacingSmall),
          _buildSeverityButtons(colors),
        ],
      );

  /// Builds the location selection section
  Widget _buildLocationSection(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Location', colors, isRequired: true),
          const SizedBox(height: _spacingSmall),
          _buildLocationSelector(colors),
        ],
      );

  /// Builds the description input section
  Widget _buildDescriptionSection(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Description', colors),
          const SizedBox(height: _spacingSmall),
          _buildDescriptionField(colors),
        ],
      );

  /// Builds the photo upload section
  Widget _buildPhotoSection(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Add Photos', colors),
          const SizedBox(height: _spacingSmall),
          _buildPhotoUploader(colors),
        ],
      );

  /// Builds a label with optional required indicator
  Widget _buildLabel(String text, AppColorTheme colors,
          {bool isRequired = false}) =>
      Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.primary300,
            ),
          ),
          if (isRequired)
            Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.warning,
              ),
            ),
        ],
      );

  /// Builds the incident type dropdown
  Widget _buildIncidentTypeDropdown(AppColorTheme colors) => Container(
        decoration: _fieldDecoration(colors),
        child: DropdownButtonFormField<String>(
          value: _selectedIncidentType,
          decoration: const InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: 12),
            border: InputBorder.none,
          ),
          dropdownColor: colors.bg100,
          style: TextStyle(color: colors.text200, fontSize: 16),
          hint: Text('Select incident type',
              style: TextStyle(color: colors.text200)),
          items: _incidentTypes
              .map((value) => DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(_getDisasterIcon(value),
                            color: colors.accent200, size: 20),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (String? newValue) =>
              setState(() => _selectedIncidentType = newValue),
        ),
      );

  /// Builds the field for specifying other incident type
  Widget _buildOtherIncidentField(AppColorTheme colors) => Container(
        decoration: _fieldDecoration(colors),
        child: TextField(
          onChanged: (value) => _otherIncidentType = value,
          style: TextStyle(color: colors.text200),
          decoration: InputDecoration(
            hintText: 'Please specify the incident type',
            hintStyle: TextStyle(color: colors.text200.withOpacity(0.7)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: _spacingMedium, vertical: 12),
            border: InputBorder.none,
          ),
        ),
      );

  /// Builds the severity selection buttons
  Widget _buildSeverityButtons(AppColorTheme colors) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _severities.map((severity) {
          final bool isSelected = _selectedSeverity == severity;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedSeverity = severity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? colors.accent200
                      : colors.bg100.withOpacity(0.7),
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

  /// Builds the location selector with map preview
  Widget _buildLocationSelector(AppColorTheme colors) => Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: colors.bg100.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedLocation == null
                    ? colors.warning
                    : colors.bg300.withOpacity(0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  if (_isLoadingLocation)
                    Center(
                        child:
                            CircularProgressIndicator(color: colors.accent200))
                  else
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _selectedMapLocation ??
                            _currentLocation ??
                            _defaultLocation,
                        zoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.mydpar.app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (_currentLocation != null &&
                                _selectedMapLocation == null)
                              Marker(
                                point: _currentLocation!,
                                builder: (_) => Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                            if (_selectedMapLocation != null)
                              Marker(
                                point: _selectedMapLocation!,
                                builder: (_) => Icon(
                                  Icons.location_pin,
                                  color: colors.warning,
                                  size: 40,
                                ),
                              ),
                            if (_currentLocation == null &&
                                _selectedMapLocation == null)
                              Marker(
                                point: _defaultLocation,
                                builder: (_) => Icon(
                                  Icons.location_pin,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleLocationSelection(context),
                      ),
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
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: _spacingMedium, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ],
      );

  /// Builds the description text field
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

  /// Handles photo picking from gallery or camera
  Future<void> _pickPhotos() async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Column(
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

      if (source != null) {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 85, // Reduce file size
          maxWidth: 1024, // Limit resolution
          maxHeight: 1024,
        );

        if (pickedFile != null) {
          setState(() {
            _selectedPhotos.add(File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to pick photo: $e', Colors.red);
    }
  }

  /// Builds the photo uploader section
  Widget _buildPhotoUploader(AppColorTheme colors) => Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.bg100.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: colors.bg300.withOpacity(0.2), width: 2),
            ),
            child: MaterialButton(
              onPressed: _pickPhotos,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: _spacingLarge),
                child: Column(
                  children: [
                    Icon(Icons.upload_outlined,
                        color: colors.accent200, size: 32),
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
                          image: DecorationImage(
                            image: FileImage(_selectedPhotos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPhotos.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colors.bg100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: colors.warning,
                            ),
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

  /// Builds the submit button
  Widget _buildSubmitButton(AppColorTheme colors) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleSubmit(colors),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent200,
            foregroundColor: colors.bg100,
            padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Submit Report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );

  /// Reusable field decoration
  BoxDecoration _fieldDecoration(AppColorTheme colors) => BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      );

  /// Helper method to get icon based on disaster type
  IconData _getDisasterIcon(String type) {
    const IconData flood = IconData(0xf07a3, fontFamily: 'MaterialIcons');
    const IconData tsunami = IconData(0xf07cf, fontFamily: 'MaterialIcons');

    switch (type.toLowerCase()) {
      case 'flood':
        return flood; // Water waves icon
      case 'fire':
        return Icons.local_fire_department; // Fire icon
      case 'earthquake':
        return Icons.terrain; // Terrain/ground icon
      case 'landslide':
        return Icons.landslide; // Mountain/falling rocks icon
      case 'tsunami':
        return tsunami; // Large wave icon
      case 'haze':
        return Icons.air; // Air/smoke icon
      case 'typhoon':
        return Icons.cyclone; // Cyclone/rotating icon
      case 'other':
        return Icons.warning_amber_rounded; // Generic warning icon
      default:
        return Icons.error_outline; // Fallback icon
    }
  }

  /// Handles location selection via SelectLocationScreen
  Future<void> _handleLocationSelection(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocationScreen(
          initialLocation: _selectedMapLocation,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedMapLocation =
            LatLng(result['latitude'] as double, result['longitude'] as double);
        _selectedLocation =
            result['locationName'] as String? ?? 'Location selected';
        _mapController.move(_selectedMapLocation!, 15);
      });
    }
  }

  /// Handles form submission
  void _handleSubmit(AppColorTheme colors) {
    if (_isFormValid()) {
      final IncidentReport report = IncidentReport(
        incidentType: _selectedIncidentType!,
        otherIncidentType: _otherIncidentType,
        severity: _selectedSeverity!,
        location: _selectedLocation!,
        latitude: _selectedMapLocation?.latitude,
        longitude: _selectedMapLocation?.longitude,
        description: _descriptionController.text,
        photoPaths: _selectedPhotos.map((photo) => photo.path).toList(),
        timestamp: DateTime.now().toIso8601String(),
      );

      // TODO: Implement Firebase submission here (see Firebase Integration Steps)
      debugPrint('Submitting report: ${report.toJson()}');

      _showSnackBar('Report submitted successfully!', colors.accent200);

      // Reset form
      setState(() {
        _selectedIncidentType = null;
        _otherIncidentType = null;
        _selectedSeverity = null;
        _selectedLocation = null;
        _selectedMapLocation = null;
        _descriptionController.clear();
        _selectedPhotos.clear();
      });
    } else {
      _showValidationErrors(colors);
    }
  }

  /// Shows validation errors if form is incomplete
  void _showValidationErrors(AppColorTheme colors) {
    final List<String> missingFields = [];
    if (_selectedIncidentType == null) missingFields.add('Incident Type');
    if (_selectedIncidentType == 'Other' &&
        (_otherIncidentType?.isEmpty ?? true)) {
      missingFields.add('Other Incident Type specification');
    }
    if (_selectedSeverity == null) missingFields.add('Severity Level');
    if (_selectedLocation == null) missingFields.add('Location');

    if (missingFields.isNotEmpty) {
      _showSnackBar(
        'Please fill in the required fields: ${missingFields.join(", ")}',
        colors.warning,
      );
    }
  }

  /// Displays a snackbar with a message
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
