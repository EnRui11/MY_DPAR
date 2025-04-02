import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/services/disaster_information_service.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/fire_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/flood_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/landslide_guide_screen.dart';
import 'package:mydpar/screens/knowledge_base/prepareration_guide/heavy_rain_guide_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mydpar/localization/app_localizations.dart';

class DisasterDetailScreen extends StatefulWidget {
  final String disasterId;

  const DisasterDetailScreen({super.key, required this.disasterId});

  @override
  State<DisasterDetailScreen> createState() => _DisasterDetailScreenState();
}

class _DisasterDetailScreenState extends State<DisasterDetailScreen> {
  DisasterModel? _disaster;
  bool _isLoading = true;
  LatLng? _userLocation;
  String? _distanceText;

  @override
  void initState() {
    super.initState();
    _loadDisasterData();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _calculateDistance();
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadDisasterData() async {
    final disasterService =
        Provider.of<DisasterService>(context, listen: false);
    try {
      final disaster = await disasterService.getDisasterById(widget.disasterId);
      setState(() {
        _disaster = disaster;
        _isLoading = false;
        _calculateDistance();
      });
    } catch (e) {
      debugPrint('Error loading disaster: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateDistance() {
    if (_disaster?.coordinates != null && _userLocation != null) {
      final distance = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        _disaster!.coordinates!.latitude,
        _disaster!.coordinates!.longitude,
      );

      final localizations = AppLocalizations.of(context);

      setState(() {
        if (distance < 1000) {
          // Use localized format for distance
          _distanceText = localizations
              .translate('distance_away')
              .replaceAll('{distance}', (distance / 1000).toStringAsFixed(1));
        } else {
          _distanceText = localizations
              .translate('distance_away')
              .replaceAll('{distance}', (distance / 1000).toStringAsFixed(1));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.accent200))
          : _disaster == null
              ? Center(
                  child: Text(localizations.translate('error_loading_disaster'),
                      style: TextStyle(color: colors.text200)))
              : SafeArea(
                  child: Stack(
                    children: [
                      _buildContent(colors),
                      _buildGlassAppBar(colors),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGlassAppBar(AppColorTheme colors) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          border:
              Border(bottom: BorderSide(color: colors.bg300.withOpacity(0.2))),
          boxShadow: [
            BoxShadow(
              color: colors.bg300.withOpacity(0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.accent200),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              AppLocalizations.of(context).translate('disaster_details'),
              style: TextStyle(
                color: colors.accent200,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildContent(AppColorTheme colors) => SingleChildScrollView(
        padding:
            const EdgeInsets.only(top: 72, bottom: 24, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertHeader(colors),
            const SizedBox(height: 16),
            _buildLocationSection(colors),
            const SizedBox(height: 16),
            _buildDescriptionSection(colors),
            const SizedBox(height: 16),
            if (_disaster!.photoPaths?.isNotEmpty ?? false) ...[
              _buildPhotoSection(colors),
              const SizedBox(height: 24),
            ],
            _buildRelatedGuides(colors),
          ],
        ),
      );

  Widget _buildAlertHeader(AppColorTheme colors) {
    final localizations = AppLocalizations.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                DisasterService.getSeverityColor(_disaster!.severity, colors).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            DisasterService.getDisasterIcon(_disaster!.disasterType),
            color: DisasterService.getSeverityColor(_disaster!.severity, colors),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Translate disaster type
                localizations.translate(
                    'disaster_type_${_disaster!.disasterType.toLowerCase().replaceAll(' ', '_')}'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.text100,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DisasterService.getSeverityColor(
                          _disaster!.severity, colors),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      // Translate severity
                      localizations.translate(
                          'severity_${_disaster!.severity.toLowerCase()}'),
                      style: TextStyle(color: colors.bg100, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${_getLocalizedTimeAgo(context, DateTime.parse(_disaster!.timestamp))}',
                    style: TextStyle(color: colors.text200, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(AppColorTheme colors) => _buildGlassContainer(
        colors,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: colors.accent200, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('location'),
                  style: TextStyle(
                    color: colors.text100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_distanceText != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent200.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.accent200.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 14,
                          color: colors.accent200,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _distanceText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.accent200,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _disaster!.location,
              style: TextStyle(color: colors.text200),
            ),
            if (_disaster!.coordinates != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      center: _disaster!.coordinates,
                      zoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          // Disaster location marker
                          Marker(
                            point: _disaster!.coordinates!,
                            builder: (ctx) => Icon(
                              Icons.warning_amber_rounded,
                              color: DisasterService.getSeverityColor(
                                  _disaster!.severity, colors),
                              size: 40,
                            ),
                          ),
                          // User location marker (if available)
                          if (_userLocation != null)
                            Marker(
                              point: _userLocation!,
                              builder: (ctx) => Container(
                                decoration: BoxDecoration(
                                  color: colors.accent200.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.person_pin_circle,
                                    color: colors.accent200,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildDescriptionSection(AppColorTheme colors) => _buildGlassContainer(
        colors,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: colors.accent200, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('description'),
                  style: TextStyle(
                    color: colors.text100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _disaster!.description,
              style: TextStyle(color: colors.text200),
            ),
          ],
        ),
      );

  Widget _buildPhotoSection(AppColorTheme colors) => _buildGlassContainer(
        colors,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: colors.accent200, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('photos'),
                  style: TextStyle(
                    color: colors.text100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _disaster!.photoPaths!.length,
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _disaster!.photoPaths![index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildRelatedGuides(AppColorTheme colors) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('safety_tips'),
          style: TextStyle(
            color: colors.text100,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildGuideButton(
          colors,
          title:
              '${localizations.translate('disaster_type_${_disaster!.disasterType.toLowerCase().replaceAll(' ', '_')}')} ${localizations.translate('safety_tips')}',
          description:
              '${localizations.translate('learn_handle')} ${localizations.translate('disaster_type_${_disaster!.disasterType.toLowerCase().replaceAll(' ', '_')}')} ${localizations.translate('situations')}',
          icon: DisasterService.getDisasterIcon(_disaster!.disasterType),
          onTap: () => _navigateToGuide(context, _disaster!.disasterType),
        ),
      ],
    );
  }

  Widget _buildGuideButton(
    AppColorTheme colors, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bg100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.bg300.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accent200.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.accent200),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.text100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: colors.text200,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colors.accent200,
                size: 16,
              ),
            ],
          ),
        ),
      );

  void _navigateToGuide(BuildContext context, String disasterType) {
    final localizations = AppLocalizations.of(context);

    Widget? screen;
    switch (disasterType.toLowerCase()) {
      case 'fire':
        screen = FireGuideScreen();
        break;
      case 'flood':
        screen = FloodGuideScreen();
        break;
      case 'landslide':
        screen = LandslideGuideScreen();
        break;
      case 'heavy rain':
        screen = HeavyRainGuideScreen();
        break;
      // Add other disaster types as needed
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => screen!,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('safety_guide_not_available')),
        ),
      );
    }
  }

  Widget _buildGlassContainer(AppColorTheme colors, Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.bg300.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

String _getLocalizedTimeAgo(BuildContext context, DateTime timestamp) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 
          ? localizations.translate('time_year_ago')
          : localizations.translate('time_years_ago').replaceAll('{count}', years.toString());
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 
          ? localizations.translate('time_month_ago')
          : localizations.translate('time_months_ago').replaceAll('{count}', months.toString());
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 
          ? localizations.translate('time_day_ago')
          : localizations.translate('time_days_ago').replaceAll('{count}', difference.inDays.toString());
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 
          ? localizations.translate('time_hour_ago')
          : localizations.translate('time_hours_ago').replaceAll('{count}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 
          ? localizations.translate('time_minute_ago')
          : localizations.translate('time_minutes_ago').replaceAll('{count}', difference.inMinutes.toString());
    } else {
      return localizations.translate('time_just_now');
    }
  }
