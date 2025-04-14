import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mydpar/screens/report_disaster/select_disaster_location_screen.dart';
import 'package:mydpar/services/disaster_verification_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/alert_notification_service.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

const _padding = 24.0;
const _spacingSmall = 8.0;
const _spacingMedium = 16.0;
const _spacingLarge = 24.0;
const _defaultLocation = LatLng(3.1390, 101.6869);

class DisasterReport {
  final String id;
  final String userId;
  final String disasterType;
  final String? otherDisasterType;
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

  DisasterReport({
    String? id,
    required this.userId,
    required this.disasterType,
    this.otherDisasterType,
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
  }) : id = id ?? _generateId(disasterType);

  static String _generateId(String disasterType) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final randomStr = (Random().nextInt(9000) + 1000).toString();
    final typeStr = _getDisasterTypeShortForm(disasterType);
    return 'DIS_${typeStr}_${dateStr}_${timeStr}_$randomStr';
  }

  static String _getDisasterTypeShortForm(String type) {
    const map = {
      'heavy_rain': 'RAIN',
      'flood': 'FLD',
      'earthquake': 'EQT',
      'fire': 'FIRE',
      'landslide': 'LAND',
      'haze': 'HAZE',
      'other': 'OTH',
    };
    return map[type.toLowerCase()] ?? type.substring(0, 4).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'disasterType': disasterType,
        'otherDisasterType': otherDisasterType,
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

class ReportDisasterScreen extends StatefulWidget {
  const ReportDisasterScreen({super.key});

  @override
  State<ReportDisasterScreen> createState() => _ReportDisasterScreenState();
}

class _ReportDisasterScreenState extends State<ReportDisasterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final MapController _mapController;
  final _picker = ImagePicker();
  final _verificationService = DisasterVerificationService();
  List<File> _selectedPhotos = [];
  String? _selectedDisasterType;
  String? _otherDisasterType;
  String? _selectedSeverity;
  String? _selectedLocation;
  LatLng? _currentLocation;
  LatLng? _selectedMapLocation;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  Timer? _locationRetryTimer; // Timer for retrying location fetch

  static const _disasterTypes = [
    'Heavy Rain',
    'Flood',
    'Earthquake',
    'Fire',
    'Landslide',
    'Haze',
    'Other'
  ];
  static const _severities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _mapController = MapController();
    _initializeServices();
    _updateCurrentLocation(); // Start attempting to get location
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose();
    _locationRetryTimer?.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await DisasterVerificationService.initializeTimeZone();
    await _verificationService.cacheDisasters();
  }

  Future<void> _updateCurrentLocation() async {
    if (_selectedMapLocation != null) {
      // Stop retrying if user has selected a location
      _locationRetryTimer?.cancel();
      return;
    }

    setState(() => _isLoadingLocation = true);
    try {
      if (!await _checkLocationPermission()) {
        _scheduleLocationRetry();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Avoid hanging too long
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 15);
        _isLoadingLocation = false;
        _locationRetryTimer?.cancel(); // Stop retrying on success
      });
    } catch (e) {
      // Failed to get location, schedule a retry
      _scheduleLocationRetry();
    }
  }

  void _scheduleLocationRetry() {
    if (_selectedMapLocation != null || !mounted) {
      setState(() => _isLoadingLocation = false);
      return; // Don't retry if location is selected or widget is disposed
    }

    setState(() => _isLoadingLocation = false);
    _locationRetryTimer?.cancel(); // Cancel any existing timer
    _locationRetryTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _currentLocation == null && _selectedMapLocation == null) {
        _updateCurrentLocation(); // Retry fetching location
      }
    });
  }

  Future<bool> _checkLocationPermission() async {
    final l = AppLocalizations.of(context);
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showSnackBar(l.translate('location_services_disabled'), Colors.red);
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar(l.translate('location_permission_denied'), Colors.red);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          l.translate('location_permission_denied_forever'), Colors.red);
      return false;
    }
    return true;
  }

  Future<void> _submitReport(AppColorTheme colors) async {
    final l = AppLocalizations.of(context);
    if (!_isFormValid()) {
      _showValidationErrors(colors);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final photoUrls = await _uploadPhotos(colors);
      final timestamp = DisasterVerificationService.getCurrentTimestamp();
      final alertService = AlertNotificationService();
      final disasterService =
          Provider.of<DisasterService>(context, listen: false);

      // Convert display disaster type to internal type (with underscore)
      final internalDisasterType =
          _selectedDisasterType!.replaceAll(' ', '_').toLowerCase();

      if (_selectedMapLocation != null) {
        final existingDisaster =
            await _verificationService.checkExistingDisaster(
          disasterType: internalDisasterType,
          latitude: _selectedMapLocation!.latitude,
          longitude: _selectedMapLocation!.longitude,
          timestamp: timestamp,
        );

        if (existingDisaster != null) {
          final disaster =
              await disasterService.getDisasterById(existingDisaster['id']);
          if (disaster != null) {
            final updatedDisaster = disaster.copyWith(
              severity: _selectedSeverity!,
              description: _descriptionController.text,
              photoPaths: [...(disaster.photoPaths ?? []), ...photoUrls],
              userList: [...(disaster.userList ?? []), user.uid],
              verificationCount: disaster.verificationCount + 1,
            );

            await disasterService.updateDisaster(updatedDisaster);
            await alertService.alertNearbyUsers(
              disasterId: existingDisaster['id'],
              disasterType: internalDisasterType,
              latitude: _selectedMapLocation!.latitude,
              longitude: _selectedMapLocation!.longitude,
              severity: _selectedSeverity!,
              location: _selectedLocation!,
              description: _descriptionController.text,
            );

            _showSnackBar(
                l.translate('disaster_updated_success'), colors.accent200);
            _resetForm();
            return;
          }
        }
      }

      // Generate disaster ID before creating
      final disasterId = DisasterReport._generateId(internalDisasterType);

      final newDisasterId = await disasterService.createDisaster(
        id: disasterId,
        userId: user.uid,
        disasterType: internalDisasterType,
        otherDisasterType: _otherDisasterType,
        severity: _selectedSeverity!,
        location: _selectedLocation!,
        coordinates: _selectedMapLocation,
        description: _descriptionController.text,
        photoPaths: photoUrls,
        timestamp: timestamp,
        status: 'pending',
        userList: [user.uid],
        locationList: [],
        verificationCount: 1,
      );

      if (newDisasterId != null && _selectedMapLocation != null) {
        await alertService.alertNearbyUsers(
          disasterId: newDisasterId,
          disasterType: internalDisasterType,
          latitude: _selectedMapLocation!.latitude,
          longitude: _selectedMapLocation!.longitude,
          severity: _selectedSeverity!,
          location: _selectedLocation!,
          description: _descriptionController.text,
        );
      }

      _showSnackBar(l.translate('disaster_reported_success'), colors.accent200);
      _resetForm();
    } catch (e) {
      _showSnackBar(
          l.translate('failed_to_submit_report', {'error': e.toString()}),
          colors.warning);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _uploadPhotos(AppColorTheme colors) async {
    final l = AppLocalizations.of(context);
    try {
      return await Future.wait(_selectedPhotos.map((photo) async {
        final ref = FirebaseStorage.instance.ref().child('disaster_photos').child(
            '${DateTime.now().millisecondsSinceEpoch}_${photo.path.split('/').last}');
        await ref.putFile(photo);
        return await ref.getDownloadURL();
      }));
    } catch (e) {
      _showSnackBar(
          l.translate('failed_to_upload_photos', {'error': e.toString()}),
          Colors.red);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _StatusBar(colors: colors),
            _MainContent(formKey: _formKey, colors: colors),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final AppColorTheme colors;

  const _StatusBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: _spacingMedium, vertical: _spacingMedium - 4),
      decoration: _cardDecoration(colors),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.primary300),
            onPressed: () => Navigator.pop(context),
            tooltip: l.translate('back'),
          ),
          Text(
            l.translate('report_disaster'),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300),
          ),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AppColorTheme colors;

  const _MainContent({required this.formKey, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_padding),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DisasterTypeSection(colors: colors),
              const SizedBox(height: _spacingLarge),
              _SeveritySection(colors: colors),
              const SizedBox(height: _spacingLarge),
              _LocationSection(colors: colors),
              const SizedBox(height: _spacingLarge),
              _DescriptionSection(colors: colors),
              const SizedBox(height: _spacingLarge),
              _PhotoSection(colors: colors),
              const SizedBox(height: _spacingLarge),
              _SubmitButton(colors: colors),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisasterTypeSection extends StatelessWidget {
  final AppColorTheme colors;

  const _DisasterTypeSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(textKey: 'disaster_type', colors: colors, isRequired: true),
        const SizedBox(height: _spacingSmall),
        _DisasterTypeDropdown(colors: colors),
        if (state._selectedDisasterType == 'Other') ...[
          const SizedBox(height: _spacingMedium),
          _Label(
              textKey: 'specify_disaster_type',
              colors: colors,
              isRequired: true),
          const SizedBox(height: _spacingSmall),
          _OtherDisasterField(colors: colors),
        ],
      ],
    );
  }
}

