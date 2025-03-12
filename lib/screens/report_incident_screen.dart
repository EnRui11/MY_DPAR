import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/select_location_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final MapController _mapController; // Add MapController

  String? _selectedIncidentType;
  String? _otherIncidentType;
  String? _selectedSeverity;
  String? _selectedLocation;
  LatLng? _currentLocation;
  LatLng? _selectedMapLocation;
  bool _isLoadingLocation = false;

  static const _incidentTypes = [
    'Flood',
    'Fire',
    'Earthquake',
    'Landslide',
    'Tsunami',
    'Haze',
    'Typhoon',
    'Other',
  ];
  static const _severities = ['Low', 'Medium', 'High'];
  static const _defaultLocation = LatLng(3.1390, 101.6869);
  static const _paddingValue = 24.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 16.0;
  static const _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _mapController = MapController(); // Initialize MapController
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose(); // Dispose MapController
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _mapController.move(_currentLocation ?? _defaultLocation, 15); // Initial center
      });
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  bool _isFormValid() {
    if (_selectedIncidentType == null) return false;
    if (_selectedIncidentType == 'Other' && (_otherIncidentType?.isEmpty ?? true)) return false;
    if (_selectedSeverity == null) return false;
    if (_selectedLocation == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final dynamic colors = themeProvider.currentTheme;

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

  Widget _buildStatusBar(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: colors.primary300,
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Report Incident',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.primary300),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(dynamic colors) {
    return Expanded(
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
  }

  Widget _buildIncidentTypeSection(dynamic colors) {
    return Column(
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
  }

  Widget _buildSeveritySection(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Severity Level', colors, isRequired: true),
        const SizedBox(height: _spacingSmall),
        _buildSeverityButtons(colors),
      ],
    );
  }

  Widget _buildLocationSection(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Location', colors, isRequired: true),
        const SizedBox(height: _spacingSmall),
        _buildLocationSelector(colors),
      ],
    );
  }

  Widget _buildDescriptionSection(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Description', colors),
        const SizedBox(height: _spacingSmall),
        _buildDescriptionField(colors),
      ],
    );
  }

  Widget _buildPhotoSection(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Add Photos', colors),
        const SizedBox(height: _spacingSmall),
        _buildPhotoUploader(colors),
      ],
    );
  }

  Widget _buildLabel(String text, dynamic colors, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.primary300),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.warning),
          ),
      ],
    );
  }

  Widget _buildIncidentTypeDropdown(dynamic colors) {
    return Container(
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
        items: _incidentTypes.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? newValue) => setState(() => _selectedIncidentType = newValue),
      ),
    );
  }

  Widget _buildOtherIncidentField(dynamic colors) {
    return Container(
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
  }

  Widget _buildSeverityButtons(dynamic colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _severities.map((severity) {
        final bool isSelected = _selectedSeverity == severity;
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
  }

  Widget _buildLocationSelector(dynamic colors) {
    return Column(
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
                    mapController: _mapController, // Use MapController
                    options: MapOptions(
                      center: _selectedMapLocation ?? _currentLocation ?? _defaultLocation,
                      zoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.mydpar.app',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_currentLocation != null && _selectedMapLocation == null)
                            Marker(
                              point: _currentLocation!,
                              builder: (ctx) => Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          if (_selectedMapLocation != null)
                            Marker(
                              point: _selectedMapLocation!,
                              builder: (ctx) => Icon(
                                Icons.location_pin,
                                color: colors.warning,
                                size: 40,
                              ),
                            ),
                          if (_currentLocation == null && _selectedMapLocation == null)
                            Marker(
                              point: _defaultLocation,
                              builder: (ctx) => Icon(
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
                contentPadding: EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: 12),
                border: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionField(dynamic colors) {
    return Container(
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
  }

  Widget _buildPhotoUploader(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2), width: 2),
      ),
      child: MaterialButton(
        onPressed: () {
          // TODO: Implement photo upload
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _spacingLarge),
          child: Column(
            children: [
              Icon(Icons.upload_outlined, color: colors.accent200, size: 32),
              const SizedBox(height: _spacingSmall),
              Text('Tap to upload photo', style: TextStyle(color: colors.text200)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(dynamic colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleSubmit(colors),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          foregroundColor: colors.bg100,
          padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Submit Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration(dynamic colors) {
    return BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.bg300.withOpacity(0.2)),
    );
  }

  void _handleLocationSelection(BuildContext context) async {
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
        _selectedMapLocation = LatLng(result['latitude'] as double, result['longitude'] as double);
        _selectedLocation = result['locationName'] as String? ?? 'Location selected';
        _mapController.move(_selectedMapLocation!, 15); // Explicitly move map to selected location
      });
    }
  }

  void _handleSubmit(dynamic colors) {
    if (_isFormValid()) {
      // TODO: Implement report submission
      debugPrint('Form is valid, submitting...');
    } else {
      _showValidationErrors(colors);
    }
  }

  void _showValidationErrors(dynamic colors) {
    final List<String> missingFields = [];
    if (_selectedIncidentType == null) missingFields.add('Incident Type');
    if (_selectedIncidentType == 'Other' && (_otherIncidentType?.isEmpty ?? true)) {
      missingFields.add('Other Incident Type specification');
    }
    if (_selectedSeverity == null) missingFields.add('Severity Level');
    if (_selectedLocation == null) missingFields.add('Location');

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in the required fields: ${missingFields.join(", ")}',
            style: TextStyle(color: colors.bg100),
          ),
          backgroundColor: colors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}