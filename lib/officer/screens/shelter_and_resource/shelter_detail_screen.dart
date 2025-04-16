import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ShelterDetailScreen extends StatelessWidget {
  final String name;
  final String location;
  final ShelterStatus status;
  final int currentCapacity;
  final int totalCapacity;
  final LatLng coordinates;

  const ShelterDetailScreen({
    Key? key,
    required this.name,
    required this.location,
    required this.status,
    required this.currentCapacity,
    required this.totalCapacity,
    required this.coordinates,
  }) : super(key: key);

  static const double _padding = 16.0;
  static const double _spacing = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _cardRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final localize = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  children: [
                    _buildShelterInfoCard(colors),
                    const SizedBox(height: _spacing),
                    _buildDemographicsCard(colors),
                    const SizedBox(height: _spacing),
                    _buildResourceInventoryCard(colors),
                    const SizedBox(height: _spacing),
                    _buildHelpRequestsCard(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorTheme colors) => Container(
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
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.primary300),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: _spacingSmall),
            Text(
              name,
              style: TextStyle(
                color: colors.primary300,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildShelterInfoCard(AppColorTheme colors) => _buildCard(
        colors,
        title: 'Shelter Information',
        titleTrailing: _buildStatusBadge(colors),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location,
              style: TextStyle(
                color: colors.text200,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: _spacingSmall),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colors.bg200,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  center: coordinates,
                  zoom: 15,
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
          ],
        ),
      );

  Widget _buildDemographicsCard(AppColorTheme colors) => _buildCard(
        colors,
        title: 'Resident Demographics',
        titleTrailing: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Update',
            style: TextStyle(
              color: colors.accent200,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        content: Column(
          children: [
            _buildOccupancySection(colors),
            const SizedBox(height: _spacingSmall),
            _buildDemographicsGrid(colors),
          ],
        ),
      );

  Widget _buildOccupancySection(AppColorTheme colors) => Container(
        padding: const EdgeInsets.all(_padding),
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
                  'Total Occupancy',
                  style: TextStyle(
                    color: colors.text200,
                    fontSize: 14,
                  ),
                ),
                _buildCapacityBadge(colors),
              ],
            ),
            const SizedBox(height: _spacingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '$currentCapacity',
                      style: TextStyle(
                        color: _getCapacityColor(colors),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'residents',
                      style: TextStyle(
                        color: colors.text200,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(currentCapacity / totalCapacity * 100).toInt()}%',
                      style: TextStyle(
                        color: _getCapacityColor(colors),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'of $totalCapacity capacity',
                      style: TextStyle(
                        color: colors.text200,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: _spacingSmall),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: currentCapacity / totalCapacity,
                backgroundColor: colors.primary100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCapacityColor(colors),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );

  Widget _buildDemographicsGrid(AppColorTheme colors) => Container(
        padding: const EdgeInsets.only(top: _spacingSmall),
        child: Row(
          children: [
            Expanded(
              child: _buildDemographicItem('Elderly', '20', colors),
            ),
            Expanded(
              child: _buildDemographicItem('Adults', '85', colors),
            ),
            Expanded(
              child: _buildDemographicItem('Children', '35', colors),
            ),
          ],
        ),
      );

  Widget _buildDemographicItem(
          String label, String count, AppColorTheme colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.text200,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              color: colors.accent200,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _buildResourceInventoryCard(AppColorTheme colors) => _buildCard(
        colors,
        title: 'Resource Inventory',
        content: Column(
          children: [
            _buildResourceItem(
              colors,
              icon: Icons.restaurant,
              title: 'Food Supplies',
              description:
                  'Basic food supplies including rice, canned goods, and dry foods',
              currentStock: 75,
              minRequired: 50,
              status: ResourceStatus.medium,
            ),
            const SizedBox(height: _spacingSmall),
            _buildResourceItem(
              colors,
              icon: Icons.local_drink,
              title: 'Water Supplies',
              description: 'Clean drinking water in bottles and containers',
              currentStock: 120,
              minRequired: 100,
              status: ResourceStatus.good,
            ),
            const SizedBox(height: _spacingSmall),
            _buildResourceItem(
              colors,
              icon: Icons.medical_services,
              title: 'Medical Supplies',
              description:
                  'First aid kits, medications, and basic medical equipment',
              currentStock: 30,
              minRequired: 50,
              status: ResourceStatus.low,
            ),
            const SizedBox(height: _spacing),
            _buildResourceActionButtons(colors),
          ],
        ),
      );

  Widget _buildResourceItem(
    AppColorTheme colors, {
    required IconData icon,
    required String title,
    required String description,
    required int currentStock,
    required int minRequired,
    required ResourceStatus status,
  }) {
    final statusData = _getResourceStatusData(status, colors);
    final surplus = currentStock - minRequired;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: colors.bg200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: colors.accent200, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.primary300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: colors.text200,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Stock: $currentStock units',
                style: TextStyle(
                  color: colors.text200,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Update Stock',
                  style: TextStyle(
                    color: colors.accent200,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minimum Required: $minRequired units',
                style: TextStyle(
                  color: statusData.color,
                  fontSize: 12,
                ),
              ),
              Text(
                surplus >= 0 ? '+$surplus units' : '$surplus units',
                style: TextStyle(
                  color: statusData.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add this new section for help requests
  Widget _buildHelpRequestsCard(AppColorTheme colors) => _buildCard(
        colors,
        title: 'Help Requests',
        titleTrailing: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View All',
            style: TextStyle(
              color: colors.accent200,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        content: Column(
          children: [
            _buildHelpRequestItem(
              colors,
              icon: Icons.medical_services,
              title: 'Medical Assistance',
              description: 'Need additional medical supplies and personnel',
              requestDate: 'May 15, 2023',
            ),
            const SizedBox(height: _spacingSmall),
            _buildHelpRequestItem(
              colors,
              icon: Icons.people,
              title: 'Volunteer Support',
              description: 'Requesting volunteers for food distribution',
              requestDate: 'May 12, 2023',
            ),
            const SizedBox(height: _spacing),
            // Wrap the button in a SizedBox with a defined height
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Create New Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent200,
                  foregroundColor: colors.bg100,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildHelpRequestItem(
    AppColorTheme colors, {
    required IconData icon,
    required String title,
    required String description,
    required String requestDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: colors.bg200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accent200, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.primary300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: colors.text200,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: colors.text200, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Requested on: $requestDate',
                    style: TextStyle(
                      color: colors.text200,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: colors.accent200,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceActionButtons(AppColorTheme colors) => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Add Resource'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildCard(
    AppColorTheme colors, {
    required String title,
    required Widget content,
    Widget? titleTrailing,
  }) =>
      Container(
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: colors.bg100.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.primary300,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (titleTrailing != null) titleTrailing,
              ],
            ),
            const SizedBox(height: _spacingSmall),
            content,
          ],
        ),
      );

  Widget _buildStatusBadge(AppColorTheme colors) {
    final statusData = _getShelterStatusData(status, colors);
    return Container(
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
    );
  }

  Widget _buildCapacityBadge(AppColorTheme colors) {
    final capacityPercentage = (currentCapacity / totalCapacity) * 100;
    String label;
    Color color;

    if (capacityPercentage < 50) {
      label = 'Low Capacity';
      color = colors.accent200;
    } else if (capacityPercentage < 80) {
      label = 'Medium Capacity';
      color = const Color(0xFFFF8C00); // Orange
    } else {
      label = 'High Capacity';
      color = const Color(0xFFFF8C00); // Orange
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getCapacityColor(AppColorTheme colors) {
    final capacityPercentage = (currentCapacity / totalCapacity) * 100;
    if (capacityPercentage < 50) {
      return colors.accent200;
    } else if (capacityPercentage < 80) {
      return const Color(0xFFFF8C00); // Orange
    } else {
      return const Color(0xFFFF8C00); // Orange
    }
  }

  _StatusData _getShelterStatusData(
      ShelterStatus status, AppColorTheme colors) {
    switch (status) {
      case ShelterStatus.available:
        return _StatusData(
          color: colors.accent200,
          label: 'Available',
        );
      case ShelterStatus.nearFull:
        return _StatusData(
          color: const Color(0xFFFF8C00), // Orange
          label: 'Near Full',
        );
      case ShelterStatus.full:
        return _StatusData(
          color: colors.warning,
          label: 'Full',
        );
    }
  }

  _StatusData _getResourceStatusData(
      ResourceStatus status, AppColorTheme colors) {
    switch (status) {
      case ResourceStatus.good:
        return _StatusData(
          color: colors.accent200,
          label: 'Good',
        );
      case ResourceStatus.medium:
        return _StatusData(
          color: const Color(0xFFFF8C00), // Orange
          label: 'Medium',
        );
      case ResourceStatus.low:
        return _StatusData(
          color: colors.warning,
          label: 'Low',
        );
    }
  }
}

enum ShelterStatus {
  available,
  nearFull,
  full,
}

enum ResourceStatus {
  good,
  medium,
  low,
}

class _StatusData {
  final Color color;
  final String label;

  const _StatusData({
    required this.color,
    required this.label,
  });
}
