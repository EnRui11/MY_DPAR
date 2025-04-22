import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/officer/services/shelter_and_resource_service.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/officer/screens/shelter_and_resource/select_shelter_location_screen.dart';
import 'package:flutter/services.dart';

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

class _ShelterDetailScreenState extends State<ShelterDetailScreen>
    with SingleTickerProviderStateMixin {
  final ShelterService _shelterService = ShelterService();
  final UserInformationService _userService = UserInformationService();
  Map<String, int> _demographics = {'elderly': 0, 'adults': 0, 'children': 0};
  late TabController _tabController;
  late int _currentCapacity;
  late ShelterStatus _currentStatus;
  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _helpRequests = [];
  String _cityName = '';
  String _creatorName = '';
  String? _creatorId;
  DateTime? _createdAt;
  bool _isLoading = true;

  // UI constants
  static const double _padding = 16.0;
  static const double _spacing = 24.0;
  static const double _spacingSmall = 8.0;
  static const double _cardRadius = 16.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentCapacity = widget.currentCapacity;
    _currentStatus = widget.status;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load shelter data
      final shelter = await _shelterService.getShelter(widget.id);
      if (shelter != null) {
        // Get city name from coordinates
        final placemarks = await placemarkFromCoordinates(
          widget.coordinates.latitude,
          widget.coordinates.longitude,
        );
        if (placemarks.isNotEmpty) {
          _cityName = placemarks.first.locality ?? widget.location;
        }

        // Get creator info
        final creatorId = shelter['createdBy'];
        _creatorId = creatorId;
        final creatorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId)
            .get();
        if (creatorDoc.exists) {
          final data = creatorDoc.data()!;
          _creatorName = '${data['firstName']} ${data['lastName']}';
        }

        // Get creation date
        _createdAt = (shelter['createdAt'] as Timestamp).toDate();

        setState(() {
          _demographics = Map<String, int>.from(shelter['demographics'] ??
              {'elderly': 0, 'adults': 0, 'children': 0});

          _currentStatus =
              ShelterStatus.fromString(shelter['status'] as String);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(colors, localizations),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildShelterInfoCard(colors, localizations),
                          ),

                          // Tabs
                          Container(
                            decoration: BoxDecoration(
                              color: colors.bg100,
                              border: Border(
                                bottom: BorderSide(color: colors.bg300),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: colors.accent200,
                              unselectedLabelColor: colors.text200,
                              indicatorColor: colors.accent200,
                              tabs: [
                                Tab(
                                    text: localizations
                                        .translate('demographics')),
                                Tab(text: localizations.translate('resources')),
                                Tab(
                                    text: localizations
                                        .translate('help_requests')),
                                Tab(text: localizations.translate('location')),
                              ],
                            ),
                          ),

                          // Tab content
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildDemographicsTab(colors, localizations),
                                _buildResourcesTab(colors, localizations),
                                _buildHelpRequestsTab(colors, localizations),
                                _buildLocationTab(colors, localizations),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

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
            Expanded(
              child: Text(
                widget.name,
                style: TextStyle(
                  color: colors.primary300,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.accent200),
              onPressed: () {
                _showEditShelterDialog(context, colors, localizations);
              },
            ),
          ],
        ),
      );

  /// Shows dialog to edit shelter status or delete shelter.
  void _showEditShelterDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == _creatorId;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bg100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share, color: colors.accent200),
              title: Text(
                localizations.translate('share_shelter'),
                style: TextStyle(color: colors.text200),
              ),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: widget.id));
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(localizations.translate('shelter_id_copied')),
                      backgroundColor: colors.accent200,
                    ),
                  );
                }
              },
            ),
            if (_currentStatus == ShelterStatus.available) ...[
              ListTile(
                leading: Icon(Icons.build, color: colors.accent200),
                title: Text(
                  localizations.translate('preparation'),
                  style: TextStyle(color: colors.text200),
                ),
                selected: _currentStatus == ShelterStatus.preparation,
                onTap: () {
                  Navigator.pop(context);
                  _updateShelterStatus(
                    colors,
                    localizations,
                    ShelterStatus.preparation,
                  );
                },
              ),
              if (isCreator) ...[
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colors.warning),
                  title: Text(
                    localizations.translate('delete_shelter'),
                    style: TextStyle(color: colors.warning),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteShelterDialog(context, colors, localizations);
                  },
                ),
              ],
            ] else if (_currentStatus == ShelterStatus.preparation) ...[
              ListTile(
                leading: Icon(Icons.check_circle, color: colors.accent200),
                title: Text(
                  localizations.translate('available'),
                  style: TextStyle(color: colors.text200),
                ),
                selected: _currentStatus == ShelterStatus.available,
                onTap: () {
                  Navigator.pop(context);
                  _updateShelterStatus(
                    colors,
                    localizations,
                    ShelterStatus.available,
                  );
                },
              ),
              if (isCreator) ...[
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colors.warning),
                  title: Text(
                    localizations.translate('delete_shelter'),
                    style: TextStyle(color: colors.warning),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteShelterDialog(context, colors, localizations);
                  },
                ),
              ],
            ] else if (isCreator) ...[
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.warning),
                title: Text(
                  localizations.translate('delete_shelter'),
                  style: TextStyle(color: colors.warning),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteShelterDialog(context, colors, localizations);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows dialog to confirm shelter deletion.
  void _showDeleteShelterDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('delete_shelter'),
          style: TextStyle(color: colors.warning),
        ),
        content: Text(
          localizations.translate('delete_shelter_confirmation'),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteShelter(context, colors, localizations),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: colors.bg100,
            ),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );
  }

  /// Deletes the shelter and returns to the previous screen.
  Future<void> _deleteShelter(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) async {
    try {
      await _shelterService.deleteShelter(widget.id);
      if (mounted) {
        Navigator.pop(context); // Pop dialog
        Navigator.pop(context); // Pop page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('shelter_deleted')),
            backgroundColor: colors.accent200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('delete_failed')}: $e'),
            backgroundColor: colors.warning,
          ),
        );
      }
    }
  }

  Widget _buildShelterInfoCard(
      AppColorTheme colors, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.accent200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.name.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        color: colors.primary300,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusBadge(colors, localizations),
                        const SizedBox(width: 8),
                        _buildCapacityBadge(colors, localizations),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoGrid(colors, localizations),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(AppColorTheme colors, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            colors,
            localizations.translate('shelter_manager'),
            _creatorName,
            Icons.person,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            colors,
            localizations.translate('location'),
            _cityName,
            Icons.location_on,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            colors,
            localizations.translate('created_at'),
            _formatDate(_createdAt),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    AppColorTheme colors,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.accent200),
        const SizedBox(width: 12),
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
            Text(
              value,
              style: TextStyle(
                color: colors.primary300,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Formats a date to a readable string.
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    final DateTime dateTime = date is Timestamp
        ? date.toDate()
        : date is DateTime
            ? date
            : DateTime.now();

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

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

  /// Builds the demographics tab content.
  Widget _buildDemographicsTab(
      AppColorTheme colors, AppLocalizations localizations) {
    final totalOccupants =
        _demographics.values.fold<int>(0, (sum, count) => sum + count);
    final percent =
        widget.totalCapacity == 0 ? 0.0 : totalOccupants / widget.totalCapacity;
    final percentLabel = '${(percent * 100).toInt()}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${localizations.translate('total_occupants')} ($totalOccupants)',
                style: TextStyle(
                  color: colors.primary300,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () =>
                    _showEditDemographicsDialog(context, colors, localizations),
                child: Text(
                  localizations.translate('update'),
                  style: TextStyle(
                    color: colors.accent200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bg100.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.bg300.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('capacity_overview'),
                  style: TextStyle(
                    color: colors.primary300,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$totalOccupants',
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
                          percentLabel,
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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: colors.primary100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getCapacityColor(colors)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDemographicCard(
            colors,
            localizations,
            Icons.elderly,
            localizations.translate('elderly'),
            _demographics['elderly'] ?? 0,
          ),
          const SizedBox(height: 12),
          _buildDemographicCard(
            colors,
            localizations,
            Icons.person,
            localizations.translate('adults'),
            _demographics['adults'] ?? 0,
          ),
          const SizedBox(height: 12),
          _buildDemographicCard(
            colors,
            localizations,
            Icons.child_care,
            localizations.translate('children'),
            _demographics['children'] ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicCard(
    AppColorTheme colors,
    AppLocalizations localizations,
    IconData icon,
    String category,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.accent200),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: colors.primary300,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${count} ${localizations.translate('people')}',
                  style: TextStyle(
                    color: colors.text200,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${((count / widget.totalCapacity) * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: colors.accent200,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows dialog to edit shelter demographics.
  void _showEditDemographicsDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    int elderlyCount = _demographics['elderly'] ?? 0;
    int adultsCount = _demographics['adults'] ?? 0;
    int childrenCount = _demographics['children'] ?? 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('edit_demographics'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDemographicField(
              colors,
              localizations.translate('elderly'),
              elderlyCount.toString(),
              (value) => elderlyCount = int.tryParse(value) ?? elderlyCount,
            ),
            const SizedBox(height: 16),
            _buildDemographicField(
              colors,
              localizations.translate('adults'),
              adultsCount.toString(),
              (value) => adultsCount = int.tryParse(value) ?? adultsCount,
            ),
            const SizedBox(height: 16),
            _buildDemographicField(
              colors,
              localizations.translate('children'),
              childrenCount.toString(),
              (value) => childrenCount = int.tryParse(value) ?? childrenCount,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
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
                  _currentCapacity = elderlyCount + adultsCount + childrenCount;
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(localizations.translate('demographics_updated')),
                      backgroundColor: colors.accent200,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${localizations.translate('update_failed')}: $e'),
                      backgroundColor: colors.warning,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent200,
              foregroundColor: colors.bg100,
            ),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicField(
    AppColorTheme colors,
    String label,
    String initialValue,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.text200),
        filled: true,
        fillColor: colors.bg200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.bg300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.bg300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent200),
        ),
      ),
    );
  }

  /// Returns the color based on capacity percentage.
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

  /// Builds the resources tab content.
  Widget _buildResourcesTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _shelterService.getShelterResources(widget.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${localizations.translate('error_loading_resources')}: ${snapshot.error}',
              style: TextStyle(color: colors.warning),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final resources = snapshot.data!;
        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory, size: 48, color: colors.text200),
                const SizedBox(height: 16),
                Text(
                  localizations.translate('no_resources'),
                  style: TextStyle(color: colors.text200),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showAddResourceDialog(context, colors, localizations),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(localizations.translate('add_resource')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent200,
                    foregroundColor: colors.bg100,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.translate('resource_inventory'),
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showAddResourceDialog(context, colors, localizations),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(localizations.translate('add_resource')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent200,
                      foregroundColor: colors.bg100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...resources.map((resource) {
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
                      onUpdateStock: () => _showUpdateStockDialog(
                        context,
                        colors,
                        localizations,
                        resource['id'],
                        resource,
                      ),
                      onDelete: () => _showDeleteResourceDialog(
                        context,
                        colors,
                        localizations,
                        resource['id'],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.bg200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: colors.accent200, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: colors.text200, fontSize: 14),
          ),
          const SizedBox(height: 12),
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
                    color: colors.bg200,
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
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('add_resource'),
          style: TextStyle(color: colors.primary300),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeController.text,
                decoration: InputDecoration(
                  labelText: localizations.translate('resource_type'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
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
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('resource_description'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currentStockController,
                decoration: InputDecoration(
                  labelText: localizations.translate('current_stock'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minThresholdController,
                decoration: InputDecoration(
                  labelText: localizations.translate('min_threshold'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveNewResource(
              typeController,
              descriptionController,
              currentStockController,
              minThresholdController,
              colors,
              localizations,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent200,
              foregroundColor: colors.bg100,
            ),
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
    AppLocalizations localizations,
  ) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('resource_added')),
            backgroundColor: colors.accent200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('update_failed')}: $e'),
            backgroundColor: colors.warning,
          ),
        );
      }
    }
  }

  /// Shows dialog to update resource stock.
  void _showUpdateStockDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
    String resourceId,
    Map<String, dynamic> resource,
  ) {
    final stockController =
        TextEditingController(text: resource['currentStock'].toString());
    final minThresholdController =
        TextEditingController(text: resource['minThreshold'].toString());
    final descriptionController =
        TextEditingController(text: resource['description'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('edit_resource'),
          style: TextStyle(color: colors.primary300),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('resource_description'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: localizations.translate('current_stock'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minThresholdController,
                decoration: InputDecoration(
                  labelText: localizations.translate('min_threshold'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () => _updateResourceDetails(
              resourceId,
              descriptionController,
              stockController,
              minThresholdController,
              colors,
              localizations,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent200,
              foregroundColor: colors.bg100,
            ),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves updated resource stock.
  Future<void> _updateResourceDetails(
    String resourceId,
    TextEditingController descriptionController,
    TextEditingController stockController,
    TextEditingController minThresholdController,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) async {
    try {
      await _shelterService.updateResource(
        widget.id,
        resourceId,
        description: descriptionController.text,
        currentStock: int.parse(stockController.text),
        minThreshold: int.parse(minThresholdController.text),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('resource_updated')),
            backgroundColor: colors.accent200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('update_failed')}: $e'),
            backgroundColor: colors.warning,
          ),
        );
      }
    }
  }

  /// Shows dialog to confirm resource deletion.
  void _showDeleteResourceDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
    String resourceId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('delete_resource'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Text(
          localizations.translate('delete_resource_confirmation'),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteResource(resourceId, colors, localizations),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: colors.bg100,
            ),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );
  }

  /// Deletes a resource from the shelter.
  Future<void> _deleteResource(
    String resourceId,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) async {
    try {
      await _shelterService.deleteResource(widget.id, resourceId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('resource_deleted')),
            backgroundColor: colors.accent200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('delete_failed')}: $e'),
            backgroundColor: colors.warning,
          ),
        );
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

  /// Returns status data for resource status.
  _StatusData _getResourceStatusData(
    ResourceStatus status,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) =>
      switch (status) {
        ResourceStatus.good => _StatusData(
            color: Colors.green,
            label: localizations.translate('good'),
          ),
        ResourceStatus.medium => _StatusData(
            color: Colors.orange,
            label: localizations.translate('medium'),
          ),
        ResourceStatus.low => _StatusData(
            color: Colors.red,
            label: localizations.translate('low'),
          ),
      };

  /// Builds the help requests tab content.
  Widget _buildHelpRequestsTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _shelterService.getHelpRequests(widget.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${localizations.translate('error_loading_help_requests')}: ${snapshot.error}',
              style: TextStyle(color: colors.warning),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.help_outline, size: 48, color: colors.text200),
                const SizedBox(height: 16),
                Text(
                  localizations.translate('no_help_requests'),
                  style: TextStyle(color: colors.text200),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showAddHelpRequestDialog(context, colors, localizations),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(localizations.translate('create_help_requests')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent200,
                    foregroundColor: colors.bg100,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.translate('help_requests'),
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddHelpRequestDialog(
                        context, colors, localizations),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(localizations.translate('create_new_request')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent200,
                      foregroundColor: colors.bg100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...requests.map((request) {
                final createdAtRaw = request['createdAt'];
                final createdAt = createdAtRaw is Timestamp
                    ? createdAtRaw.toDate()
                    : DateTime.now();
                return Column(
                  children: [
                    _buildHelpRequestItem(
                      colors,
                      localizations,
                      icon: _getHelpRequestIcon(request['type']),
                      title:
                          _getHelpRequestTitle(request['type'], localizations),
                      description: request['description'],
                      status: request['status'],
                      requestDate: _formatDate(createdAt),
                      onUpdate: () => _showUpdateHelpRequestDialog(
                        context,
                        colors,
                        localizations,
                        request,
                      ),
                      onDelete: () => _showDeleteHelpRequestDialog(
                        context,
                        colors,
                        localizations,
                        request['id'],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

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
    final statusData = _getHelpRequestStatusData(status, colors, localizations);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.bg200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: colors.accent200, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.primary300,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: colors.text200, fontSize: 14),
          ),
          const SizedBox(height: 12),
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
                    color: colors.bg200,
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

  /// Shows dialog to add a new help request.
  void _showAddHelpRequestDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final typeController = TextEditingController(text: 'food');
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('add_help_request'),
          style: TextStyle(color: colors.primary300),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: typeController.text,
                decoration: InputDecoration(
                  labelText: localizations.translate('request_type'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'food',
                    child: Text(localizations.translate('request_type_food')),
                  ),
                  DropdownMenuItem(
                    value: 'water',
                    child: Text(localizations.translate('request_type_water')),
                  ),
                  DropdownMenuItem(
                    value: 'medical',
                    child:
                        Text(localizations.translate('request_type_medical')),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(localizations.translate('request_type_other')),
                  ),
                ],
                onChanged: (value) => typeController.text = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('request_description'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: localizations.translate('quantity'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveNewHelpRequest(
              typeController,
              descriptionController,
              quantityController,
              colors,
              localizations,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent200,
              foregroundColor: colors.bg100,
            ),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves a new help request.
  Future<void> _saveNewHelpRequest(
    TextEditingController typeController,
    TextEditingController descriptionController,
    TextEditingController quantityController,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (descriptionController.text.isEmpty ||
          quantityController.text.isEmpty) {
        throw Exception('All fields are required');
      }

      final quantity = int.tryParse(quantityController.text);
      if (quantity == null || quantity <= 0) {
        throw Exception('Please enter a valid quantity');
      }

      // Use the ShelterService to create the help request
      await _shelterService.createHelpRequest(
        shelterId: widget.id,
        type: typeController.text,
        description: descriptionController.text,
        quantity: quantity,
        requestedBy: currentUser.uid,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('help_request_created')),
            backgroundColor: colors.accent200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('create_failed')}: $e'),
            backgroundColor: colors.warning,
          ),
        );
      }
    }
  }

  /// Shows dialog to update help request status.
  void _showUpdateHelpRequestDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
    Map<String, dynamic> request,
  ) {
    final statusController = TextEditingController(text: request['status']);
    final descriptionController =
        TextEditingController(text: request['description']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('update_request_status'),
          style: TextStyle(color: colors.primary300),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: request['status'],
                decoration: InputDecoration(
                  labelText: localizations.translate('request_status'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
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
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('request_description'),
                  labelStyle: TextStyle(color: colors.text200),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.bg300),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () => _updateHelpRequest(
              request['id'],
              statusController,
              descriptionController,
              colors,
              localizations,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent200,
              foregroundColor: colors.bg100,
            ),
            child: Text(localizations.translate('save')),
          ),
        ],
      ),
    );
  }

  /// Saves updated help request status.
  Future<void> _updateHelpRequest(
    String requestId,
    TextEditingController statusController,
    TextEditingController descriptionController,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      await _shelterService.updateHelpRequest(
        shelterId: widget.id,
        requestId: requestId,
        status: statusController.text,
        description: descriptionController.text,
        requestedBy: currentUser.uid,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('request_updated')),
            backgroundColor: colors.accent200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('update_failed')}: $e'),
            backgroundColor: colors.warning,
          ),
        );
      }
    }
  }

  /// Shows dialog to confirm help request deletion.
  void _showDeleteHelpRequestDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
    String requestId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('delete_help_request'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Text(
          localizations.translate('delete_help_request_confirmation'),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                _deleteHelpRequest(requestId, colors, localizations),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: colors.bg100,
            ),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );
  }

  /// Deletes a help request from the shelter.
  Future<void> _deleteHelpRequest(
    String requestId,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) async {
    try {
      await _shelterService.deleteHelpRequest(
        shelterId: widget.id,
        requestId: requestId,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('help_request_deleted')),
            backgroundColor: colors.accent200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('delete_failed')}: $e'),
            backgroundColor: colors.warning,
          ),
        );
      }
    }
  }

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

  /// Returns status data for help request status.
  _StatusData _getHelpRequestStatusData(
    String status,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) =>
      switch (status) {
        'pending' => _StatusData(
            color: Colors.orange,
            label: localizations.translate('status_pending'),
          ),
        'in_progress' => _StatusData(
            color: Colors.blue,
            label: localizations.translate('status_in_progress'),
          ),
        'completed' => _StatusData(
            color: Colors.green,
            label: localizations.translate('status_completed'),
          ),
        'cancelled' => _StatusData(
            color: Colors.red,
            label: localizations.translate('status_cancelled'),
          ),
        _ => _StatusData(
            color: colors.text200,
            label: status,
          ),
      };

  /// Builds the location tab content.
  Widget _buildLocationTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('shelter_location'),
                style: TextStyle(
                  color: colors.primary300,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showUpdateLocationDialog(
                  context,
                  colors,
                  localizations,
                ),
                icon: Icon(Icons.edit, color: colors.accent200, size: 16),
                label: Text(
                  localizations.translate('update'),
                  style: TextStyle(
                    color: colors.accent200,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: colors.bg200,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              options: MapOptions(
                center: widget.coordinates,
                zoom: 15,
                interactiveFlags: InteractiveFlag.none,
              ),
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
                      builder: (_) => const Icon(
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bg200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: colors.accent200, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('address'),
                        style: TextStyle(
                          color: colors.text200,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.location,
                        style: TextStyle(
                          color: colors.primary300,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.translate('location_history'),
            style: TextStyle(
              color: colors.primary300,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _shelterService.getLocationHistory(widget.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  localizations.translate('error_loading_location_history'),
                  style: TextStyle(color: colors.warning),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final history = snapshot.data!;
              if (history.isEmpty) {
                return Text(
                  localizations.translate('no_location_history'),
                  style: TextStyle(color: colors.text200),
                );
              }

              return Column(
                children: history.map((entry) {
                  final location = entry['location'] as LatLng;
                  final locationName = entry['locationName'] as String;
                  final timestamp = entry['timestamp'] as Timestamp;
                  final notes = entry['notes'] as String?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bg200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history,
                                color: colors.accent200, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locationName,
                                    style: TextStyle(
                                      color: colors.primary300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(timestamp),
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
                        if (notes != null && notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            notes,
                            style: TextStyle(
                              color: colors.text200,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Shows dialog to update shelter location.
  void _showUpdateLocationDialog(
    BuildContext context,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectShelterLocationScreen(
          initialLocation: widget.coordinates,
        ),
      ),
    );

    if (result != null && mounted) {
      final newLocation = LatLng(
        result['latitude'] as double,
        result['longitude'] as double,
      );
      final locationName = result['locationName'] as String;

      try {
        // Update the shelter's current location
        await _shelterService.updateShelter(
          shelterId: widget.id,
          location: newLocation,
          locationName: locationName,
        );

        // Add to location history
        await _shelterService.addLocationHistory(
          shelterId: widget.id,
          location: newLocation,
          locationName: locationName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('location_updated')),
              backgroundColor: colors.accent200,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.translate('update_failed')}: $e'),
              backgroundColor: colors.warning,
            ),
          );
        }
      }
    }
  }

  /// Updates the shelter status.
  Future<void> _updateShelterStatus(
    AppColorTheme colors,
    AppLocalizations localizations,
    ShelterStatus newStatus,
  ) async {
    try {
      await _shelterService.updateShelter(
        shelterId: widget.id,
        status: newStatus.name,
      );
      setState(() => _currentStatus = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('demographics_updated')),
          backgroundColor: colors.accent200,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.translate('update_failed')}: $e'),
          backgroundColor: colors.warning,
        ),
      );
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
  overCapacity;

  static ShelterStatus fromString(String status) {
    return ShelterStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ShelterStatus.available, // fallback
    );
  }
}

/// Enum for resource status.
enum ResourceStatus { good, medium, low }

/// Data class for status information.
class _StatusData {
  final Color color;
  final String label;

  const _StatusData({required this.color, required this.label});
}
