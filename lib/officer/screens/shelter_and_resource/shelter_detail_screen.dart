import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/officer/service/shelter_and_resource_service.dart';

/// Screen for viewing and managing shelter details, including demographics, resources, and help requests.
class ShelterDetailScreen extends StatefulWidget {
  final String id;
  final String name;
  final String location;
  final ShelterStatus status;
  final int currentCapacity;
  final int totalCapacity;
  final LatLng coordinates;

  const ShelterDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.currentCapacity,
    required this.totalCapacity,
    required this.coordinates,
  });

  @override
  State<ShelterDetailScreen> createState() => _ShelterDetailScreenState();
}

class _ShelterDetailScreenState extends State<ShelterDetailScreen> {
  final ShelterService _shelterService = ShelterService();
  Map<String, int> _demographics = {'elderly': 0, 'adults': 0, 'children': 0};
  late int _currentCapacity;
  late ShelterStatus _currentStatus;
  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _helpRequests = [];

  // UI constants
  static const double _padding = 16.0;
  static const double _spacing = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _cardRadius = 16.0;

  @override
  void initState() {
    super.initState();
    _currentCapacity = widget.currentCapacity;
    _currentStatus = widget.status;
    _loadDemographics();
    _loadResources();
    _loadHelpRequests();
  }

  /// Loads shelter demographics from the service.
  Future<void> _loadDemographics() async {
    try {
      final shelter = await _shelterService.getShelter(widget.id);
      if (shelter != null && shelter['demographics'] != null) {
        setState(() {
          _demographics = Map<String, int>.from(shelter['demographics']);
        });
      }
    } catch (e) {
      _showErrorSnackBar(
          AppLocalizations.of(context).translate('error_loading_demographics'),
          e);
      debugPrint('Error loading demographics: $e');
    }
  }

  /// Subscribes to real-time updates for shelter resources.
  void _loadResources() {
    _shelterService.getShelterResources(widget.id).listen(
      (resources) => setState(() => _resources = resources),
      onError: (e) {
        _showErrorSnackBar(
            AppLocalizations.of(context).translate('error_loading_resources'),
            e);
        debugPrint('Error loading resources: $e');
      },
    );
  }

