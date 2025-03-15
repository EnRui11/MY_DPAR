import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/main/profile_screen.dart';
import 'package:mydpar/screens/main/community_screen.dart';
import 'package:mydpar/screens/report_incident/report_incident_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _locationTimer;
  LatLng? _currentLocation;
  Set<String> _activeFilters = {};
  bool _isSearching = false;
  List<Location>? _searchResults;
  double _currentHeading = 0.0;
  LatLng? _searchedLocation;

  // Constants for consistency and easy tweaking
  static const LatLng _defaultLocation = LatLng(3.1390, 101.6869); // Kuala Lumpur
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _locationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateLocation());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  /// Initializes the user's location on map load
  Future<void> _initializeLocation() async {
    await _updateLocation();
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    }
  }

  /// Updates the user's current location periodically
  Future<void> _updateLocation() async {
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
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _currentHeading = position.heading;
      });
    } catch (e) {
      _showSnackBar('Unable to get current location: $e', Colors.red);
    }
  }

  /// Searches for a location based on user input
  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      final List<Location> locations = await locationFromAddress(query);
      setState(() {
        _searchResults = locations;
        _isSearching = false;
        if (locations.isNotEmpty) {
          _searchedLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _mapController.move(_searchedLocation!, 15);
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      _showSnackBar('Location not found', Colors.red);
    }
  }

  /// Toggles a filter on or off
  void _toggleFilter(String filter) {
    setState(() => _activeFilters.contains(filter)
        ? _activeFilters.remove(filter)
        : _activeFilters.add(filter));
  }

  /// Displays a snackbar with a message
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColorTheme colors = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildSearchBar(colors),
          _buildFilterControls(colors),
          _buildLocationControl(colors),
          _buildReportButton(context, colors),
          _buildBottomNavigation(context, colors),
        ],
      ),
    );
  }

  /// Builds the map with current location marker
  Widget _buildMap() => FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      center: _currentLocation ?? _defaultLocation,
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
          if (_currentLocation != null)
            Marker(
              point: _currentLocation!,
              builder: (_) =>
              const Icon(Icons.my_location, color: Colors.blue, size: 30),
            ),
        ],
      ),
    ],
  );

  /// Builds the search bar at the top
  Widget _buildSearchBar(AppColorTheme colors) => Container(
    decoration: BoxDecoration(
      color: colors.bg100,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    margin: const EdgeInsets.only(top: 48, left: _spacingLarge, right: _spacingLarge),
    padding: const EdgeInsets.symmetric(horizontal: _paddingValue, vertical: _spacingSmall),
    child: Row(
      children: [
        Icon(Icons.search, color: colors.primary300, size: 24),
        const SizedBox(width: _spacingMedium),
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search location',
              hintStyle: TextStyle(color: colors.primary300.withOpacity(0.5)),
              border: InputBorder.none,
              suffixIcon: _isSearching
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accent200,
                ),
              )
                  : null,
            ),
            style: TextStyle(color: colors.primary300),
            onSubmitted: (value) => value.isNotEmpty ? _searchLocation(value) : null,
          ),
        ),
      ],
    ),
  );

  /// Builds the filter controls below the search bar
  Widget _buildFilterControls(AppColorTheme colors) => Positioned(
    top: 120,
    left: _spacingLarge,
    right: _spacingLarge,
    child: Container(
      decoration: BoxDecoration(
        color: colors.bg100,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: _spacingSmall),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton(
              icon: Icons.warning_amber_rounded,
              label: 'Incidents',
              colors: colors,
            ),
            _buildFilterButton(
              icon: Icons.home_outlined,
              label: 'Shelters',
              colors: colors,
            ),
            _buildFilterButton(
              icon: Icons.local_hospital_outlined,
              label: 'Medical',
              colors: colors,
            ),
            _buildFilterButton(
              icon: Icons.inventory_2_outlined,
              label: 'Supplies',
              colors: colors,
            ),
          ],
        ),
      ),
    ),
  );

  /// Builds an individual filter button
  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required AppColorTheme colors,
  }) {
    final bool isActive = _activeFilters.contains(label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _toggleFilter(label),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: _paddingValue, vertical: _spacingSmall),
          decoration: BoxDecoration(
            color: isActive ? colors.accent200.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? colors.accent200 : colors.primary300,
              ),
              const SizedBox(width: _spacingSmall),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? colors.accent200 : colors.primary300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the location control button
  Widget _buildLocationControl(AppColorTheme colors) => Positioned(
    bottom: 90,
    right: 10,
    child: Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg100.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(Icons.my_location, color: colors.accent200),
        onPressed: () {
          if (_currentLocation != null) {
            _mapController.rotate(-_currentHeading);
            _mapController.move(_currentLocation!, 15);
          }
        },
      ),
    ),
  );

  /// Builds the report incident button
  Widget _buildReportButton(BuildContext context, AppColorTheme colors) => Positioned(
    bottom: 85,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _navigateTo(context, const ReportIncidentScreen()),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.warning,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: _paddingValue, vertical: _spacingMedium),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, color: colors.bg100, size: 20),
                const SizedBox(width: _spacingSmall),
                Text(
                  'Report Incident',
                  style: TextStyle(
                    color: colors.bg100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// Builds the bottom navigation bar
  Widget _buildBottomNavigation(BuildContext context, AppColorTheme colors) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      decoration: BoxDecoration(
        color: colors.bg100,
        border: Border(top: BorderSide(color: colors.bg100)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _spacingSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                isActive: false,
                onPressed: () => _navigateTo(context, const HomeScreen()),
                colors: colors,
              ),
              _buildNavItem(
                icon: Icons.map_outlined,
                isActive: true, // Map is active
                onPressed: () {},
                colors: colors,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                isActive: false,
                onPressed: () => _navigateTo(context, const CommunityScreen()),
                colors: colors,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                isActive: false,
                onPressed: () => _navigateTo(context, const ProfileScreen()),
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Reusable navigation item widget
  Widget _buildNavItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required AppColorTheme colors,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: isActive ? colors.accent200.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon),
          color: isActive ? colors.accent200 : colors.text200,
          onPressed: onPressed,
          padding: const EdgeInsets.all(_spacingMedium),
        ),
      );

  /// Navigates to a new screen
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}