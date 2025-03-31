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

class AlertDetailScreen extends StatefulWidget {
  final String disasterId;

  const AlertDetailScreen({super.key, required this.disasterId});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  DisasterModel? _disaster;
  bool _isLoading = true;

  // Add at the top of the class
  LatLng? _userLocation;

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
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadDisasterData() async {
    final disasterService =
        Provider.of<DisasterService>(context, listen: false);
    final disaster = await disasterService.getDisasterById(widget.disasterId);
    setState(() {
      _disaster = disaster;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.accent200))
          : _disaster == null
              ? Center(
                  child: Text('Disaster not found',
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
              'Alert Details',
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

  Widget _buildAlertHeader(AppColorTheme colors) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getSeverityColor(_disaster!.severity, colors)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getDisasterIcon(_disaster!.disasterType),
              color: _getSeverityColor(_disaster!.severity, colors),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _disaster!.disasterType,
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
                        color: _getSeverityColor(_disaster!.severity, colors),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _disaster!.severity,
                        style: TextStyle(color: colors.bg100, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_disaster!.formattedTime}',
                      style: TextStyle(color: colors.text200, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

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
                  'Location',
                  style: TextStyle(
                    color: colors.text100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                              color: _getSeverityColor(
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
                  'Description',
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
                  'Photos',
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

  Widget _buildRelatedGuides(AppColorTheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preparation Guides',
            style: TextStyle(
              color: colors.text100,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildGuideButton(
            colors,
            title: '${_disaster!.disasterType} Safety Guide',
            description:
                'Learn how to handle ${_disaster!.disasterType.toLowerCase()} situations',
            icon: _getDisasterIcon(_disaster!.disasterType),
            onTap: () => _navigateToGuide(context, _disaster!.disasterType),
          ),
        ],
      );

  Widget _buildGlassContainer(AppColorTheme colors, Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        child: child,
      );

  Widget _buildGuideButton(
    AppColorTheme colors, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _buildGlassContainer(
          colors,
          Row(
            children: [
              Icon(icon, color: colors.accent200),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.text100,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                Icons.chevron_right,
                color: colors.accent200,
              ),
            ],
          ),
        ),
      );

  void _navigateToGuide(BuildContext context, String disasterType) {
    Widget? guide;
    switch (disasterType.toLowerCase()) {
      case 'fire':
        guide = const FireGuideScreen();
        break;
      case 'flood':
        guide = const FloodGuideScreen();
        break;
      case 'landslide':
        guide = const LandslideGuideScreen();
        break;
      case 'heavy rain':
        guide = const HeavyRainGuideScreen();
        break;
    }
    if (guide != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => guide!));
    }
  }

  IconData _getDisasterIcon(String type) {
    switch (type.toLowerCase()) {
      case 'heavy rain':
        return Icons.thunderstorm_outlined;
      case 'flood':
        return IconData(0xf07a3, fontFamily: 'MaterialIcons');
      case 'fire':
        return Icons.local_fire_department;
      case 'earthquake':
        return Icons.terrain;
      case 'landslide':
        return Icons.landslide;
      case 'haze':
        return Icons.air_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  // Update the severity color method
  Color _getSeverityColor(String severity, AppColorTheme colors) {
    switch (severity.toLowerCase()) {
      case 'high':
        return colors.warning;
      case 'medium':
        return const Color(0xFFFF8C00);
      case 'low':
        return const Color(0xFF71C4EF);
      default:
        return colors.accent200;
    }
  }
}
