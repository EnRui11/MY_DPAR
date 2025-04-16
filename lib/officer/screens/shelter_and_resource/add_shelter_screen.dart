import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mydpar/officer/screens/shelter_and_resource/select_shelter_location_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mydpar/services/shelter_and_resource_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddShelterScreen extends StatefulWidget {
  const AddShelterScreen({super.key});

  @override
  State<AddShelterScreen> createState() => _AddShelterScreenState();
}

class _AddShelterScreenState extends State<AddShelterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  String _selectedStatus = 'available';
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  String? _locationName;
  final List<ResourceItem> _resources = [];
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  late final MapController _mapController;
  static const LatLng _defaultLocation =
      LatLng(3.1390, 101.6869); // Kuala Lumpur

  final _shelterService = ShelterService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        if (_selectedLocation == null) {
          _mapController.move(_currentLocation!, 15);
        }
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, localizations),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfo(colors, localizations),
                      const SizedBox(height: 24),
                      _buildLocationSection(colors, localizations),
                      const SizedBox(height: 24),
                      _buildCapacityInput(colors, localizations),
                      const SizedBox(height: 24),
                      _buildResourceSetup(colors, localizations),
                      const SizedBox(height: 32),
                      _buildSubmitButton(colors, localizations),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorTheme colors, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: colors.bg300.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.accent200),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            localizations.translate('add_new_shelter'),
            style: TextStyle(
              color: colors.accent200,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('basic_information'),
          style: TextStyle(
            color: colors.text100,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Shelter Name (required)
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: localizations.translate('shelter_name'),
                style: TextStyle(color: colors.text100),
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.bg100,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.translate('please_enter_shelter_name');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: InputDecoration(
            labelText: localizations.translate('status'),
            labelStyle: TextStyle(color: colors.text100),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.bg100,
          ),
          items: [
            DropdownMenuItem(
              value: 'available',
              child: Text(localizations.translate('status_available')),
            ),
            DropdownMenuItem(
              value: 'preparation',
              child: Text(localizations.translate('status_preparation')),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedStatus = value!);
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection(
      AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              localizations.translate('location'),
              style: TextStyle(
                color: colors.text100,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedLocation == null
                  ? colors.warning
                  : colors.bg300.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (_isLoadingLocation)
                  Center(
                    child: CircularProgressIndicator(color: colors.accent200),
                  )
                else
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _selectedLocation ??
                          _currentLocation ??
                          _defaultLocation,
                      zoom: 15,
                      interactiveFlags: InteractiveFlag.none,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          if (_selectedLocation != null)
                            Marker(
                              point: _selectedLocation!,
                              builder: (_) => Icon(
                                Icons.location_pin,
                                color: colors.warning,
                                size: 40,
                              ),
                            )
                          else if (_currentLocation != null)
                            Marker(
                              point: _currentLocation!,
                              builder: (_) => Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectLocation,
                      child: _selectedLocation == null && !_isLoadingLocation
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 8),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_locationName != null) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.bg100.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.bg300.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.location_on, color: colors.accent200, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationName!,
                    style: TextStyle(color: colors.text200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCapacityInput(
      AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              localizations.translate('total_capacity'),
              style: TextStyle(
                color: colors.text100,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _capacityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: localizations.translate('enter_total_capacity'),
            labelStyle: TextStyle(color: colors.text100),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.bg100,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.translate('please_enter_capacity');
            }
            final number = int.tryParse(value);
            if (number == null || number <= 0) {
              return localizations.translate('capacity_must_be_positive');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildResourceSetup(
      AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.translate('resource_setup'),
              style: TextStyle(
                color: colors.text100,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: colors.accent200),
              onPressed: () => _addResource(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _resources.length,
          itemBuilder: (context, index) => _buildResourceCard(
            colors,
            localizations,
            _resources[index],
            index,
          ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(
    AppColorTheme colors,
    AppLocalizations localizations,
    ResourceItem resource,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getResourceIcon(resource.type),
                color: colors.accent200,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: resource.type,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'food',
                      child:
                          Text(localizations.translate('resource_type_food')),
                    ),
                    DropdownMenuItem(
                      value: 'water',
                      child:
                          Text(localizations.translate('resource_type_water')),
                    ),
                    DropdownMenuItem(
                      value: 'medical',
                      child: Text(
                          localizations.translate('resource_type_medical')),
                    ),
                    DropdownMenuItem(
                      value: 'others',
                      child:
                          Text(localizations.translate('resource_type_others')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _resources[index] = resource.copyWith(type: value!);
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: colors.warning),
                onPressed: () {
                  setState(() {
                    _resources.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: resource.descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: localizations.translate('resource_description'),
              labelStyle: TextStyle(color: colors.text100),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colors.bg200,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: resource.initialStockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: localizations.translate('current_stock'),
                    labelStyle: TextStyle(color: colors.text100),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colors.bg200,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: resource.minThresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: localizations.translate('min_threshold'),
                    labelStyle: TextStyle(color: colors.text100),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colors.bg200,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
      AppColorTheme colors, AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          foregroundColor: colors.bg100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: colors.bg100,
                  strokeWidth: 2,
                ),
              )
            : Text(
                localizations.translate('create_shelter'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectShelterLocationScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLocation = LatLng(
          result['latitude'] as double,
          result['longitude'] as double,
        );
        _locationName = result['locationName'] as String;
      });
      // Move the map to the selected location
      if (_selectedLocation != null) {
        _mapController.move(_selectedLocation!, 15);
      }
    }
  }

  void _addResource() {
    setState(() {
      _resources.add(ResourceItem());
    });
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'food':
        return Icons.restaurant;
      case 'water':
        return Icons.water_drop;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.inventory;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('please_select_location')),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare resources data
      final resourcesData = _resources
          .map((resource) => {
                'type': resource.type,
                'description': resource.descriptionController.text,
                'currentStock': int.parse(resource.initialStockController.text),
                'minThreshold': int.parse(resource.minThresholdController.text),
              })
          .toList();

      // Create shelter with resources
      await _shelterService.createShelter(
        name: _nameController.text,
        status: _selectedStatus,
        location: _selectedLocation!,
        locationName: _locationName!,
        capacity: int.parse(_capacityController.text),
        createdBy: currentUser.uid,
        resources: resourcesData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('shelter_created_successfully')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('failed_to_create_shelter')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class ResourceItem {
  String type;
  final TextEditingController descriptionController;
  final TextEditingController initialStockController;
  final TextEditingController minThresholdController;

  ResourceItem({
    this.type = 'food',
    TextEditingController? descriptionController,
    TextEditingController? initialStockController,
    TextEditingController? minThresholdController,
  })  : descriptionController =
            descriptionController ?? TextEditingController(),
        initialStockController =
            initialStockController ?? TextEditingController(),
        minThresholdController =
            minThresholdController ?? TextEditingController();

  ResourceItem copyWith({
    String? type,
    TextEditingController? descriptionController,
    TextEditingController? initialStockController,
    TextEditingController? minThresholdController,
  }) {
    return ResourceItem(
      type: type ?? this.type,
      descriptionController:
          descriptionController ?? this.descriptionController,
      initialStockController:
          initialStockController ?? this.initialStockController,
      minThresholdController:
          minThresholdController ?? this.minThresholdController,
    );
  }
}
