import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class SelectLocationScreen extends StatefulWidget {
  final LatLng? initialLocation; // Optional initial location from ReportIncidentScreen

  const SelectLocationScreen({super.key, this.initialLocation});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  late final MapController _mapController;
  late final TextEditingController _searchController;

  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  String? _selectedLocationName;
  bool _isSearching = false;

  // Constants for consistency and easy tweaking
  static const LatLng _defaultLocation = LatLng(3.1390, 101.6869); // Kuala Lumpur
  static const double _defaultZoom = 15.0;
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 4.0;
  static const double _spacingMedium = 8.0;
  static const double _spacingLarge = 16.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();

    // Set initial selected location if provided
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _fetchLocationName(_selectedLocation!);
    }

    _initializeCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Initializes the map with the current or default location
  Future<void> _initializeCurrentLocation() async {
    await _fetchCurrentLocation();

    final LatLng initialCenter = widget.initialLocation ?? _currentLocation ?? _defaultLocation;
    _mapController.move(initialCenter, _defaultZoom);
  }

  /// Fetches the user's current location
  Future<void> _fetchCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled', Colors.red);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied', Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission permanently denied', Colors.red);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
    } catch (e) {
      _showSnackBar('Failed to fetch current location: $e', Colors.red);
    }
  }

  /// Fetches the human-readable name for a given location
  Future<void> _fetchLocationName(LatLng location) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        setState(() {
          _selectedLocationName =
              '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}'.trim();
          if (_selectedLocationName!.isEmpty) _selectedLocationName = 'Unnamed Location';
        });
      }
    } catch (e) {
      setState(() => _selectedLocationName = 'Unknown Location');
      _showSnackBar('Failed to fetch location name: $e', Colors.red);
    }
  }

  /// Searches for a location based on user input
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final LatLng location = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() => _selectedLocation = location);
        _mapController.move(location, _defaultZoom);
        await _fetchLocationName(location);
      } else {
        _showSnackBar('No locations found', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to search location: $e', Colors.red);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme; // Updated type

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(colors),
          _buildTopBar(colors),
          _buildCurrentLocationButton(colors),
          _buildBottomControls(colors),
        ],
      ),
    );
  }

  /// Builds the map with markers for current and selected locations
  Widget _buildMap(AppColorTheme colors) => FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      center: widget.initialLocation ?? _currentLocation ?? _defaultLocation,
      zoom: _defaultZoom,
      onTap: (TapPosition tapPosition, LatLng point) async {
        setState(() => _selectedLocation = point);
        await _fetchLocationName(point);
      },
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: const ['a', 'b', 'c'],
        userAgentPackageName: 'com.mydpar.app',
      ),
      MarkerLayer(
        markers: [
          if (_selectedLocation != null)
            Marker(
              point: _selectedLocation!,
              builder: (_) => Icon(
                Icons.location_pin,
                color: colors.warning,
                size: 40,
              ),
            ),
          if (_currentLocation != null && _selectedLocation != _currentLocation)
            Marker(
              point: _currentLocation!,
              builder: (_) => const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            ),
        ],
      ),
    ],
  );

  /// Builds the top bar with back button and search field
  Widget _buildTopBar(AppColorTheme colors) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Container(
      color: colors.bg100.withOpacity(0.9),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(_paddingValue),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colors.primary300),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(child: _buildSearchField(colors)),
            ],
          ),
        ),
      ),
    ),
  );

  /// Builds the search field
  Widget _buildSearchField(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.bg200,
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: _searchController,
      style: TextStyle(color: colors.text200),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: 'Search location',
        hintStyle: TextStyle(color: colors.text200.withOpacity(0.7), fontSize: 16),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: _paddingValue),
          child: Icon(Icons.search, color: colors.primary300),
        ),
        suffixIcon: _isSearching
            ? Padding(
          padding: const EdgeInsets.all(_spacingLarge - 4),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.accent200,
          ),
        )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: _spacingLarge * 3, vertical: _spacingMedium + 4),
      ),
      onSubmitted: _searchLocation,
    ),
  );

  /// Builds the current location button
  Widget _buildCurrentLocationButton(AppColorTheme colors) => Positioned(
    right: _spacingLarge,
    bottom: 220,
    child: FloatingActionButton(
      onPressed: () async {
        await _fetchCurrentLocation();
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, _defaultZoom);
        }
      },
      backgroundColor: colors.bg100,
      child: Icon(Icons.my_location, color: colors.accent200),
    ),
  );

  /// Builds the bottom controls with location info and confirm button
  Widget _buildBottomControls(AppColorTheme colors) => Positioned(
    bottom: _spacingLarge,
    left: _spacingLarge,
    right: _spacingLarge,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedLocation != null) _buildSelectedLocationInfo(colors),
        const SizedBox(height: _spacingLarge),
        _buildConfirmButton(colors),
      ],
    ),
  );

  /// Builds the selected location info card
  Widget _buildSelectedLocationInfo(AppColorTheme colors) => Container(
    padding: const EdgeInsets.all(_paddingValue),
    decoration: BoxDecoration(
      color: colors.bg100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Location:',
          style: TextStyle(color: colors.text200.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: _spacingSmall),
        Text(
          _selectedLocationName ?? 'Loading location name...',
          style: TextStyle(color: colors.text200, fontSize: 16),
        ),
      ],
    ),
  );

  /// Builds the confirm button
  Widget _buildConfirmButton(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [colors.accent200, colors.accent200.withOpacity(0.8)],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ElevatedButton(
      onPressed: _selectedLocation != null ? _confirmLocation : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.bg100,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: _spacingLarge),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: colors.bg100),
          const SizedBox(width: _spacingMedium),
          const Text(
            'Confirm Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );

  /// Confirms the selected location and returns it to the parent screen
  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'locationName': _selectedLocationName ?? 'Selected Location',
      });
    }
  }

  /// Displays a snackbar with a message
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}