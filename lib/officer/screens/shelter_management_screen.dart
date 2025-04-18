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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _joinShelterController = TextEditingController();
  String _selectedFilter = 'all';
  bool _isAddMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _joinShelterController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Map<String, dynamic>> _filterShelters(
      List<Map<String, dynamic>> shelters) {
    final searchText = _searchController.text.toLowerCase();
    return shelters.where((shelter) {
      // Apply filter by status
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'available') {
          // Show all shelters that are available, regardless of capacity
          if (shelter['status'] != 'available') return false;
        } else if (_selectedFilter == 'preparation') {
          if (shelter['status'] != 'preparation') return false;
        } else {
          // For capacity statuses, only show those with available status and matching capacity
          if (shelter['status'] != 'available') return false;
          final capacityStatus = _getCapacityStatus(
            shelter['currentOccupancy'],
            shelter['capacity'],
          );
          if (capacityStatus != _selectedFilter) return false;
        }
      }
      // Apply search text filter
      if (searchText.isEmpty) return true;
      final name = (shelter['name'] ?? '').toLowerCase();
      final id = (shelter['id'] ?? '').toLowerCase();
      final location = (shelter['locationName'] ?? '').toLowerCase();
      return name.contains(searchText) ||
          id.contains(searchText) ||
          location.contains(searchText);
    }).toList();
  }

  // Helper to get capacity status string
  String _getCapacityStatus(int currentOccupancy, int capacity) {
    if (capacity == 0) return 'lowCapacity';
    final percentage = (currentOccupancy / capacity) * 100;
    if (percentage > 100) {
      return 'overCapacity';
    } else if (percentage == 100) {
      return 'full';
    } else if (percentage >= 80) {
      return 'highCapacity';
    } else if (percentage >= 50) {
      return 'mediumCapacity';
    } else {
      return 'lowCapacity';
    }
  }

  void _showAddShelterDialog(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('add_shelter'),
          style: TextStyle(color: colors.primary300),
        ),
        content: TextField(
          controller: _joinShelterController,
          decoration: InputDecoration(
            hintText: localizations.translate('enter_shelter_id'),
            hintStyle: TextStyle(color: colors.text200.withOpacity(0.6)),
            filled: true,
            fillColor: colors.bg200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.bg300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.bg300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.accent200),
            ),
          ),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () {
              _joinShelterController.clear();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(
              localizations.translate('add'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () {
              final shelterId = _joinShelterController.text.trim();
              if (shelterId.isNotEmpty) {
                Navigator.pop(context);
                _addShelterById(shelterId, colors, localizations);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addShelterById(String shelterId, AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      // Show snackbar indicating the process has started
      _showSnackBar(
        localizations.translate('adding_shelter'),
        backgroundColor: Colors.blue,
      );

      await _shelterService.joinShelter(shelterId);

      // Show snackbar for successful addition
      _showSnackBar(
        localizations.translate('successfully_added_shelter'),
        backgroundColor: Colors.green,
      );

      setState(() {});
    } catch (e) {
      // Show snackbar for failed addition
      _showErrorSnackBar(
        localizations.translate('failed_to_add_shelter'),
        e,
      );
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  void _showErrorSnackBar(String message, Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilter(colors, localizations),
            Expanded(
              child: _buildShelterList(context, colors, localizations),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isAddMenuOpen) ...[
            _buildFloatingActionButton(
              icon: Icons.add_circle,
              label: localizations.translate('create_shelter'),
              onPressed: () {
                setState(() => _isAddMenuOpen = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddShelterScreen(),
                  ),
                );
              },
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildFloatingActionButton(
              icon: Icons.add_home,
              label: localizations.translate('add_shelter'),
              onPressed: () {
                setState(() => _isAddMenuOpen = false);
                _showAddShelterDialog(colors, localizations);
              },
              colors: colors,
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            onPressed: () => setState(() => _isAddMenuOpen = !_isAddMenuOpen),
            backgroundColor: colors.primary100,
            child: Icon(
              _isAddMenuOpen ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required AppColorTheme colors,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: colors.primary100,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter(
          AppColorTheme colors, AppLocalizations localizations) =>
      Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizations.translate('search_shelters'),
                hintStyle: TextStyle(color: colors.text200),
                prefixIcon: Icon(Icons.search, color: colors.text200),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.bg300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.bg300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.accent200),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                      localizations.translate('all_shelters'), 'all', colors),
                  _buildFilterChip(localizations.translate('preparation'),
                      'preparation', colors),
                  _buildFilterChip(localizations.translate('available'),
                      'available', colors),
                  _buildFilterChip(localizations.translate('low_capacity'),
                      'lowCapacity', colors),
                  _buildFilterChip(localizations.translate('medium_capacity'),
                      'mediumCapacity', colors),
                  _buildFilterChip(localizations.translate('high_capacity'),
                      'highCapacity', colors),
                  _buildFilterChip(
                      localizations.translate('full'), 'full', colors),
                  _buildFilterChip(localizations.translate('over_capacity'),
                      'overCapacity', colors),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChip(String label, String value, AppColorTheme colors) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) =>
            setState(() => _selectedFilter = selected ? value : 'all'),
        backgroundColor: colors.bg100,
        selectedColor: colors.accent200,
        labelStyle:
            TextStyle(color: isSelected ? colors.bg100 : colors.text200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? colors.accent200 : colors.bg300),
        ),
      ),
    );
  }

  Widget _buildShelterList(BuildContext context, AppColorTheme colors,
          AppLocalizations localizations) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _shelterService.getUserShelters(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                localizations.translate('error_loading_shelters'),
                style: TextStyle(color: colors.warning),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shelters = _filterShelters(snapshot.data!);

          if (shelters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, size: 64, color: colors.bg300),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_shelters_found'),
                    style: TextStyle(color: colors.text200, fontSize: 16),
                  ),
                  if (_searchController.text.isNotEmpty ||
                      _selectedFilter != 'all') ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _selectedFilter = 'all';
                      }),
                      child: Text(
                        localizations.translate('clear_filters'),
                        style: TextStyle(color: colors.accent200),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(_padding),
            itemCount: shelters.length,
            itemBuilder: (context, index) {
              final shelter = shelters[index];
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

    // Determine if we need to show both "available" and capacity status
    final isAvailable = status == ShelterManagementStatus.lowCapacity ||
        status == ShelterManagementStatus.mediumCapacity ||
        status == ShelterManagementStatus.highCapacity ||
        status == ShelterManagementStatus.full ||
        status == ShelterManagementStatus.overCapacity;

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
                    Row(
                      children: [
                        if (isAvailable) ...[
                          // Show "available" status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent200.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('available'),
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Show capacity/preparation status
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
