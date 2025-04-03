import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/screens/disaster_infomation/disaster_detail_screen.dart';
import 'package:mydpar/localization/app_localizations.dart';

/// Displays a list of ongoing disasters with filtering and sorting capabilities.
class DisastersScreen extends StatefulWidget {
  const DisastersScreen({super.key});

  @override
  State<DisastersScreen> createState() => _DisastersScreenState();
}

class _DisastersScreenState extends State<DisastersScreen> {
  // State variables
  String _selectedSort = 'time';
  bool _isAscending = true;
  String _selectedType = 'All Types';
  Position? _currentPosition;
  bool _showBackToTop = false;

  // Constants
  static const _disasterTypes = [
    'all_types',
    'heavy_rain',
    'earthquake',
    'flood',
    'fire',
    'landslide',
    'haze',
    'other',
  ];
  static const _padding = 16.0;
  static const _spacingSmall = 8.0;
  static const _spacingMedium = 12.0;
  static const _spacingLarge = 24.0;

  // Controllers
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Initializes the screen by fetching location and disasters.
  void _initialize() {
    _fetchCurrentLocation();
    _scrollController.addListener(_updateBackToTopVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the DisasterService to fetch all disasters
      Provider.of<DisasterService>(context, listen: false)
          .fetchDisasters(onlyHappening: true);
    });
  }

  /// Updates the visibility of the back-to-top button based on scroll position.
  void _updateBackToTopVisibility() {
    setState(() => _showBackToTop = _scrollController.offset >= 200);
  }

  /// Fetches the user's current location.
  Future<void> _fetchCurrentLocation() async {
    try {
      if (!await _checkLocationPermission()) return;
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);
    } catch (e) {
      _showSnackBar(
          AppLocalizations.of(context)
              .translate('error_location')
              .replaceAll('{error}', e.toString()),
          Colors.red);
    }
  }

  /// Checks and requests location permissions.
  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showSnackBar(AppLocalizations.of(context).translate('location_disabled'),
          Colors.red);
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar(AppLocalizations.of(context).translate('location_denied'),
            Colors.red);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          AppLocalizations.of(context).translate('location_denied_forever'),
          Colors.red);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            _buildFilterSection(colors),
            Expanded(child: _buildContent(colors)),
          ],
        ),
      ),
    );
  }

  /// Builds the header with a back button and title.
  Widget _buildHeader(AppColorTheme colors) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        decoration: _headerDecoration(colors),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.accent200),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              AppLocalizations.of(context).translate('happening_disasters'),
              style: TextStyle(
                  color: colors.accent200,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  /// Builds the filter section with type selection and sorting options.
  Widget _buildFilterSection(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_padding),
        decoration: _sectionDecoration(colors),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('filter_by_type'),
                style: _labelStyle(colors)),
            const SizedBox(height: _spacingSmall),
            _buildTypeFilterChips(colors),
            const SizedBox(height: _spacingLarge),
            _buildSortOptions(colors),
          ],
        ),
      );

  /// Builds the content area with a list of disasters.
  Widget _buildContent(AppColorTheme colors) => Consumer<DisasterService>(
        builder: (context, service, child) =>
            _buildDisasterList(service, colors),
      );

  /// Builds filter chips for disaster types.
  Widget _buildTypeFilterChips(AppColorTheme colors) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _disasterTypes
              .map((type) => _buildFilterChip(type, colors))
              .toList(),
        ),
      );

  /// Builds a single filter chip.
  Widget _buildFilterChip(String type, AppColorTheme colors) {
    final isSelected = type == _selectedType;
    return Padding(
      padding: const EdgeInsets.only(right: _spacingSmall),
      child: FilterChip(
        avatar: Icon(
          type == 'all_types' ? Icons.filter_list : getDisasterIcon(type),
          size: 18,
          color: isSelected ? colors.accent200 : colors.text200,
        ),
        label: Text(AppLocalizations.of(context).translate(type)),
        selected: isSelected,
        onSelected: (selected) =>
            setState(() => _selectedType = selected ? type : 'all_types'),
        backgroundColor: colors.bg100,
        selectedColor: colors.primary100,
        labelStyle:
            TextStyle(color: isSelected ? colors.accent200 : colors.text200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: isSelected ? colors.accent100 : colors.primary200),
        ),
      ),
    );
  }

  /// Builds sorting options with dropdown and direction toggle.
  Widget _buildSortOptions(AppColorTheme colors) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(AppLocalizations.of(context).translate('sort_by'),
                  style: _labelStyle(colors)),
              const SizedBox(width: _spacingMedium),
              _buildSortDropdown(colors),
            ],
          ),
          _buildSortDirectionButton(colors),
        ],
      );

  /// Builds the sort dropdown menu.
  Widget _buildSortDropdown(AppColorTheme colors) => Container(
        decoration: _dropdownDecoration(colors),
        padding: const EdgeInsets.symmetric(horizontal: _spacingMedium),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedSort,
            items: [
              DropdownMenuItem(
                  value: 'time',
                  child: Text(AppLocalizations.of(context).translate('time'))),
              DropdownMenuItem(
                  value: 'severity',
                  child:
                      Text(AppLocalizations.of(context).translate('severity'))),
              DropdownMenuItem(
                  value: 'distance',
                  child:
                      Text(AppLocalizations.of(context).translate('distance'))),
            ],
            onChanged: (value) => setState(() => _selectedSort = value!),
            style: TextStyle(color: colors.accent200),
            dropdownColor: colors.bg100,
          ),
        ),
      );

  /// Builds the sort direction toggle button.
  Widget _buildSortDirectionButton(AppColorTheme colors) => Container(
        decoration: _dropdownDecoration(colors),
        child: IconButton(
          icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: colors.accent200),
          onPressed: () => setState(() => _isAscending = !_isAscending),
        ),
      );

  /// Builds the disaster list based on service state.
  Widget _buildDisasterList(DisasterService service, AppColorTheme colors) {
    if (service.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (service.error != null) {
      return Center(
          child: Text('Error: ${service.error}',
              style: TextStyle(color: colors.warning)));
    }

    final filteredDisasters =
        _filterAndSortDisasters(service.happeningDisasters);
    if (filteredDisasters.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context).translate('no_disasters'),
              style: TextStyle(color: colors.text200)));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await service.fetchDisasters(onlyHappening: true);
        await _fetchCurrentLocation();
      },
      color: colors.accent200,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(_padding),
            itemCount: filteredDisasters.length + 1,
            itemBuilder: (_, index) => index == 0
                ? _buildListHeader(filteredDisasters.length, service, colors)
                : _buildDisasterCard(filteredDisasters[index - 1], colors),
          ),
          if (_showBackToTop) _buildBackToTopButton(colors),
        ],
      ),
    );
  }

  /// Builds the list header with disaster count and refresh button.
  Widget _buildListHeader(
          int count, DisasterService service, AppColorTheme colors) =>
      Padding(
        padding: const EdgeInsets.only(bottom: _spacingLarge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppLocalizations.of(context).translate('happening_disasters')} ($count)',
              style: TextStyle(
                  color: colors.accent200,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: colors.accent200, size: 20),
              onPressed: () async {
                await service.fetchDisasters(onlyHappening: true);
                await _fetchCurrentLocation();
              },
            ),
          ],
        ),
      );

  /// Builds a disaster card with details and map.
  Widget _buildDisasterCard(DisasterModel disaster, AppColorTheme colors) =>
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisasterDetailScreen(disasterId: disaster.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: _spacingSmall),
          child: Container(
            decoration: _cardDecoration(
                colors, _getSeverityColor(disaster.severity, colors)),
            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(disaster, colors),
                  const SizedBox(height: _spacingMedium),
                  // Translate the description if needed
                  Text(disaster.description,
                      style: TextStyle(color: colors.text200, fontSize: 14)),
                  const SizedBox(height: _spacingMedium),
                  _buildStatusRow(disaster.status, colors),
                  if (disaster.coordinates != null) ...[
                    const SizedBox(height: _spacingMedium),
                    _buildMiniMap(disaster.coordinates!, colors),
                  ],
                  const SizedBox(height: _spacingMedium),
                  _buildLocationRow(
                      disaster.location, disaster.coordinates, colors),
                  const SizedBox(height: 4),
                  _buildTimeRow(disaster, colors),
                ],
              ),
            ),
          ),
        ),
      );

  /// Builds the header section of a disaster card.
  Widget _buildCardHeader(DisasterModel disaster, AppColorTheme colors) {
    final severityColor =
        DisasterService.getSeverityColor(disaster.severity, colors);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4)),
                child: Icon(
                    DisasterService.getDisasterIcon(disaster.disasterType),
                    color: colors.bg100,
                    size: 20),
              ),
              const SizedBox(width: _spacingSmall),
              Expanded(
                child: Text(
                    // Translate the disaster type
                    AppLocalizations.of(context).translate(
                        'disaster_type_${disaster.disasterType.toLowerCase().replaceAll(' ', '_')}'),
                    style: TextStyle(color: colors.text200, fontSize: 18)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: _spacingSmall, vertical: 4),
          decoration: BoxDecoration(
              color: severityColor, borderRadius: BorderRadius.circular(12)),
          child: Text(
              AppLocalizations.of(context)
                  .translate('severity_${disaster.severity.toLowerCase()}'),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }

  /// Builds the status row.
  Widget _buildStatusRow(String status, AppColorTheme colors) => Row(
        children: [
          Icon(Icons.verified, color: colors.text200, size: 16),
          const SizedBox(width: 4),
          Text(
              '${AppLocalizations.of(context).translate('status')}: ${AppLocalizations.of(context).translate('status_${status.toLowerCase().replaceAll(' ', '_')}')}',
              style: TextStyle(color: colors.text200, fontSize: 12)),
        ],
      );

  /// Builds a mini map for the disaster location.
  Widget _buildMiniMap(LatLng coordinates, AppColorTheme colors) => SizedBox(
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FlutterMap(
            options: MapOptions(
                center: coordinates,
                zoom: 12,
                interactiveFlags: InteractiveFlag.none),
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
                    builder: (_) => Icon(Icons.location_pin,
                        color: _getSeverityColor('high', colors), size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// Builds the location row with distance if available.
  Widget _buildLocationRow(
      String location, LatLng? coordinates, AppColorTheme colors) {
    String distanceText = '';
    if (_currentPosition != null && coordinates != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        coordinates.latitude,
        coordinates.longitude,
      );

      // Use the same approach as in disaster_detail_screen.dart
      distanceText =
          ' (${AppLocalizations.of(context).translate('distance_away').replaceAll('{distance}', (distanceInMeters / 1000).toStringAsFixed(1))})';
    }

    return Row(
      children: [
        Icon(Icons.location_on, color: colors.text200, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text('$location$distanceText',
              style: TextStyle(color: colors.text200, fontSize: 12)),
        ),
      ],
    );
  }

  /// Builds the time row with localized relative time.
  Widget _buildTimeRow(DisasterModel disaster, AppColorTheme colors) {
    // Assuming disaster has a method to get the raw timestamp
    final timestamp = DateTime.parse(disaster.timestamp);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    String timeText;

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      timeText = years == 1
          ? AppLocalizations.of(context).translate('time_year_ago')
          : AppLocalizations.of(context)
              .translate('time_years_ago')
              .replaceAll('{count}', years.toString());
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      timeText = months == 1
          ? AppLocalizations.of(context).translate('time_month_ago')
          : AppLocalizations.of(context)
              .translate('time_months_ago')
              .replaceAll('{count}', months.toString());
    } else if (difference.inDays > 0) {
      timeText = difference.inDays == 1
          ? AppLocalizations.of(context).translate('time_day_ago')
          : AppLocalizations.of(context)
              .translate('time_days_ago')
              .replaceAll('{count}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      timeText = difference.inHours == 1
          ? AppLocalizations.of(context).translate('time_hour_ago')
          : AppLocalizations.of(context)
              .translate('time_hours_ago')
              .replaceAll('{count}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      timeText = difference.inMinutes == 1
          ? AppLocalizations.of(context).translate('time_minute_ago')
          : AppLocalizations.of(context)
              .translate('time_minutes_ago')
              .replaceAll('{count}', difference.inMinutes.toString());
    } else {
      timeText = AppLocalizations.of(context).translate('time_just_now');
    }

    return Row(
      children: [
        Icon(Icons.access_time, color: colors.text200, size: 16),
        const SizedBox(width: 4),
        Text(timeText, style: TextStyle(color: colors.text200, fontSize: 12)),
      ],
    );
  }

  /// Builds the back-to-top button.
  Widget _buildBackToTopButton(AppColorTheme colors) => Positioned(
        bottom: 20,
        right: 20,
        child: AnimatedOpacity(
          opacity: _showBackToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.extended(
            backgroundColor: colors.accent200.withOpacity(0.6),
            onPressed: () => _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
            icon: Icon(Icons.arrow_upward, color: colors.bg100),
            label: Text(AppLocalizations.of(context).translate('back_to_top'),
                style: TextStyle(color: colors.bg100)),
          ),
        ),
      );

  /// Filters and sorts the disaster list based on user selections.
  List<DisasterModel> _filterAndSortDisasters(List<DisasterModel> disasters) {
    final filtered = _selectedType == 'All Types'
        ? disasters
        : disasters
            .where((d) =>
                d.disasterType.toLowerCase() == _selectedType.toLowerCase())
            .toList();
    _sortDisasters(filtered);
    return filtered;
  }

  /// Sorts disasters based on the selected criterion.
  void _sortDisasters(List<DisasterModel> disasters) {
    disasters.sort((a, b) {
      switch (_selectedSort) {
        case 'time':
          return _compareTime(a.timestamp, b.timestamp);
        case 'severity':
          return _compareSeverity(a.severity, b.severity);
        case 'distance':
          return _compareDistance(a.coordinates, b.coordinates);
        default:
          return 0;
      }
    });
  }

  /// Compares disaster times.
  int _compareTime(String timeA, String timeB) {
    try {
      final dateA = DateTime.parse(timeA);
      final dateB = DateTime.parse(timeB);
      return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return 0;
    }
  }

  /// Compares disaster severities.
  int _compareSeverity(String severityA, String severityB) {
    final valueA = _getSeverityValue(severityA);
    final valueB = _getSeverityValue(severityB);
    return _isAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
  }

  /// Compares distances from current position.
  int _compareDistance(LatLng? coordA, LatLng? coordB) {
    if (_currentPosition == null) return 0;
    final distanceA = coordA != null
        ? Geolocator.distanceBetween(_currentPosition!.latitude,
            _currentPosition!.longitude, coordA.latitude, coordA.longitude)
        : double.infinity;
    final distanceB = coordB != null
        ? Geolocator.distanceBetween(_currentPosition!.latitude,
            _currentPosition!.longitude, coordB.latitude, coordB.longitude)
        : double.infinity;
    return _isAscending
        ? distanceA.compareTo(distanceB)
        : distanceB.compareTo(distanceA);
  }

  /// Maps severity to a numeric value for sorting.
  int _getSeverityValue(String severity) => switch (severity.toLowerCase()) {
        'high' => 3,
        'medium' => 2,
        'low' => 1,
        _ => 0,
      };

  /// Determines the color based on severity.
  Color _getSeverityColor(String severity, AppColorTheme colors) {
    return DisasterService.getSeverityColor(severity, colors);
  }

  /// Displays a snackbar with a message.
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  /// Reusable header decoration.
  BoxDecoration _headerDecoration(AppColorTheme colors) => BoxDecoration(
        color: colors.bg100,
        border: Border(
            bottom: BorderSide(color: colors.primary200.withOpacity(0.2))),
      );

  /// Reusable section decoration.
  BoxDecoration _sectionDecoration(AppColorTheme colors) => BoxDecoration(
        color: colors.bg100,
        border: Border(
            bottom: BorderSide(color: colors.primary200.withOpacity(0.2))),
      );

  /// Reusable card decoration.
  BoxDecoration _cardDecoration(AppColorTheme colors, Color severityColor) =>
      BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: severityColor, width: 4)),
      );

  /// Reusable label text style.
  TextStyle _labelStyle(AppColorTheme colors) => TextStyle(
        color: colors.accent200,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  /// Reusable dropdown decoration.
  BoxDecoration _dropdownDecoration(AppColorTheme colors) => BoxDecoration(
        color: colors.bg100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accent100),
      );

  /// Returns an icon based on the disaster type.
  IconData getDisasterIcon(String type) {
    return DisasterService.getDisasterIcon(type);
  }
}
