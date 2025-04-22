import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mydpar/screens/report_disaster/report_disaster_screen.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/widgets/bottom_nav_bar.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/main/community_screen.dart';
import 'package:mydpar/screens/main/profile_screen.dart';
import 'package:mydpar/services/map_marker_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

const double _paddingValue = 16.0;
const double _spacingSmall = 8.0;
const double _spacingMedium = 12.0;
const double _spacingLarge = 24.0;

class MapScreen extends StatefulWidget {
  final String? initialMarkerId;
  final String? initialMarkerType;

  const MapScreen({
    Key? key,
    this.initialMarkerId,
    this.initialMarkerType,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _locationTimer;
  LatLng? _currentLocation;
  bool _isSearching = false;
  List<Location>? _searchResults;
  double _currentHeading = 0.0;
  LatLng? _searchedLocation;
  late MapMarkerService _markerService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const LatLng _defaultLocation =
      LatLng(3.1390, 101.6869); // Kuala Lumpur

  @override
  void initState() {
    super.initState();
    _markerService = MapMarkerService();
    _markerService.addListener(_onMarkersUpdated);
    _initializeLocation();
    _locationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateLocation());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationService>(context, listen: false).changeIndex(1);
      if (widget.initialMarkerId != null && widget.initialMarkerType != null) {
        _showInitialMarker();
      }
    });
  }

  void _showInitialMarker() {
    final marker = _markerService.getMarkerById(widget.initialMarkerId!);
    if (marker != null) {
      _showMarkerDetails(marker);
      _mapController.move(
        LatLng(marker['latitude'], marker['longitude']),
        15,
      );
    }
  }

  void _onMarkersUpdated() {
    debugPrint(
        'Markers updated: ${_markerService.getVisibleMarkers().length} markers visible');
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationTimer?.cancel();
    _markerService.removeListener(_onMarkersUpdated);
    _markerService.dispose();
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
    _markerService.toggleFilter(filter);
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  // Add the Google Maps navigation method
  void _openGoogleMaps(double latitude, double longitude) async {
    final Uri googleMapUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');

    if (await canLaunchUrl(googleMapUrl)) {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not open the map.');
    }
  }

  void _showMarkerDetails(Map<String, dynamic> marker) {
    final l = AppLocalizations.of(context);
    final colors =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    // Create a stream controller for the marker data
    final markerStreamController = StreamController<Map<String, dynamic>>();

    // Initialize with current marker data
    markerStreamController.add(marker);

    // Set up Firebase listeners based on marker type
    StreamSubscription? subscription;
    switch (marker['type']) {
      case 'SOS':
        subscription = _firestore
            .collection('alerts')
            .doc(marker['id'])
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            markerStreamController.add({
              ...marker,
              ...data,
              'id': snapshot.id,
            });
          }
        });
        break;
      case 'Shelter':
        subscription = _firestore
            .collection('shelters')
            .doc(marker['id'])
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            markerStreamController.add({
              ...marker,
              ...data,
              'id': snapshot.id,
            });
          }
        });
        break;
      case 'Disaster':
        subscription = _firestore
            .collection('disaster_reports')
            .doc(marker['id'])
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            markerStreamController.add({
              ...marker,
              ...data,
              'id': snapshot.id,
            });
          }
        });
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 300),
      ),
      enableDrag: true,
      isDismissible: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.25,
        minChildSize: 0.15,
        maxChildSize: 0.75,
        snap: true,
        snapSizes: const [0.25, 0.5, 0.75],
        builder: (context, scrollController) =>
            StreamBuilder<Map<String, dynamic>>(
          stream: markerStreamController.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                decoration: BoxDecoration(
                  color: colors.bg100,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final currentMarker = snapshot.data!;
            return Container(
              decoration: BoxDecoration(
                color: colors.bg100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.text200.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _markerService.getMarkerIcon(
                                    currentMarker['type'],
                                    disasterType: currentMarker['disasterType'],
                                  ),
                                  color: _markerService.getMarkerColor(
                                    currentMarker['type'],
                                    severity: currentMarker['severity'],
                                    colors: colors,
                                  ),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.translate(currentMarker['title'] ??
                                        currentMarker['name'] ??
                                        'unknown'),
                                    style: TextStyle(
                                      color: colors.primary300,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildMarkerContent(currentMarker, colors, l),
                            const SizedBox(height: 16),
                            _buildActionButtons(currentMarker, colors, l),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      // Clean up resources when the bottom sheet is closed
      subscription?.cancel();
      markerStreamController.close();
    });
  }

  Widget _buildMarkerContent(
      Map<String, dynamic> marker, AppColorTheme colors, AppLocalizations l) {
    switch (marker['type']) {
      case 'SOS':
        return _buildSOSContent(marker, colors, l);
      case 'Shelter':
        return _buildShelterContent(marker, colors, l);
      case 'Disaster':
        return _buildDisasterContent(marker, colors, l);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSOSContent(
      Map<String, dynamic> marker, AppColorTheme colors, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alert Status and Time
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: marker['isActive'] == true
                    ? colors.warning.withOpacity(0.1)
                    : colors.text200.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                marker['isActive'] == true
                    ? l.translate('active')
                    : l.translate('inactive'),
                style: TextStyle(
                  color: marker['isActive'] == true
                      ? colors.warning
                      : colors.text200,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            if (marker['alertStartTime'] != null)
              Text(
                _formatTimestamp(marker['alertStartTime']),
                style: TextStyle(color: colors.text200),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        if (marker['description'] != null && marker['description'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              marker['description'],
              style: TextStyle(color: colors.text200),
            ),
          ),

        // Location
        if (marker['address'] != null && marker['address'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colors.text200),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    marker['address'],
                    style: TextStyle(color: colors.text200),
                  ),
                ),
              ],
            ),
          ),

        // Reporter Information Section
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.translate('reporter_information'),
                style: TextStyle(
                  color: colors.primary300,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bg200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Photo and Name
                    Row(
                      children: [
                        if (marker['userPhotoUrl'] != null)
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(marker['userPhotoUrl']),
                                fit: BoxFit.cover,
                              ),
                              color: colors.bg100,
                            ),
                            child: marker['userPhotoUrl'] != null
                                ? null
                                : Icon(Icons.person, color: colors.text200),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.bg100,
                            ),
                            child: Icon(Icons.person, color: colors.text200),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${marker['firstName']} ${marker['lastName']}'
                                    .trim(),
                                style: TextStyle(
                                  color: colors.text200,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (marker['userCreatedAt'] != null)
                                Text(
                                  l.translate('member_since', {
                                    'date': _formatDate(marker['userCreatedAt'])
                                  }),
                                  style: TextStyle(
                                    color: colors.text200.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Phone Number
                    if (marker['userPhone'] != null &&
                        marker['userPhone'].isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: colors.text200),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () =>
                                _makePhoneCall(marker['userPhone']),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              marker['userPhone'],
                              style: TextStyle(
                                color: colors.accent200,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Emergency Contacts Section
        if (marker['emergencyContacts'] != null &&
            (marker['emergencyContacts'] as List).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.translate('emergency_contacts'),
                  style: TextStyle(
                    color: colors.primary300,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...(marker['emergencyContacts'] as List).map((contact) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.bg200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 16, color: colors.text200),
                              const SizedBox(width: 4),
                              Text(
                                contact['name'] ?? l.translate('unknown'),
                                style: TextStyle(
                                  color: colors.text200,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (contact['relation'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 16, color: colors.text200),
                                  const SizedBox(width: 4),
                                  Text(
                                    contact['relation'],
                                    style: TextStyle(color: colors.text200),
                                  ),
                                ],
                              ),
                            ),
                          if (contact['phone'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.phone_outlined,
                                      size: 16, color: colors.text200),
                                  const SizedBox(width: 4),
                                  TextButton(
                                    onPressed: () =>
                                        _makePhoneCall(contact['phone']),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      contact['phone'],
                                      style: TextStyle(
                                        color: colors.accent200,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

        // Latest Update Time
        if (marker['latestUpdateTime'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.update, size: 16, color: colors.text200),
                const SizedBox(width: 4),
                Text(
                  l.translate('last_updated',
                      {'time': _formatTimestamp(marker['latestUpdateTime'])}),
                  style: TextStyle(color: colors.text200),
                ),
              ],
            ),
          ),

        // Cancel Time if available
        if (marker['cancelTime'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 16, color: colors.text200),
                const SizedBox(width: 4),
                Text(
                  l.translate('cancelled',
                      {'time': _formatTimestamp(marker['cancelTime'])}),
                  style: TextStyle(color: colors.text200),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShelterContent(
      Map<String, dynamic> marker, AppColorTheme colors, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accent200.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              marker['status'] ?? l.translate('unknown'),
              style: TextStyle(
                color: colors.accent200,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Location
        if (marker['locationName'] != null && marker['locationName'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colors.text200),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    marker['locationName'],
                    style: TextStyle(color: colors.text200),
                  ),
                ),
              ],
            ),
          ),

        // Occupancy
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 20, color: colors.text200),
                    const SizedBox(width: 8),
                    Text(
                      l.translate('current_occupancy'),
                      style: TextStyle(
                        color: colors.text200,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${marker['currentOccupancy'] ?? 0}',
                      style: TextStyle(
                        color: colors.accent200,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${marker['capacity'] ?? 0}',
                      style: TextStyle(
                        color: colors.text200,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Demographics
        if (marker['demographics'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bg200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups, size: 20, color: colors.text200),
                      const SizedBox(width: 8),
                      Text(
                        l.translate('demographics'),
                        style: TextStyle(
                          color: colors.text200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDemographicItem(
                    colors,
                    Icons.elderly,
                    l.translate('elderly'),
                    marker['demographics']['elderly'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildDemographicItem(
                    colors,
                    Icons.person,
                    l.translate('adults'),
                    marker['demographics']['adults'] ?? 0,
                  ),
                  const SizedBox(height: 8),
                  _buildDemographicItem(
                    colors,
                    Icons.child_care,
                    l.translate('children'),
                    marker['demographics']['children'] ?? 0,
                  ),
                ],
              ),
            ),
          ),

        // Creator Information
        if (marker['createdBy'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.translate('creator_information'),
                  style: TextStyle(
                    color: colors.primary300,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bg200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Creator Photo and Name
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.bg100,
                            ),
                            child: marker['creatorPhotoUrl'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      marker['creatorPhotoUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                              Icons.person,
                                              color: colors.text200),
                                    ),
                                  )
                                : Icon(Icons.person, color: colors.text200),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  marker['creatorName'] ??
                                      l.translate('unknown'),
                                  style: TextStyle(
                                    color: colors.text200,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (marker['creatorRole'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.accent200.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      marker['creatorRole']
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: colors.accent200,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (marker['creatorCreatedAt'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      l.translate('member_since', {
                                        'date': _formatDate(
                                            marker['creatorCreatedAt'])
                                      }),
                                      style: TextStyle(
                                        color: colors.text200.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Phone Number
                      if (marker['creatorPhone'] != null &&
                          marker['creatorPhone'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Icon(Icons.phone,
                                  size: 16, color: colors.text200),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () =>
                                    _makePhoneCall(marker['creatorPhone']),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  marker['creatorPhone'],
                                  style: TextStyle(
                                    color: colors.accent200,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Timestamps
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              if (marker['createdAt'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: colors.text200),
                      const SizedBox(width: 4),
                      Text(
                        l.translate('created_at',
                            {'time': _formatTimestamp(marker['createdAt'])}),
                        style: TextStyle(color: colors.text200),
                      ),
                    ],
                  ),
                ),
              if (marker['updatedAt'] != null)
                Row(
                  children: [
                    Icon(Icons.update, size: 16, color: colors.text200),
                    const SizedBox(width: 4),
                    Text(
                      l.translate('updated_at',
                          {'time': _formatTimestamp(marker['updatedAt'])}),
                      style: TextStyle(color: colors.text200),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemographicItem(
      AppColorTheme colors, IconData icon, String label, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.text200),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: colors.text200),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: TextStyle(
            color: colors.text200,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds the verification UI for disaster markers
  Widget _buildVerificationUI(
    Map<String, dynamic> marker,
    AppColorTheme colors,
    AppLocalizations l,
    _MapScreenState state,
  ) {
    if (marker['type'] != 'Disaster') return const SizedBox.shrink();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: state._markerService.disasterService.getVerificationStatus(
        marker['id'],
        userId,
        context,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final status = snapshot.data!;
        final bool canVerify = status['canVerify'];
        final bool hasVerified = status['hasVerified'];
        final bool isFalseAlarm = status['isFalseAlarm'];
        final int verificationCount = status['verificationCount'];
        final int verifyFalseNum = status['verifyFalseNum'] ?? 0;
        final Timestamp? lastUpdated = status['lastUpdated'];
        final String message = status['message'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Verification status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bg200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFalseAlarm
                      ? colors.warning
                      : hasVerified
                          ? colors.accent200
                          : colors.text200.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFalseAlarm
                            ? Icons.warning_amber_rounded
                            : hasVerified
                                ? Icons.verified_user
                                : Icons.verified_outlined,
                        color: isFalseAlarm
                            ? colors.warning
                            : hasVerified
                                ? colors.accent200
                                : colors.text200,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: colors.text200,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Verification counts
                  Row(
                    children: [
                      Text(
                        '${l.translate('verified_true')}: $verificationCount',
                        style: TextStyle(
                          color: colors.text200.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${l.translate('verified_not_true')}: $verifyFalseNum',
                        style: TextStyle(
                          color: colors.text200.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Last updated time
                  if (lastUpdated != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l.translate('last_updated')}: ${_formatTimestamp(lastUpdated)}',
                      style: TextStyle(
                        color: colors.text200.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canVerify) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (state._currentLocation == null) {
                          state._showSnackBar(
                            'location_required_for_verification',
                            colors.warning,
                          );
                          return;
                        }
                        final success = await state
                            ._markerService.disasterService
                            .verifyDisaster(
                          marker['id'],
                          userId,
                          state._currentLocation!,
                        );
                        if (success) {
                          state._showSnackBar(
                            'verification_successful',
                            colors.accent200,
                          );
                        } else {
                          state._showSnackBar(
                            'verification_failed',
                            colors.warning,
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_user),
                      label: Text(l.translate('verify_disaster')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent200,
                        foregroundColor: colors.bg100,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (state._currentLocation == null) {
                        state._showSnackBar(
                          'location_required_for_verification',
                          colors.warning,
                        );
                        return;
                      }
                      // Show confirmation dialog
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l.translate('not_true')),
                          content: Text(l.translate('not_true_confirmation')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l.translate('cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l.translate('confirm')),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await state
                            ._markerService.disasterService
                            .markAsFalseAlarm(
                          marker['id'],
                          userId,
                          state._currentLocation!,
                        );
                        if (success) {
                          state._showSnackBar(
                            'marked_as_not_true',
                            colors.accent200,
                          );
                        } else {
                          state._showSnackBar(
                            'not_true_marking_failed',
                            colors.warning,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: Text(l.translate('not_true')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.warning,
                      foregroundColor: colors.bg100,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDisasterContent(
      Map<String, dynamic> marker, AppColorTheme colors, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disaster Type with Severity
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(marker['severity'], colors)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l.translate(
                      'disaster_type_${marker['disasterType'].toString().toLowerCase()}'),
                  style: TextStyle(
                    color: _getSeverityColor(marker['severity'], colors),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(marker['severity'], colors)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l.translate(
                      'severity_${marker['severity'].toString().toLowerCase()}'),
                  style: TextStyle(
                    color: _getSeverityColor(marker['severity'], colors),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Description
        if (marker['description'] != null && marker['description'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              marker['description'],
              style: TextStyle(color: colors.text200),
            ),
          ),

        // Location
        if (marker['location'] != null && marker['location'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colors.text200),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    marker['location'],
                    style: TextStyle(color: colors.text200),
                  ),
                ),
              ],
            ),
          ),

        // Timestamp
        if (marker['timestamp'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: colors.text200),
                const SizedBox(width: 4),
                Text(
                  l.translate('reported_at',
                      {'time': _formatTimestamp(marker['timestamp'])}),
                  style: TextStyle(color: colors.text200),
                ),
              ],
            ),
          ),

        // Status
        if (marker['status'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.text200),
                const SizedBox(width: 4),
                Text(
                  l.translate(
                      'status_${marker['status'].toString().toLowerCase()}'),
                  style: TextStyle(color: colors.text200),
                ),
              ],
            ),
          ),

        // Photos
        if (marker['photoPaths'] != null &&
            (marker['photoPaths'] as List).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l.translate('photos'),
                    style: TextStyle(
                      color: colors.text200,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (marker['photoPaths'] as List).length,
                    itemBuilder: (context, index) {
                      final photoPath = (marker['photoPaths'] as List)[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photoPath,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 150,
                              width: 150,
                              color: colors.bg200,
                              child: Center(
                                child: Icon(Icons.image_not_supported,
                                    color: colors.text200),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // Add verification UI after the existing content
        _buildVerificationUI(marker, colors, l, this),
      ],
    );
  }

  Color _getSeverityColor(String? severity, AppColorTheme colors) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return colors.warning;
      case 'medium':
        return const Color(0xFFFF8C00); // Orange
      case 'low':
        return const Color(0xFF71C4EF); // Light blue
      default:
        return colors.text200;
    }
  }

  Widget _buildActionButtons(
      Map<String, dynamic> marker, AppColorTheme colors, AppLocalizations l) {
    // Don't show navigation button for disasters
    if (marker['type'] == 'Disaster') {
      return const SizedBox.shrink();
    }

    final position = marker['position'] as LatLng;
    String buttonText = marker['type'] == 'SOS'
        ? l.translate('respond_to_sos')
        : l.translate('navigate_to_shelter');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          _openGoogleMaps(position.latitude, position.longitude);
        },
        icon: const Icon(Icons.directions),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              marker['type'] == 'SOS' ? colors.warning : colors.accent200,
          foregroundColor: colors.bg100,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _navigateToMarkerLocation(Map<String, dynamic> marker) {
    if (marker['position'] == null) return;

    final position = marker['position'] as LatLng;
    _openGoogleMaps(position.latitude, position.longitude);

    // Close the bottom sheet
    Navigator.pop(context);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown';
    }

    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '';
      }

      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _markerService,
      child: Builder(
        builder: (context) {
          final colors = context.watch<ThemeProvider>().currentTheme;
          final navigationService = Provider.of<NavigationService>(context);

          return Scaffold(
            backgroundColor: colors.bg200,
            body: SafeArea(
              child: Stack(
                children: [
                  _Map(
                    colors: colors,
                    markerService: _markerService,
                    onMarkerTap: _showMarkerDetails,
                  ),
                  _SearchBar(colors: colors),
                  _FilterControls(colors: colors),
                  _LocationControl(colors: colors),
                  _ReportButton(colors: colors),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavBar(
              onTap: (index) {
                if (index != 1) {
                  // Only navigate if not already on map screen
                  navigationService.changeIndex(index);
                  _navigateToScreen(index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToScreen(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 2:
        screen = const CommunityScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

class _Map extends StatelessWidget {
  final AppColorTheme colors;
  final MapMarkerService markerService;
  final Function(Map<String, dynamic>) onMarkerTap;

  const _Map({
    required this.colors,
    required this.markerService,
    required this.onMarkerTap,
  });

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
            ...markerService.getVisibleMarkers().map((marker) {
              final bool isFalseAlarm = marker['type'] == 'Disaster' &&
                  marker['status']?.toLowerCase() == 'false_alarm';

              return Marker(
                point: marker['position'] as LatLng,
                width: 40,
                height: 40,
                builder: (_) => GestureDetector(
                  onTap: () => onMarkerTap(marker),
                  child: Stack(
                    children: [
                      Icon(
                        markerService.getMarkerIcon(
                          marker['type'],
                          disasterType: marker['disasterType'],
                        ),
                        color: isFalseAlarm
                            ? colors.warning.withOpacity(0.5)
                            : markerService.getMarkerColor(
                                marker['type'],
                                severity: marker['severity'],
                                colors: colors,
                              ),
                        size: 30,
                      ),
                      if (isFalseAlarm)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colors.bg100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.warning,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: colors.warning,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
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
    final markerService = state._markerService;

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
                isActive: markerService.activeFilters.contains('SOS'),
                onTap: () => state._toggleFilter('SOS'),
                colors: colors,
              ),
              _FilterButton(
                icon: Icons.warning_amber_rounded,
                labelKey: 'disasters',
                isActive: markerService.activeFilters.contains('Disasters'),
                onTap: () => state._toggleFilter('Disasters'),
                colors: colors,
              ),
              _FilterButton(
                icon: Icons.home_outlined,
                labelKey: 'shelters',
                isActive: markerService.activeFilters.contains('Shelters'),
                onTap: () => state._toggleFilter('Shelters'),
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
