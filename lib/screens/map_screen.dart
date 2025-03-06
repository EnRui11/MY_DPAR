import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:mydpar/screens/profile_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((_) {
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 15);
      }
    });
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _currentHeading = position.heading;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to get current location'),
          backgroundColor: Provider.of<ThemeProvider>(context, listen: false)
              .currentTheme
              .warning,
        ),
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      setState(() {
        _searchResults = locations;
        _isSearching = false;
        if (locations.isNotEmpty) {
          _searchedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        }
      });

      if (locations.isNotEmpty) {
        _mapController.move(_searchedLocation!, 15);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location not found'),
          backgroundColor: Provider.of<ThemeProvider>(context, listen: false)
              .currentTheme
              .warning,
        ),
      );
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
  }

  Widget _buildFilterButton(IconData icon, String label, dynamic colors) {
    final bool isActive = _activeFilters.contains(label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleFilter(label),
          borderRadius: BorderRadius.circular(24),
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
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? colors.accent200 : colors.primary300,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? colors.accent200 : colors.primary300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 48, left: 24, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colors.primary300,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location',
                hintStyle: TextStyle(
                  color: colors.primary300.withOpacity(0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
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
              style: TextStyle(
                color: colors.primary300,
                fontSize: 16,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchLocation(value);
                }
              },
            ),
          ),
        ],
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
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, dynamic colors) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border: Border(
            top: BorderSide(color: colors.bg100.withOpacity(0.2)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }, colors),
                _buildNavItem(Icons.map_outlined, true, () {}, colors),
                _buildNavItem(Icons.message_outlined, false, () {}, colors),
                _buildNavItem(Icons.person_outline, false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                }, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation ?? const LatLng(3.1390, 101.6869),
              zoom: 15,
            ),
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
                      builder: (ctx) => const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Search Bar
          _buildSearchBar(colors),

          // Filter Controls
          Positioned(
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
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
          ),

          // Location Control
          Positioned(
            bottom: 90,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.bg100.withOpacity(0.2)),
              ),
              child: IconButton(
                icon: Icon(Icons.my_location, color: colors.accent200),
                onPressed: () async {
                  if (_currentLocation != null) {
                    _mapController.rotate(-_currentHeading);
                    _mapController.move(_currentLocation!, 15);
                  }
                },
              ),
            ),
          ),

          // Report Button
          Positioned(
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
                child: MaterialButton(
                  onPressed: () {
                    // TODO: Implement report incident
                  },
                  color: colors.warning,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: colors.bg100, size: 20),
                        const SizedBox(width: 8),
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
          ),

          // Bottom Navigation
          _buildBottomNavigation(context, colors),
        ],
      ),
    );
  }
}
