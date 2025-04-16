import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/officer/screens/shelter_and_resource/shelter_detail_screen.dart';
import 'package:latlong2/latlong.dart';

class ShelterManagementScreen extends StatelessWidget {
  const ShelterManagementScreen({super.key});

  static const double _padding = 16.0;
  static const double _spacing = 24.0;

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
              child: _buildShelterList(context, colors), // Pass context here
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
              'Shelter Management',
              style: TextStyle(
                color: colors.primary300,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  // Update to accept BuildContext parameter
  Widget _buildShelterList(BuildContext context, AppColorTheme colors) => ListView(
        padding: const EdgeInsets.all(_padding),
        children: [
          _buildAddShelterButton(colors),
          const SizedBox(height: _spacing),
          _buildShelterCard(
            context, // Pass context here
            colors,
            name: 'Shelter A',
            location: 'Taman Meru, Block A',
            status: ShelterManagementStatus.available, // Use local enum
            currentCapacity: 120,
            totalCapacity: 200,
          ),
          const SizedBox(height: _spacing),
          _buildShelterCard(
            context, // Pass context here
            colors,
            name: 'Shelter B',
            location: 'Jalan Kebun, Shah Alam',
            status: ShelterManagementStatus.full, // Use local enum
            currentCapacity: 150,
            totalCapacity: 150,
          ),
          const SizedBox(height: _spacing),
          _buildShelterCard(
            context, // Pass context here
            colors,
            name: 'Shelter C',
            location: 'Bukit Jelutong',
            status: ShelterManagementStatus.nearFull, // Use local enum
            currentCapacity: 140,
            totalCapacity: 150,
          ),
        ],
      );

  Widget _buildAddShelterButton(AppColorTheme colors) => Container(
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
              // TODO: Implement add shelter functionality
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
                    'Add New Shelter',
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

  // Update to accept BuildContext parameter
  Widget _buildShelterCard(
    BuildContext context, // Add context parameter
    AppColorTheme colors, {
    required String name,
    required String location,
    required ShelterManagementStatus status, // Use local enum
    required int currentCapacity,
    required int totalCapacity,
  }) {
    final statusData = _getShelterStatusData(status, colors);
    final capacityPercentage = (currentCapacity / totalCapacity) * 100;

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
            // TODO: Navigate to shelter details
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
                  // TODO: Implement map view
                  child: const Center(
                    child: Text('Map View'),
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
                            'Capacity',
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
                      case ShelterManagementStatus.available:
                        detailStatus = ShelterStatus.available;
                        break;
                      case ShelterManagementStatus.nearFull:
                        detailStatus = ShelterStatus.nearFull;
                        break;
                      case ShelterManagementStatus.full:
                        detailStatus = ShelterStatus.full;
                        break;
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShelterDetailScreen(
                          name: name,
                          location: location,
                          status: detailStatus, // Use converted enum
                          currentCapacity: currentCapacity,
                          totalCapacity: totalCapacity,
                          coordinates: LatLng(3.1390, 101.6869),
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
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StatusData _getShelterStatusData(
      ShelterManagementStatus status, AppColorTheme colors) { // Update parameter type
    switch (status) {
      case ShelterManagementStatus.available: // Use local enum
        return _StatusData(
          color: colors.accent200,
          label: 'Available',
        );
      case ShelterManagementStatus.nearFull: // Use local enum
        return _StatusData(
          color: const Color(0xFFFF8C00),
          label: 'Near Full',
        );
      case ShelterManagementStatus.full: // Use local enum
        return _StatusData(
          color: colors.warning,
          label: 'Full',
        );
    }
  }
}

// Rename the enum to avoid conflict
enum ShelterManagementStatus {
  available,
  nearFull,
  full,
}

class _StatusData {
  final Color color;
  final String label;

  const _StatusData({
    required this.color,
    required this.label,
  });
}
