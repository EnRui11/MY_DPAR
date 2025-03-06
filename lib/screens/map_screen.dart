import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mydpar/screens/home_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _locationTimer; // Add this line
  LatLng? _currentLocation;
  Set<String> _activeFilters = {};
  bool _isSearching = false;
  List<Location>? _searchResults;

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
    _locationTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  // Add this variable with other class variables
  double _currentHeading = 0.0;

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _currentHeading = position.heading;
      });
    } catch (e) {
      // Handle location error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get current location'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  // Add this variable with the other class variables
  LatLng? _searchedLocation;

  // Update the _searchLocation method
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
          content: Text('Location not found'),
          backgroundColor: AppColors.warning,
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

  Widget _buildFilterButton(IconData icon, String label) {
    final bool isActive = _activeFilters.contains(label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleFilter(label),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accent200.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color:
                        isActive ? AppColors.accent200 : AppColors.primary300),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isActive ? AppColors.accent200 : AppColors.primary300,
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg100,
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
            color: AppColors.primary300,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location',
                hintStyle: TextStyle(
                  color: AppColors.primary300.withOpacity(0.5),
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
                          color: AppColors.accent200,
                        ),
                      )
                    : null,
              ),
              style: TextStyle(
                color: AppColors.primary300,
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

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accent200.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? AppColors.accent200 : AppColors.text200,
        onPressed: onPressed,
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg100.withOpacity(0.7),
          border: Border(
            top: BorderSide(color: AppColors.bg100.withOpacity(0.2)),
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
                }),
                _buildNavItem(Icons.map_outlined, true, () {}),
                _buildNavItem(Icons.message_outlined, false, () {}),
                _buildNavItem(Icons.person_outline, false, () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation ?? LatLng(3.1390, 101.6869),
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
          _buildSearchBar(),

          // Filter Controls
          Positioned(
            top: 120,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg100,
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
                        Icons.warning_amber_rounded, 'Incidents'),
                    _buildFilterButton(Icons.home_outlined, 'Shelters'),
                    _buildFilterButton(
                        Icons.local_hospital_outlined, 'Medical'),
                    _buildFilterButton(Icons.inventory_2_outlined, 'Supplies'),
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
                color: AppColors.bg100.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location),
                color: AppColors.accent200,
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
                  color: AppColors.bg100.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bg100.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(4),
                child: MaterialButton(
                  onPressed: () {
                    // TODO: Implement report incident
                  },
                  color: AppColors.warning,
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
                            color: AppColors.bg100, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Report Incident',
                          style: TextStyle(
                            color: AppColors.bg100,
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
          _buildBottomNavigation(context),
        ],
      ),
    );
  }
}
