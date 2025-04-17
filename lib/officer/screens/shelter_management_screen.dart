import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/officer/screens/shelter_and_resource/shelter_detail_screen.dart';
import 'package:mydpar/officer/screens/shelter_and_resource/add_shelter_screen.dart';
import 'package:mydpar/officer/service/shelter_and_resource_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class ShelterManagementScreen extends StatefulWidget {
  const ShelterManagementScreen({super.key});

  @override
  State<ShelterManagementScreen> createState() =>
      _ShelterManagementScreenState();
}

class _ShelterManagementScreenState extends State<ShelterManagementScreen> {
  static const double _padding = 16.0;
  static const double _spacing = 24.0;
  final ShelterService _shelterService = ShelterService();

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
            Expanded(
              child: _buildShelterList(context, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: colors.bg100,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context).translate('shelter_management'),
              style: TextStyle(
                color: colors.primary300,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildShelterList(BuildContext context, AppColorTheme colors) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _shelterService.getAllShelters(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)
                    .translate('error_loading_shelters'),
                style: TextStyle(color: colors.warning),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shelters = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(_padding),
            itemCount: shelters.length + 1, // +1 for the add button
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildAddShelterButton(context, colors),
                    const SizedBox(height: _spacing),
                  ],
                );
              }

              final shelter = shelters[index - 1];
              return Column(
                children: [
                  _buildShelterCard(
                    context,
                    colors,
                    id: shelter['id'],
                    name: shelter['name'],
                    location: shelter['locationName'],
                    status: _getShelterStatus(
                      shelter['currentOccupancy'],
                      shelter['capacity'],
                      shelter['status'],
                    ),
                    currentCapacity: shelter['currentOccupancy'],
                    totalCapacity: shelter['capacity'],
                    coordinates: shelter['location'] as LatLng,
                  ),
                  const SizedBox(height: _spacing),
                ],
              );
            },
          );
        },
      );

  Widget _buildAddShelterButton(BuildContext context, AppColorTheme colors) =>
      Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.bg100.withOpacity(0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddShelterScreen(),
                ),
              );
              if (result == true) {}
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: colors.accent200,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).translate('add_new_shelter'),
                    style: TextStyle(
                      color: colors.accent200,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildShelterCard(
    BuildContext context,
    AppColorTheme colors, {
    required String id,
    required String name,
    required String location,
    required ShelterManagementStatus status,
    required int currentCapacity,
    required int totalCapacity,
    required LatLng coordinates,
  }) {
    final statusData = _getShelterStatusData(status, colors);

    return Container(
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.bg100.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Convert local enum to ShelterDetailScreen enum
            ShelterStatus detailStatus;
            switch (status) {
              case ShelterManagementStatus.preparation:
                detailStatus = ShelterStatus.preparation;
                break;
              case ShelterManagementStatus.lowCapacity:
                detailStatus = ShelterStatus.lowCapacity;
                break;
              case ShelterManagementStatus.mediumCapacity:
                detailStatus = ShelterStatus.mediumCapacity;
                break;
              case ShelterManagementStatus.highCapacity:
                detailStatus = ShelterStatus.highCapacity;
                break;
              case ShelterManagementStatus.full:
                detailStatus = ShelterStatus.full;
                break;
              case ShelterManagementStatus.overCapacity:
                detailStatus = ShelterStatus.overCapacity;
                break;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShelterDetailScreen(
                  id: id,
                  name: name,
                  location: location,
                  status: detailStatus,
                  currentCapacity: currentCapacity,
                  totalCapacity: totalCapacity,
                  coordinates: coordinates,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: colors.primary300,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusData.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusData.label,
                        style: TextStyle(
                          color: statusData.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  location,
                  style: TextStyle(
                    color: colors.text200,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: colors.bg200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    options: MapOptions(
                      center: coordinates,
                      zoom: 15,
                      interactiveFlags: InteractiveFlag.none,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: coordinates,
                            builder: (ctx) => const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bg200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('Capacity'),
                            style: TextStyle(
                              color: colors.text200,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$currentCapacity/$totalCapacity',
                            style: TextStyle(
                              color: statusData.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: currentCapacity / totalCapacity,
                          backgroundColor: colors.primary100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusData.color,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Convert local enum to ShelterDetailScreen enum
                    ShelterStatus detailStatus;
                    switch (status) {
                      case ShelterManagementStatus.preparation:
                        detailStatus = ShelterStatus.preparation;
                        break;
                      case ShelterManagementStatus.lowCapacity:
                        detailStatus = ShelterStatus.lowCapacity;
                        break;
                      case ShelterManagementStatus.mediumCapacity:
                        detailStatus = ShelterStatus.mediumCapacity;
                        break;
                      case ShelterManagementStatus.highCapacity:
                        detailStatus = ShelterStatus.highCapacity;
                        break;
                      case ShelterManagementStatus.full:
                        detailStatus = ShelterStatus.full;
                        break;
                      case ShelterManagementStatus.overCapacity:
                        detailStatus = ShelterStatus.overCapacity;
                        break;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShelterDetailScreen(
                          id: id,
                          name: name,
                          location: location,
                          status: detailStatus,
                          currentCapacity: currentCapacity,
                          totalCapacity: totalCapacity,
                          coordinates: coordinates,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent200,
                    foregroundColor: colors.bg100,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                      AppLocalizations.of(context).translate('view_details')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ShelterManagementStatus _getShelterStatus(
      int currentOccupancy, int capacity, String status) {
    // First check if the shelter is under preparation
    if (status == 'preparation') {
      return ShelterManagementStatus.preparation;
    }

    // If not under preparation, calculate based on capacity
    if (capacity == 0) return ShelterManagementStatus.lowCapacity;

    final percentage = (currentOccupancy / capacity) * 100;

    if (percentage > 100) {
      return ShelterManagementStatus.overCapacity;
    } else if (percentage == 100) {
      return ShelterManagementStatus.full;
    } else if (percentage >= 80) {
      return ShelterManagementStatus.highCapacity;
    } else if (percentage >= 50) {
      return ShelterManagementStatus.mediumCapacity;
    } else {
      return ShelterManagementStatus.lowCapacity;
    }
  }

  _StatusData _getShelterStatusData(
      ShelterManagementStatus status, AppColorTheme colors) {
    switch (status) {
      case ShelterManagementStatus.preparation:
        return _StatusData(
          color: Colors.blue,
          label: AppLocalizations.of(context).translate('preparation'),
        );
      case ShelterManagementStatus.lowCapacity:
        return _StatusData(
          color: Colors.green,
          label: AppLocalizations.of(context).translate('low_capacity'),
        );
      case ShelterManagementStatus.mediumCapacity:
        return _StatusData(
          color: Colors.yellow,
          label: AppLocalizations.of(context).translate('medium_capacity'),
        );
      case ShelterManagementStatus.highCapacity:
        return _StatusData(
          color: Colors.orange,
          label: AppLocalizations.of(context).translate('high_capacity'),
        );
      case ShelterManagementStatus.full:
        return _StatusData(
          color: Colors.red,
          label: AppLocalizations.of(context).translate('full'),
        );
      case ShelterManagementStatus.overCapacity:
        return _StatusData(
          color: Colors.purple,
          label: AppLocalizations.of(context).translate('over_capacity'),
        );
    }
  }
}

enum ShelterManagementStatus {
  preparation,
  lowCapacity,
  mediumCapacity,
  highCapacity,
  full,
  overCapacity,
}

class _StatusData {
  final Color color;
  final String label;

  const _StatusData({
    required this.color,
    required this.label,
  });
}
