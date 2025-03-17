import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

// Model for incident data, Firebase-ready
class Incident {
  final String title;
  final String description;
  final String severity;
  final String location;
  final String time;
  final String disasterType;
  final LatLng? coordinates;

  const Incident({
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    required this.time,
    required this.disasterType,
    this.coordinates,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'severity': severity,
        'location': location,
        'time': time,
        'disasterType': disasterType,
        'coordinates': coordinates != null
            ? {
                'latitude': coordinates!.latitude,
                'longitude': coordinates!.longitude
              }
            : null,
      };
}

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  String _selectedSort = 'time';
  bool _isAscending = true;
  String _selectedType = 'All Types';
  Position? _currentPosition;

  static const List<String> _disasterTypes = [
    'All Types',
    'Heavy Rain',
    'Flood',
    'Fire',
    'Landslide',
    'Haze',
    'Other',
  ];
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  final List<Incident> _incidents = const [
    Incident(
      title: 'Flash Flood Warning',
      description: 'Severe flooding reported in Klang Valley area...',
      severity: 'High',
      location: 'Klang Valley Region',
      time: '2023-11-15 14:30',
      coordinates: LatLng(3.1390, 101.6869),
      disasterType: 'Flood',
    ),
    Incident(
      title: 'Landslide Risk',
      description: 'Potential landslide risk in highland areas...',
      severity: 'Medium',
      location: 'Cameron Highlands',
      time: '2023-11-15 11:30',
      coordinates: LatLng(4.4718, 101.3750),
      disasterType: 'Landslide',
    ),
    Incident(
      title: 'Heavy Rain Advisory',
      description: 'Expected heavy rainfall in the evening...',
      severity: 'Low',
      location: 'Kuala Lumpur',
      time: '2023-11-14 14:30',
      coordinates: null,
      disasterType: 'Landslide',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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
      setState(() => _currentPosition = position);
    } catch (e) {
      _showSnackBar('Error getting location: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colors),
            _buildFilterSection(colors),
            Expanded(child: _buildContent(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: _paddingValue),
        decoration: BoxDecoration(
          color: colors.bg100,
          border: Border(
              bottom: BorderSide(color: colors.primary200.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.accent200),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              'All Incidents',
              style: TextStyle(
                color: colors.accent200,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterSection(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_paddingValue),
        decoration: BoxDecoration(
          color: colors.bg100,
          border: Border(
              bottom: BorderSide(color: colors.primary200.withOpacity(0.2))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Disaster Type',
              style: TextStyle(
                color: colors.accent200,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _disasterTypes.map((type) {
                  final bool isSelected = type == _selectedType;
                  return Padding(
                    padding: const EdgeInsets.only(right: _spacingSmall),
                    child: FilterChip(
                      avatar: Icon(
                        type == 'All Types'
                            ? Icons.filter_list
                            : _getDisasterIcon(type),
                        size: 18,
                        color: isSelected ? colors.accent200 : colors.text200,
                      ),
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() =>
                            _selectedType = selected ? type : 'All Types');
                      },
                      backgroundColor: colors.bg100,
                      selectedColor: colors.primary100,
                      labelStyle: TextStyle(
                        color: isSelected ? colors.accent200 : colors.text200,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              isSelected ? colors.accent100 : colors.primary200,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: _spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Sort Incidents By',
                      style: TextStyle(
                        color: colors.accent200,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: _spacingMedium),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.bg100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.accent100),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: _spacingMedium),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          items: const [
                            DropdownMenuItem(
                                value: 'time', child: Text('Time')),
                            DropdownMenuItem(
                                value: 'severity', child: Text('Severity')),
                            DropdownMenuItem(
                                value: 'distance', child: Text('Distance')),
                          ],
                          onChanged: (newValue) {
                            setState(() => _selectedSort = newValue!);
                          },
                          style: TextStyle(color: colors.accent200),
                          dropdownColor: colors.bg100,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.bg100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.accent100),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: colors.accent200,
                    ),
                    onPressed: () =>
                        setState(() => _isAscending = !_isAscending),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildContent(AppColorTheme colors) {
    List<Incident> filteredIncidents = _selectedType == 'All Types'
        ? List.from(_incidents)
        : _incidents
            .where((incident) => incident.disasterType == _selectedType)
            .toList();

    switch (_selectedSort) {
      case 'time':
        filteredIncidents.sort((a, b) => _isAscending
            ? DateTime.parse(a.time).compareTo(DateTime.parse(b.time))
            : DateTime.parse(b.time).compareTo(DateTime.parse(a.time)));
        break;
      case 'severity':
        const Map<String, int> severityOrder = {
          'High': 3,
          'Medium': 2,
          'Low': 1
        };
        filteredIncidents.sort((a, b) => _isAscending
            ? (severityOrder[a.severity] ?? 0)
                .compareTo(severityOrder[b.severity] ?? 0)
            : (severityOrder[b.severity] ?? 0)
                .compareTo(severityOrder[a.severity] ?? 0));
        break;
      case 'distance':
        if (_currentPosition != null) {
          filteredIncidents.sort((a, b) {
            final double distanceA = a.coordinates != null
                ? Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    a.coordinates!.latitude,
                    a.coordinates!.longitude,
                  )
                : double.infinity;
            final double distanceB = b.coordinates != null
                ? Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    b.coordinates!.latitude,
                    b.coordinates!.longitude,
                  )
                : double.infinity;
            return _isAscending
                ? distanceA.compareTo(distanceB)
                : distanceB.compareTo(distanceA);
          });
        }
        break;
    }

    if (filteredIncidents.isEmpty) {
      return Center(
        child: Text(
          'No incidents match your filters',
          style: TextStyle(color: colors.text200),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(_paddingValue),
      itemCount: filteredIncidents.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: _spacingLarge),
            child: Text(
              'Active Incidents (${filteredIncidents.length})',
              style: TextStyle(
                color: colors.accent200,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final Incident incident = filteredIncidents[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: _spacingSmall),
          child: _buildIncidentCard(
            colors: colors,
            title: incident.title,
            description: incident.description,
            severity: incident.severity,
            location: incident.location,
            time: incident.time,
            disasterType: incident.disasterType,
            coordinates: incident.coordinates,
          ),
        );
      },
    );
  }

  Widget _buildIncidentCard({
    required AppColorTheme colors,
    required String title,
    required String description,
    required String severity,
    required String location,
    required String time,
    required String disasterType,
    LatLng? coordinates,
  }) {
    final Color severityColor = _getSeverityColor(severity, colors);

    String distanceText = '';
    if (_currentPosition != null && coordinates != null) {
      final double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        coordinates.latitude,
        coordinates.longitude,
      );
      distanceText = distanceInMeters < 1000
          ? '${distanceInMeters.round()} m'
          : '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: severityColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(_paddingValue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: severityColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              _getDisasterIcon(disasterType),
                              color: colors.bg100,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: _spacingSmall),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: colors.primary300,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  disasterType,
                                  style: TextStyle(
                                    color: colors.text200,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severity,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _spacingMedium),
                Text(
                  description,
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
                if (coordinates != null) ...[
                  const SizedBox(height: _spacingMedium),
                  SizedBox(
                    height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        options: MapOptions(
                          center: coordinates,
                          zoom: 12,
                          interactiveFlags: InteractiveFlag.none,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: coordinates,
                                builder: (_) => Icon(
                                  Icons.location_pin,
                                  color: severityColor,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: _spacingMedium),
                Row(
                  children: [
                    Icon(Icons.location_on, color: colors.text200, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$location${distanceText.isNotEmpty ? ' ($distanceText)' : ''}',
                        style: TextStyle(color: colors.text200, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, color: colors.text200, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(color: colors.text200, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity, AppColorTheme colors) {
    switch (severity.toLowerCase()) {
      case 'high':
        return colors.warning;
      case 'medium':
        return const Color(0xFFFF8C00);
      case 'low':
        return const Color(0xFF71C4EF);
      default:
        return colors.text200;
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}

IconData _getDisasterIcon(String type) {
  const IconData flood = IconData(0xf07a3, fontFamily: 'MaterialIcons');
  const IconData tsunami = IconData(0xf07cf, fontFamily: 'MaterialIcons');

  switch (type.toLowerCase()) {
    case 'heavy rain':
      return Icons.thunderstorm_outlined;
    case 'flood':
      return flood;
    case 'fire':
      return Icons.local_fire_department;
    case 'earthquake':
      return Icons.terrain;
    case 'landslide':
      return Icons.landslide;
    case 'tsunami':
      return tsunami;
    case 'haze':
      return Icons.air;
    case 'typhoon':
      return Icons.cyclone;
    case 'other':
      return Icons.warning_amber_rounded;
    default:
      return Icons.error_outline;
  }
}