  /// Subscribes to real-time updates for help requests.
  void _loadHelpRequests() {
    _shelterService.getHelpRequests(widget.id).listen(
      (requests) => setState(() => _helpRequests = requests),
      onError: (e) {
        _showErrorSnackBar(
            AppLocalizations.of(context)
                .translate('error_loading_help_requests'),
            e);
        debugPrint('Error loading help requests: $e');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Provider.of<ThemeProvider>(context, listen: true).currentTheme;
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, localizations),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  children: [
                    _buildShelterLocationCard(colors, localizations),
                    const SizedBox(height: _spacing),
                    _buildDemographicsCard(colors, localizations),
                    const SizedBox(height: _spacing),
                    _buildResourceInventoryCard(colors, localizations),
                    const SizedBox(height: _spacing),
                    _buildHelpRequestsCard(colors, localizations),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header with back button and shelter name.
  Widget _buildHeader(AppColorTheme colors, AppLocalizations localizations) =>
      Container(
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
              widget.name,
              style: TextStyle(
                color: colors.primary300,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  /// Builds the card showing shelter location and map.
  Widget _buildShelterLocationCard(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildCard(
        colors,
        title: localizations.translate('shelter_location'),
        titleTrailing: Row(
          children: [
            _buildStatusBadge(colors, localizations),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.edit, color: colors.accent200, size: 16),
              onPressed: () =>
                  _showEditStatusDialog(context, colors, localizations),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.location,
              style: TextStyle(color: colors.text200, fontSize: 14),
            ),
            const SizedBox(height: _spacingSmall),
            _buildMap(colors),
          ],
        ),
      );

  /// Builds the map showing the shelter's coordinates.
  Widget _buildMap(AppColorTheme colors) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: colors.bg200,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          options: MapOptions(center: widget.coordinates, zoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: widget.coordinates,
                  builder: (_) => const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      );

  /// Builds the demographics card with occupancy and demographic details.
  Widget _buildDemographicsCard(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildCard(
        colors,
        title: localizations.translate('resident_demographics'),
        titleTrailing: TextButton(
          onPressed: () {
            if (_currentStatus == ShelterStatus.available) {
              _showEditDemographicsDialog(context, colors, localizations);
            } else {
              _showSnackBar(
                localizations.translate('cannot_edit_demographics'),
                backgroundColor: colors.warning,
              );
            }
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            localizations.translate('update'),
            style: TextStyle(
              color: _currentStatus == ShelterStatus.available
                  ? colors.accent200
                  : colors.text200,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        content: Column(
          children: [
            _buildOccupancySection(colors, localizations),
            const SizedBox(height: _spacingSmall),
            _buildDemographicsGrid(colors, localizations),
          ],
        ),
      );

  /// Builds the occupancy section with capacity details.
  Widget _buildOccupancySection(
          AppColorTheme colors, AppLocalizations localizations) =>
      Container(
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
                  localizations.translate('total_occupancy'),
                  style: TextStyle(color: colors.text200, fontSize: 14),
                ),
                _buildCapacityBadge(colors, localizations),
              ],
            ),
            const SizedBox(height: _spacingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '$_currentCapacity',
                      style: TextStyle(
                        color: _getCapacityColor(colors),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      localizations.translate('residents'),
                      style: TextStyle(color: colors.text200, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${((_currentCapacity / widget.totalCapacity) * 100).toInt()}%',
                      style: TextStyle(
                        color: _getCapacityColor(colors),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${localizations.translate('of')} ${widget.totalCapacity} ${localizations.translate('capacity')}',
                      style: TextStyle(color: colors.text200, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: _spacingSmall),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _currentCapacity / widget.totalCapacity,
                backgroundColor: colors.primary100,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_getCapacityColor(colors)),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );

  /// Builds the grid displaying demographic counts.
  Widget _buildDemographicsGrid(
          AppColorTheme colors, AppLocalizations localizations) =>
      Container(
        padding: const EdgeInsets.only(top: _spacingSmall),
        child: Row(
          children: [
            Expanded(
              child: _buildDemographicItem(
                localizations.translate('elderly'),
                _demographics['elderly']?.toString() ?? '0',
                colors,
              ),
            ),
            Expanded(
              child: _buildDemographicItem(
                localizations.translate('adults'),
                _demographics['adults']?.toString() ?? '0',
                colors,
              ),
            ),
            Expanded(
              child: _buildDemographicItem(
                localizations.translate('children'),
                _demographics['children']?.toString() ?? '0',
                colors,
              ),
            ),
          ],
        ),
      );

  /// Builds a single demographic item with label and count.
  Widget _buildDemographicItem(
          String label, String count, AppColorTheme colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.text200, fontSize: 14),
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

  /// Builds the resource inventory card with resource items and actions.
  Widget _buildResourceInventoryCard(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildCard(
        colors,
        title: localizations.translate('resource_inventory'),
        content: Column(
          children: [
            ..._resources.map((resource) {
              final currentStock = resource['currentStock'] as int;
              final minThreshold = resource['minThreshold'] as int;
              final status = currentStock < minThreshold
                  ? ResourceStatus.low
                  : currentStock < minThreshold * 1.5
                      ? ResourceStatus.medium
                      : ResourceStatus.good;
              return Column(
                children: [
                  _buildResourceItem(
                    colors,
                    localizations,
                    icon: _getResourceIcon(resource['type']),
                    title: _getResourceTitle(resource['type'], localizations),
                    description: resource['description'],
                    currentStock: currentStock,
                    minRequired: minThreshold,
                    status: status,
                    onUpdateStock: () => _showUpdateStockDialog(context, colors,
                        localizations, resource['id'], resource),
                    onDelete: () => _showDeleteResourceDialog(
                        context, colors, localizations, resource['id']),
                  ),
                  const SizedBox(height: _spacingSmall),
                ],
              );
            }),
            const SizedBox(height: _spacingSmall),
            _buildResourceActionButtons(colors, localizations),
          ],
        ),
      );

  /// Builds a single resource item with details and actions.
  Widget _buildResourceItem(
    AppColorTheme colors,
    AppLocalizations localizations, {
    required IconData icon,
    required String title,
    required String description,
    required int currentStock,
    required int minRequired,
    required ResourceStatus status,
    required VoidCallback onUpdateStock,
    required VoidCallback onDelete,
  }) {
    final statusData = _getResourceStatusData(status, colors, localizations);
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
                        color: colors.primary300, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete, color: colors.warning, size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: colors.text200, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${localizations.translate('current_stock')}: $currentStock ${localizations.translate('units')}',
                style: TextStyle(color: colors.text200, fontSize: 14),
              ),
              TextButton(
                onPressed: onUpdateStock,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.bg100,
                    border: Border.all(color: colors.primary300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    localizations.translate('edit_stock'),
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${localizations.translate('minimum_required')}: $minRequired ${localizations.translate('units')}',
                style: TextStyle(color: statusData.color, fontSize: 12),
              ),
              Text(
                surplus >= 0
                    ? '+$surplus ${localizations.translate('units')}'
                    : '$surplus ${localizations.translate('units')}',
                style: TextStyle(color: statusData.color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds action buttons for adding resources.
  Widget _buildResourceActionButtons(
          AppColorTheme colors, AppLocalizations localizations) =>
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showAddResourceDialog(context, colors, localizations),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text(localizations.translate('add_resource')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent200,
                foregroundColor: colors.bg100,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );

  /// Builds the help requests card with request items and actions.
  Widget _buildHelpRequestsCard(
          AppColorTheme colors, AppLocalizations localizations) =>
      _buildCard(
        colors,
        title: localizations.translate('help_requests'),
        content: Column(
          children: [
            ..._helpRequests.map((request) => Column(
                  children: [
                    _buildHelpRequestItem(
                      colors,
                      localizations,
                      icon: _getHelpRequestIcon(request['type']),
                      title:
                          _getHelpRequestTitle(request['type'], localizations),
                      description: request['description'],
                      status: request['status'],
                      requestDate: _formatDate(request['createdAt']),
                      onUpdate: () => _showUpdateHelpRequestDialog(
                          context, colors, localizations, request),
                      onDelete: () => _showDeleteHelpRequestDialog(
                          context, colors, localizations, request['id']),
                    ),
                    const SizedBox(height: _spacingSmall),
                  ],
                )),
            const SizedBox(height: _spacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAddHelpRequestDialog(context, colors, localizations),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: Text(localizations.translate('create_new_request')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent200,
                  foregroundColor: colors.bg100,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );

  /// Builds a single help request item with details and actions.
  Widget _buildHelpRequestItem(
    AppColorTheme colors,
    AppLocalizations localizations, {
    required IconData icon,
    required String title,
    required String description,
    required String status,
    required String requestDate,
    required VoidCallback onUpdate,
    required VoidCallback onDelete,
  }) {
    final statusData = _getResourceStatusData(
      status == 'pending'
          ? ResourceStatus.low
          : status == 'in_progress'
              ? ResourceStatus.medium
              : ResourceStatus.good,
      colors,
      localizations,
    );
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
                        color: colors.primary300, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete, color: colors.warning, size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: colors.text200, fontSize: 12),
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
                    '${localizations.translate('requested_on')}: $requestDate',
                    style: TextStyle(color: colors.text200, fontSize: 12),
                  ),
                ],
              ),
              TextButton(
                onPressed: onUpdate,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.bg100,
                    border: Border.all(color: colors.primary300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    localizations.translate('edit_request'),
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a card with a title and content.
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
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
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

  /// Builds the status badge for the shelter.
  Widget _buildStatusBadge(
      AppColorTheme colors, AppLocalizations localizations) {
    final status = _currentStatus == ShelterStatus.preparation
        ? ShelterStatus.preparation
        : ShelterStatus.available;
    final statusData = _getShelterStatusData(status, colors, localizations);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  /// Builds the capacity badge based on occupancy percentage.
  Widget _buildCapacityBadge(
      AppColorTheme colors, AppLocalizations localizations) {
    final capacityPercentage = (_currentCapacity / widget.totalCapacity) * 100;
    final (label, color) = switch (capacityPercentage) {
      < 50 => (localizations.translate('low_capacity'), Colors.green),
      < 80 => (localizations.translate('medium_capacity'), Colors.yellow),
      < 100 => (localizations.translate('high_capacity'), Colors.orange),
      100 => (localizations.translate('full'), Colors.red),
      _ => (localizations.translate('over_capacity'), Colors.purple),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  /// Determines the color for capacity indicators.
  Color _getCapacityColor(AppColorTheme colors) {
    final capacityPercentage = (_currentCapacity / widget.totalCapacity) * 100;
    return switch (capacityPercentage) {
      < 50 => Colors.green,
      < 80 => Colors.yellow,
      < 100 => Colors.orange,
      100 => Colors.red,
      _ => Colors.purple,
    };
  }

  /// Returns status data for shelter status.
  _StatusData _getShelterStatusData(ShelterStatus status, AppColorTheme colors,
          AppLocalizations localizations) =>
      switch (status) {
        ShelterStatus.preparation => _StatusData(
            color: Colors.blue,
            label: localizations.translate('preparation'),
          ),
        ShelterStatus.available => _StatusData(
            color: Colors.teal,
            label: localizations.translate('available'),
          ),
        ShelterStatus.lowCapacity => _StatusData(
            color: Colors.green,
            label: localizations.translate('low_capacity'),
          ),
        ShelterStatus.mediumCapacity => _StatusData(
            color: Colors.yellow,
            label: localizations.translate('medium_capacity'),
          ),
        ShelterStatus.highCapacity => _StatusData(
            color: Colors.orange,
            label: localizations.translate('high_capacity'),
          ),
        ShelterStatus.full => _StatusData(
            color: Colors.red,
            label: localizations.translate('full'),
          ),
        ShelterStatus.overCapacity => _StatusData(
            color: Colors.purple,
            label: localizations.translate('over_capacity'),
          ),
      };

  /// Returns status data for resource status.
  _StatusData _getResourceStatusData(ResourceStatus status,
      AppColorTheme colors, AppLocalizations localizations) {
    return switch (status) {
      ResourceStatus.good => _StatusData(
          color: colors.accent200,
          label: localizations.translate('good'),
        ),
      ResourceStatus.medium => _StatusData(
          color: const Color(0xFFFF8C00),
          label: localizations.translate('good'),
        ),
      ResourceStatus.low => _StatusData(
          color: colors.warning,
          label: localizations.translate('low'),
        ),
    };
  }

  /// Shows dialog to edit shelter demographics.
  void _showEditDemographicsDialog(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations) {
    int elderlyCount = _demographics['elderly'] ?? 0;
    int adultsCount = _demographics['adults'] ?? 0;
    int childrenCount = _demographics['children'] ?? 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations.translate('edit_demographics')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditDemographicField(
              label: localizations.translate('elderly'),
              initialValue: elderlyCount.toString(),
              onChanged: (value) =>
                  elderlyCount = int.tryParse(value) ?? elderlyCount,
              colors: colors,
            ),
            _buildEditDemographicField(
              label: localizations.translate('adults'),
              initialValue: adultsCount.toString(),
              onChanged: (value) =>
                  adultsCount = int.tryParse(value) ?? adultsCount,
              colors: colors,
            ),
            _buildEditDemographicField(
              label: localizations.translate('children'),
              initialValue: childrenCount.toString(),
              onChanged: (value) =>
                  childrenCount = int.tryParse(value) ?? childrenCount,
              colors: colors,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => _saveDemographics(elderlyCount, adultsCount,
                childrenCount, colors, localizations),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves updated demographics and updates capacity status.
  Future<void> _saveDemographics(
      int elderlyCount,
      int adultsCount,
      int childrenCount,
      AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      final newCapacity = elderlyCount + adultsCount + childrenCount;
      await _shelterService.updateDemographics(
        shelterId: widget.id,
        elderlyCount: elderlyCount,
        adultsCount: adultsCount,
        childrenCount: childrenCount,
      );
      setState(() {
        _demographics = {
          'elderly': elderlyCount,
          'adults': adultsCount,
          'children': childrenCount,
        };
        _currentCapacity = newCapacity;
        _currentStatus = _getShelterStatus(newCapacity, widget.totalCapacity);
      });
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('demographics_updated'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(localizations.translate('update_failed'), e);
      }
    }
  }

  /// Builds a text field for editing demographic counts.
  Widget _buildEditDemographicField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    required AppColorTheme colors,
  }) =>
      TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.text100),
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      );

  /// Shows dialog to add a new resource.
  void _showAddResourceDialog(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations) {
    final typeController = TextEditingController(text: 'food');
    final descriptionController = TextEditingController();
    final currentStockController = TextEditingController();
    final minThresholdController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations.translate('add_resource')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeController.text,
                decoration: InputDecoration(
                  labelText: localizations.translate('resource_type'),
                  labelStyle: TextStyle(color: colors.text100),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'food',
                    child: Text(localizations.translate('resource_type_food')),
                  ),
                  DropdownMenuItem(
                    value: 'water',
                    child: Text(localizations.translate('resource_type_water')),
                  ),
                  DropdownMenuItem(
                    value: 'medical',
                    child:
                        Text(localizations.translate('resource_type_medical')),
                  ),
                  DropdownMenuItem(
                    value: 'others',
                    child:
                        Text(localizations.translate('resource_type_others')),
                  ),
                ],
                onChanged: (value) => typeController.text = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('resource_description'),
                  labelStyle: TextStyle(color: colors.text100),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: currentStockController,
                decoration: InputDecoration(
                  labelText: localizations.translate('current_stock'),
                  labelStyle: TextStyle(color: colors.text100),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: minThresholdController,
                decoration: InputDecoration(
                  labelText: localizations.translate('min_threshold'),
                  labelStyle: TextStyle(color: colors.text100),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => _saveNewResource(
                typeController,
                descriptionController,
                currentStockController,
                minThresholdController,
                colors,
                localizations),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves a new resource to the shelter.
  Future<void> _saveNewResource(
      TextEditingController typeController,
      TextEditingController descriptionController,
      TextEditingController currentStockController,
      TextEditingController minThresholdController,
      AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      await _shelterService.addResource(
        shelterId: widget.id,
        type: typeController.text,
        description: descriptionController.text,
        currentStock: int.parse(currentStockController.text),
        minThreshold: int.parse(minThresholdController.text),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('resource_added'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(localizations.translate('update_failed'), e);
      }
    }
  }

  /// Shows dialog to update resource stock.
  void _showUpdateStockDialog(
      BuildContext context,
      AppColorTheme colors,
      AppLocalizations localizations,
      String resourceId,
      Map<String, dynamic> resource) {
    final stockController =
        TextEditingController(text: resource['currentStock'].toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations.translate('edit_stock')),
        content: TextFormField(
          controller: stockController,
          decoration: InputDecoration(
            labelText: localizations.translate('current_stock'),
            labelStyle: TextStyle(color: colors.text100),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => _saveResourceStock(
                resourceId, stockController, colors, localizations),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves updated resource stock.
  Future<void> _saveResourceStock(
      String resourceId,
      TextEditingController stockController,
      AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      await _shelterService.updateResourceStock(
        widget.id,
        resourceId,
        int.parse(stockController.text),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('stock_updated'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(localizations.translate('update_failed'), e);
      }
    }
  }

  /// Shows dialog to confirm resource deletion.
  void _showDeleteResourceDialog(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations, String resourceId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations.translate('delete_resource')),
        content: Text(localizations.translate('delete_resource_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => _deleteResource(resourceId, colors, localizations),
            style: ElevatedButton.styleFrom(backgroundColor: colors.warning),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );
  }

  /// Deletes a resource from the shelter.
  Future<void> _deleteResource(String resourceId, AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      await _shelterService.deleteResource(widget.id, resourceId);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('resource_deleted'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(localizations.translate('delete_failed'), e);
      }
    }
  }

  /// Shows dialog to add a new help request.
  void _showAddHelpRequestDialog(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations) {
    final typeController = TextEditingController(text: 'food');
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations.translate('add_help_request')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeController.text,
                decoration: InputDecoration(
                  labelText: localizations.translate('resource_type'),
                  labelStyle: TextStyle(color: colors.text100),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'food',
                    child: Text(localizations.translate('resource_type_food')),
                  ),
                  DropdownMenuItem(
                    value: 'water',
                    child: Text(localizations.translate('resource_type_water')),
                  ),
                  DropdownMenuItem(
                    value: 'medical',
                    child:
                        Text(localizations.translate('resource_type_medical')),
                  ),
                  DropdownMenuItem(
                    value: 'others',
                    child:
                        Text(localizations.translate('resource_type_others')),
                  ),
                ],
                onChanged: (value) => typeController.text = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('request_description'),
                  labelStyle: TextStyle(color: colors.text100),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => _saveHelpRequest(
                typeController, descriptionController, colors, localizations),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves a new help request.
  Future<void> _saveHelpRequest(
      TextEditingController typeController,
      TextEditingController descriptionController,
      AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      await _shelterService.createHelpRequest(
        shelterId: widget.id,
        type: typeController.text,
        description: descriptionController.text,
        requestedBy: currentUser.uid,
      );
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('help_request_created'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(localizations.translate('create_failed'), e);
      }
    }
  }

  /// Shows dialog to update help request status.
  void _showUpdateHelpRequestDialog(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations, Map<String, dynamic> request) {
    final statusController = TextEditingController(text: request['status']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations.translate('update_request_status')),
        content: DropdownButtonFormField<String>(
          value: request['status'],
          decoration: InputDecoration(
            labelText: localizations.translate('request_status'),
            labelStyle: TextStyle(color: colors.text100),
          ),
          items: [
            DropdownMenuItem(
              value: 'pending',
              child: Text(localizations.translate('status_pending')),
            ),
            DropdownMenuItem(
              value: 'in_progress',
              child: Text(localizations.translate('status_in_progress')),
            ),
            DropdownMenuItem(
              value: 'completed',
              child: Text(localizations.translate('status_completed')),
            ),
            DropdownMenuItem(
              value: 'cancelled',
              child: Text(localizations.translate('status_cancelled')),
            ),
          ],
          onChanged: (value) => statusController.text = value!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => _saveHelpRequestStatus(
                request['id'], statusController, colors, localizations),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves updated help request status.
  Future<void> _saveHelpRequestStatus(
      String requestId,
      TextEditingController statusController,
      AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      await _shelterService.updateHelpRequestStatus(
        shelterId: widget.id,
        requestId: requestId,
        status: statusController.text,
        respondBy: currentUser.uid,
      );
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('status_updated'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(localizations.translate('update_failed'), e);
      }
    }
  }

  /// Shows dialog to confirm help request deletion.
  void _showDeleteHelpRequestDialog(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations, String requestId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations.translate('delete_help_request')),
        content:
            Text(localizations.translate('delete_help_request_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () =>
                _deleteHelpRequest(requestId, colors, localizations),
            style: ElevatedButton.styleFrom(backgroundColor: colors.warning),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );
  }

  /// Deletes a help request from the shelter.
  Future<void> _deleteHelpRequest(String requestId, AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      await _shelterService.deleteHelpRequest(
          shelterId: widget.id, requestId: requestId);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('help_request_deleted'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(localizations.translate('delete_failed'), e);
      }
    }
  }

  /// Shows dialog to edit shelter status.
  void _showEditStatusDialog(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations) {
    ShelterStatus selectedStatus =
        (_currentStatus == ShelterStatus.preparation ||
                _currentStatus == ShelterStatus.available)
            ? _currentStatus
            : ShelterStatus.available;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.translate('edit_shelter_status')),
          content: DropdownButtonFormField<ShelterStatus>(
            value: selectedStatus,
            items: [
              DropdownMenuItem(
                value: ShelterStatus.preparation,
                child: Text(localizations.translate('preparation')),
              ),
              DropdownMenuItem(
                value: ShelterStatus.available,
                child: Text(localizations.translate('available')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                selectedStatus = value;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _shelterService.updateShelter(
                    shelterId: widget.id,
                    status: selectedStatus.name,
                  );
                  setState(() {
                    _currentStatus = selectedStatus;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          localizations.translate('shelter_status_updated')),
                      backgroundColor: colors.accent200,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations
                          .translate('failed_to_update_shelter_status')),
                      backgroundColor: colors.warning,
                    ),
                  );
                }
              },
              child: Text(localizations.translate('save')),
            ),
          ],
        );
      },
    );
  }

  /// Saves updated shelter status.
  Future<void> _saveShelterStatus(ShelterStatus selectedStatus,
      AppColorTheme colors, AppLocalizations localizations) async {
    try {
      await _shelterService.updateShelter(
        shelterId: widget.id,
        status: selectedStatus.name,
      );
      setState(() => _currentStatus = selectedStatus);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(localizations.translate('shelter_status_updated'),
            backgroundColor: colors.accent200);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar(
            localizations.translate('failed_to_update_shelter_status'), e);
      }
    }
  }

  /// Returns the icon for a resource type.
  IconData _getResourceIcon(String type) => switch (type) {
        'food' => Icons.restaurant,
        'water' => Icons.water_drop,
        'medical' => Icons.medical_services,
        _ => Icons.inventory,
      };

  /// Returns the localized title for a resource type.
  String _getResourceTitle(String type, AppLocalizations localizations) =>
      switch (type) {
        'food' => localizations.translate('food_supplies'),
        'water' => localizations.translate('water_supplies'),
        'medical' => localizations.translate('medical_supplies'),
        _ => localizations.translate('other_supplies'),
      };

  /// Returns the icon for a help request type.
  IconData _getHelpRequestIcon(String type) => switch (type) {
        'food' => Icons.restaurant,
        'water' => Icons.water_drop,
        'medical' => Icons.medical_services,
        _ => Icons.inventory,
      };

  /// Returns the localized title for a help request type.
  String _getHelpRequestTitle(String type, AppLocalizations localizations) =>
      switch (type) {
        'food' => localizations.translate('food_request'),
        'water' => localizations.translate('water_request'),
        'medical' => localizations.translate('medical_request'),
        _ => localizations.translate('other_request'),
      };

  /// Formats a Firestore timestamp to a readable date.
  String _formatDate(Timestamp? timestamp) => timestamp != null
      ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
      : 'N/A';

  /// Shows a snackbar with a message and optional background color.
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  /// Shows an error snackbar with a message and error details.
  void _showErrorSnackBar(String message, Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$message: $error'), backgroundColor: Colors.red),
      );
    }
  }

  ShelterStatus _getShelterStatus(int currentOccupancy, int capacity) {
    if (capacity == 0) return ShelterStatus.lowCapacity;

    final percentage = (currentOccupancy / capacity) * 100;

    if (percentage > 100) {
      return ShelterStatus.overCapacity;
    } else if (percentage == 100) {
      return ShelterStatus.full;
    } else if (percentage >= 80) {
      return ShelterStatus.highCapacity;
    } else if (percentage >= 50) {
      return ShelterStatus.mediumCapacity;
    } else {
      return ShelterStatus.lowCapacity;
    }
  }
}

/// Enum for shelter status.
enum ShelterStatus {
  preparation,
  available,
  lowCapacity,
  mediumCapacity,
  highCapacity,
  full,
  overCapacity,
}

/// Enum for resource status.
enum ResourceStatus { good, medium, low }

/// Data class for status information.
class _StatusData {
  final Color color;
  final String label;

  const _StatusData({required this.color, required this.label});
}
