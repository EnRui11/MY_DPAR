import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mydpar/screens/report_disaster/report_disaster_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

const double _paddingValue = 16.0;
const double _spacingSmall = 8.0;
const double _spacingMedium = 12.0;
const double _spacingLarge = 24.0;

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

  static const LatLng _defaultLocation =
      LatLng(3.1390, 101.6869); // Kuala Lumpur

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _locationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateLocation());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationService>(context, listen: false).changeIndex(1);
    });
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
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('location_services_disabled', Colors.red);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('location_permission_denied', Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('location_permission_denied_forever', Colors.red);
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
      _showSnackBar('unable_to_get_location', Colors.red,
          params: {'error': e.toString()});
    }
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      final List<Location> locations = await locationFromAddress(query);
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
      _showSnackBar('location_not_found', Colors.red);
    }
  }

  void _toggleFilter(String filter) {
    setState(() => _activeFilters.contains(filter)
        ? _activeFilters.remove(filter)
        : _activeFilters.add(filter));
  }

  void _showSnackBar(String messageKey, Color backgroundColor,
      {Map<String, String>? params}) {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.translate(messageKey, params ?? {})),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      body: Stack(
        children: [
          _Map(colors: colors),
          _SearchBar(colors: colors),
          _FilterControls(colors: colors),
          _LocationControl(colors: colors),
          _ReportButton(colors: colors),
        ],
      ),
    );
  }
}

class _Map extends StatelessWidget {
  final AppColorTheme colors;

  const _Map({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MapScreenState>()!;
    return FlutterMap(
      mapController: state._mapController,
      options: MapOptions(
        center: state._currentLocation ?? _MapScreenState._defaultLocation,
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
            if (state._currentLocation != null)
              Marker(
                point: state._currentLocation!,
                builder: (_) =>
                    const Icon(Icons.my_location, color: Colors.blue, size: 30),
              ),
          ],
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final AppColorTheme colors;

  const _SearchBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.findAncestorStateOfType<_MapScreenState>()!;
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
      margin: const EdgeInsets.only(
          top: 48, left: _spacingLarge, right: _spacingLarge),
      padding: const EdgeInsets.symmetric(
          horizontal: _paddingValue, vertical: _spacingSmall),
      child: Row(
        children: [
          Icon(Icons.search, color: colors.primary300, size: 24),
          const SizedBox(width: _spacingMedium),
          Expanded(
            child: TextField(
              controller: state._searchController,
              decoration: InputDecoration(
                hintText: l.translate('search_location'),
                hintStyle: TextStyle(color: colors.primary300.withOpacity(0.5)),
                border: InputBorder.none,
                suffixIcon: state._isSearching
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
              onSubmitted: (value) =>
                  value.isNotEmpty ? state._searchLocation(value) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterControls extends StatelessWidget {
  final AppColorTheme colors;

  const _FilterControls({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.findAncestorStateOfType<_MapScreenState>()!;
    return Positioned(
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
              _FilterButton(
                icon: Icons.emergency,
                labelKey: 'sos',
                isActive: state._activeFilters.contains('SOS'),
                onTap: () => state._toggleFilter('SOS'),
                colors: colors,
              ),
              _FilterButton(
                icon: Icons.warning_amber_rounded,
                labelKey: 'disasters',
                isActive: state._activeFilters.contains('Disasters'),
                onTap: () => state._toggleFilter('Disasters'),
                colors: colors,
              ),
              _FilterButton(
                icon: Icons.home_outlined,
                labelKey: 'shelters',
                isActive: state._activeFilters.contains('Shelters'),
                onTap: () => state._toggleFilter('Shelters'),
                colors: colors,
              ),
              _FilterButton(
                icon: Icons.local_hospital_outlined,
                labelKey: 'medical',
                isActive: state._activeFilters.contains('Medical'),
                onTap: () => state._toggleFilter('Medical'),
                colors: colors,
              ),
              _FilterButton(
                icon: Icons.inventory_2_outlined,
                labelKey: 'supplies',
                isActive: state._activeFilters.contains('Supplies'),
                onTap: () => state._toggleFilter('Supplies'),
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  final bool isActive;
  final VoidCallback onTap;
  final AppColorTheme colors;

  const _FilterButton({
    required this.icon,
    required this.labelKey,
    required this.isActive,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: _paddingValue, vertical: _spacingSmall),
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
              const SizedBox(width: _spacingSmall),
              Text(
                l.translate(labelKey),
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
}

class _LocationControl extends StatelessWidget {
  final AppColorTheme colors;

  const _LocationControl({required this.colors});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MapScreenState>()!;
    return Positioned(
      bottom: 7,
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
            if (state._currentLocation != null) {
              state._mapController.rotate(-state._currentHeading);
              state._mapController.move(state._currentLocation!, 15);
            }
          },
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final AppColorTheme colors;

  const _ReportButton({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Positioned(
      bottom: 5,
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
            onPressed: () => _navigateTo(context, const ReportDisasterScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: _paddingValue, vertical: _spacingMedium),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined,
                      color: colors.bg100, size: 20),
                  const SizedBox(width: _spacingSmall),
                  Text(
                    l.translate('report_disaster'),
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
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