class _DisasterTypeDropdown extends StatelessWidget {
  final AppColorTheme colors;

  const _DisasterTypeDropdown({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _fieldDecoration(colors),
      child: DropdownButtonFormField<String>(
        value: state._selectedDisasterType,
        decoration: const InputDecoration(
          contentPadding:
              EdgeInsets.symmetric(horizontal: _spacingMedium, vertical: 12),
          border: InputBorder.none,
        ),
        dropdownColor: colors.bg100,
        style: TextStyle(color: colors.text200, fontSize: 16),
        hint: Text(l.translate('select_disaster_type'),
            style: TextStyle(color: colors.text200)),
        items: _ReportDisasterScreenState._disasterTypes
            .map((value) => DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                          DisasterService.getDisasterIcon(
                              _getInternalDisasterType(value)),
                          color: colors.accent200,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(l
                          .translate(value.toLowerCase().replaceAll(' ', '_'))),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (value) =>
            state.setState(() => state._selectedDisasterType = value),
      ),
    );
  }

  // Helper method to convert display name to internal type
  String _getInternalDisasterType(String displayType) {
    return displayType.replaceAll(' ', '_');
  }
}

class _OtherDisasterField extends StatelessWidget {
  final AppColorTheme colors;

  const _OtherDisasterField({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _fieldDecoration(colors),
      child: TextField(
        onChanged: (value) => state._otherDisasterType = value,
        style: TextStyle(color: colors.text200),
        decoration: InputDecoration(
          hintText: l.translate('specify_disaster_type_hint'),
          hintStyle: TextStyle(color: colors.text200.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: _spacingMedium, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _SeveritySection extends StatelessWidget {
  final AppColorTheme colors;

  const _SeveritySection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(textKey: 'severity_level', colors: colors, isRequired: true),
        const SizedBox(height: _spacingSmall),
        _SeverityButtons(colors: colors),
      ],
    );
  }
}

class _SeverityButtons extends StatelessWidget {
  final AppColorTheme colors;

  const _SeverityButtons({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _ReportDisasterScreenState._severities.map((severity) {
        final isSelected = state._selectedSeverity == severity;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () =>
                  state.setState(() => state._selectedSeverity = severity),
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
              child: Text(l.translate(severity.toLowerCase())),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final AppColorTheme colors;

  const _LocationSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(textKey: 'location', colors: colors, isRequired: true),
        const SizedBox(height: _spacingSmall),
        _LocationSelector(colors: colors),
      ],
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final AppColorTheme colors;

  const _LocationSelector({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
    context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state._selectedLocation == null
                  ? colors.warning
                  : colors.bg300.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (state._isLoadingLocation)
                  Center(
                      child: CircularProgressIndicator(color: colors.accent200))
                else
                  FlutterMap(
                    mapController: state._mapController,
                    options: MapOptions(
                      center: state._selectedMapLocation ??
                          state._currentLocation ??
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
                          if (state._currentLocation != null)
                            Marker(
                              point: state._currentLocation!,
                              builder: (_) => Icon(Icons.my_location,
                                  color: Colors.blue, size: 30),
                            ),
                          if (state._selectedMapLocation != null)
                            Marker(
                              point: state._selectedMapLocation!,
                              builder: (_) => Icon(Icons.location_pin,
                                  color: colors.warning, size: 40),
                            ),
                        ],
                      ),
                    ],
                  ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: () => state._selectLocation(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state._selectedLocation != null) ...[
          const SizedBox(height: _spacingSmall),
          Container(
            decoration: _fieldDecoration(colors),
            child: TextField(
              enabled: false,
              controller: TextEditingController(text: state._selectedLocation),
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
  }
}

class _DescriptionSection extends StatelessWidget {
  final AppColorTheme colors;

  const _DescriptionSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(textKey: 'description', colors: colors),
        const SizedBox(height: _spacingSmall),
        _DescriptionField(colors: colors),
      ],
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final AppColorTheme colors;

  const _DescriptionField({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    final l = AppLocalizations.of(context);
    return Container(
      decoration: _fieldDecoration(colors),
      child: TextField(
        controller: state._descriptionController,
        style: TextStyle(color: colors.text200),
        maxLines: 4,
        decoration: InputDecoration(
          hintText: l.translate('describe_disaster'),
          hintStyle: TextStyle(color: colors.text200.withOpacity(0.7)),
          contentPadding: const EdgeInsets.all(_spacingMedium),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final AppColorTheme colors;

  const _PhotoSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(textKey: 'add_photos', colors: colors),
        const SizedBox(height: _spacingSmall),
        _PhotoUploader(colors: colors),
      ],
    );
  }
}

class _PhotoUploader extends StatelessWidget {
  final AppColorTheme colors;

  const _PhotoUploader({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          decoration: _fieldDecoration(colors),
          child: MaterialButton(
            onPressed: state._pickPhotos,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: _spacingLarge),
              child: Column(
                children: [
                  Icon(Icons.upload_outlined,
                      color: colors.accent200, size: 32),
                  const SizedBox(height: _spacingSmall),
                  Text(
                    state._selectedPhotos.isEmpty
                        ? l.translate('tap_to_upload_photo')
                        : l.translate('tap_to_add_more_photos',
                            {'count': state._selectedPhotos.length.toString()}),
                    style: TextStyle(color: colors.text200),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state._selectedPhotos.isNotEmpty) ...[
          const SizedBox(height: _spacingMedium),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state._selectedPhotos.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: _spacingSmall),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                            image: FileImage(state._selectedPhotos[index]),
                            fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => state.setState(
                            () => state._selectedPhotos.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: colors.bg100, shape: BoxShape.circle),
                          child: Icon(Icons.close,
                              size: 16, color: colors.warning),
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
  }
}

class _SubmitButton extends StatelessWidget {
  final AppColorTheme colors;

  const _SubmitButton({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ReportDisasterScreenState>()!;
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state._isLoading ? null : () => state._submitReport(colors),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          foregroundColor: colors.bg100,
          padding: const EdgeInsets.symmetric(vertical: _spacingMedium),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: state._isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.bg100),
                ),
              )
            : Text(l.translate('submit_report'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String textKey;
  final AppColorTheme colors;
  final bool isRequired;

  const _Label(
      {required this.textKey, required this.colors, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Text(l.translate(textKey),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.primary300)),
        if (isRequired)
          Text(' *',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.warning)),
      ],
    );
  }
}

extension ReportDisasterScreenStateExtensions on _ReportDisasterScreenState {
  Future<void> _selectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SelectDisasterLocationScreen(
              initialLocation: _selectedMapLocation)),
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

  Future<void> _pickPhotos() async {
    final l = AppLocalizations.of(context);
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.translate('gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l.translate('camera')),
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
      _showSnackBar(
          l.translate('failed_to_pick_photo', {'error': e.toString()}),
          Colors.red);
    }
  }

  bool _isFormValid() {
    return _selectedDisasterType != null &&
        (_selectedDisasterType != 'Other' ||
            (_otherDisasterType?.isNotEmpty ?? false)) &&
        _selectedSeverity != null &&
        _selectedLocation != null;
  }

  void _resetForm() {
    setState(() {
      _selectedDisasterType = null;
      _otherDisasterType = null;
      _selectedSeverity = null;
      _selectedLocation = null;
      _selectedMapLocation = null;
      _descriptionController.clear();
      _selectedPhotos.clear();
    });
  }

  void _showValidationErrors(AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    final missingFields = <String>[];
    if (_selectedDisasterType == null)
      missingFields.add(l.translate('disaster_type'));
    if (_selectedDisasterType == 'Other' &&
        (_otherDisasterType?.isEmpty ?? true)) {
      missingFields.add(l.translate('specify_disaster_type'));
    }
    if (_selectedSeverity == null)
      missingFields.add(l.translate('severity_level'));
    if (_selectedLocation == null) missingFields.add(l.translate('location'));

    if (missingFields.isNotEmpty) {
      _showSnackBar(
          l.translate('please_fill_in', {'fields': missingFields.join(', ')}),
          colors.warning);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3)),
    );
  }
}

BoxDecoration _fieldDecoration(AppColorTheme colors) => BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.bg300.withOpacity(0.2)),
    );

BoxDecoration _cardDecoration(AppColorTheme colors) => BoxDecoration(
      color: colors.bg100.withOpacity(0.7),
      border: Border.all(color: colors.bg300.withOpacity(0.2)),
    );
