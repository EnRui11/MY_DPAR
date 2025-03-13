import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:mydpar/screens/profile_screen.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/report_incident_screen.dart';
import 'package:mydpar/screens/community_screen.dart';

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

  static const _defaultLocation = LatLng(3.1390, 101.6869); // Kuala Lumpur

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

  Future<void> _initializeLocation() async {
    await _updateLocation();
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _currentHeading = position.heading;
      });
    } catch (e) {
      _showSnackBar('Unable to get current location', Colors.red);
    }
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      setState(() {
        _searchResults = locations;
        _isSearching = false;
        if (locations.isNotEmpty) {
          _searchedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
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

  void _toggleFilter(String filter) {
    setState(() => _activeFilters.contains(filter)
        ? _activeFilters.remove(filter)
        : _activeFilters.add(filter));
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;

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

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options:
          MapOptions(center: _currentLocation ?? _defaultLocation, zoom: 15),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
  }

  Widget _buildSearchBar(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg100,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      margin: const EdgeInsets.only(top: 48, left: 24, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.search, color: colors.primary300, size: 24),
          const SizedBox(width: 12),
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
                            strokeWidth: 2, color: colors.accent200))
                    : null,
              ),
              style: TextStyle(color: colors.primary300),
              onSubmitted: (value) =>
                  value.isNotEmpty ? _searchLocation(value) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(dynamic colors) {
    return Positioned(
      top: 120,
      left: 24,
      right: 24,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton(
                  Icons.warning_amber_rounded, 'Incidents', colors),
              _buildFilterButton(Icons.home_outlined, 'Shelters', colors),
              _buildFilterButton(
                  Icons.local_hospital_outlined, 'Medical', colors),
              _buildFilterButton(
                  Icons.inventory_2_outlined, 'Supplies', colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(IconData icon, String label, dynamic colors) {
    final isActive = _activeFilters.contains(label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _toggleFilter(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? colors.accent200.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isActive ? colors.accent200 : colors.primary300),
              const SizedBox(width: 8),
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

  Widget _buildLocationControl(dynamic colors) {
    return Positioned(
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
  }

  Widget _buildReportButton(BuildContext context, dynamic colors) {
    return Positioned(
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined,
                      color: colors.bg100, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Report Incident',
                    style: TextStyle(
                        color: colors.bg100, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, dynamic colors) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border: Border(top: BorderSide(color: colors.bg100.withOpacity(0.2))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, false,
                    () => _navigateTo(context, const HomeScreen()), colors),
                _buildNavItem(Icons.map_outlined, true, () {}, colors),
                _buildNavItem(
                    Icons.people_outline,
                    false,
                    () => _navigateTo(context, const CommunityScreen()),
                    colors),
                _buildNavItem(Icons.person_outline, false,
                    () => _navigateTo(context, const ProfileScreen()), colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, bool isActive, VoidCallback onPressed, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color:
            isActive ? colors.accent200.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? colors.accent200 : colors.text200,
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
