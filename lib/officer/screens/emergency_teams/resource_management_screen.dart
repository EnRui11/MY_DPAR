import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/services/emergency_team_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

class ResourceManagementScreen extends StatefulWidget {
  final String teamId;
  final bool isLeader;

  const ResourceManagementScreen({
    super.key,
    required this.teamId,
    required this.isLeader,
  });

  @override
  State<ResourceManagementScreen> createState() =>
      _ResourceManagementScreenState();
}

class _ResourceManagementScreenState extends State<ResourceManagementScreen>
    with SingleTickerProviderStateMixin {
  final EmergencyTeamService _teamService = EmergencyTeamService();
  bool _isLoading = false;
  bool _isVolunteerMember = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkVolunteerStatus();
  }

  Future<void> _checkVolunteerStatus() async {
    final isVolunteer = await _teamService.isVolunteerMember(widget.teamId);
    if (mounted) {
      setState(() {
        _isVolunteerMember = isVolunteer;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Provider.of<ThemeProvider>(context, listen: true).currentTheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, localizations),
            // Tab bar
            Container(
              color: colors.bg100,
              child: TabBar(
                controller: _tabController,
                labelColor: colors.accent200,
                unselectedLabelColor: colors.text200,
                indicatorColor: colors.accent200,
                tabs: [
                  Tab(text: localizations.translate('equipment')),
                  Tab(text: localizations.translate('vehicle')),
                  Tab(text: localizations.translate('supply')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Equipment tab
                  _buildResourceList(colors, localizations, 'Equipment'),
                  // Vehicle tab
                  _buildResourceList(colors, localizations, 'Vehicle'),
                  // Supply tab
                  _buildResourceList(colors, localizations, 'Supply'),
                ],
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
        color: colors.bg100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colors.primary300),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                localizations.translate('resource_management'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          if (!_isVolunteerMember)
            IconButton(
              icon: Icon(Icons.add, color: colors.accent200),
              onPressed: () => _showAddResourceModal(colors, localizations),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceList(
      AppColorTheme colors, AppLocalizations localizations, String type) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _teamService.getTeamResourcesByType(widget.teamId, type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              localizations
                  .translate('error', {'error': snapshot.error.toString()}),
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
                Icon(Icons.inventory_2_outlined, size: 64, color: colors.bg300),
                const SizedBox(height: 16),
                Text(
                  localizations
                      .translate('no_resources_of_type', {'type': type}),
                  style: TextStyle(color: colors.text200, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) => _buildResourceCard(
            resources[index],
            colors,
            localizations,
          ),
        );
      },
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource, AppColorTheme colors,
      AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bg100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        resource['resource_name'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary300,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  resource['description'] ?? '',
                  style: TextStyle(color: colors.text200),
                ),
                const SizedBox(height: 12),
                // Resource details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: colors.text200),
                        const SizedBox(width: 4),
                        Text(
                          '${localizations.translate('type')}: ${resource['type'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.text200,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.inventory, size: 16, color: colors.text200),
                        const SizedBox(width: 4),
                        Text(
                          '${localizations.translate('quantity')}: ${resource['quantity'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.text200,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_isVolunteerMember)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.bg300)),
              ),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    label: localizations.translate('edit'),
                    onTap: () =>
                        _showEditResourceModal(resource, colors, localizations),
                    colors: colors,
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: localizations.translate('delete'),
                    onTap: () => _showDeleteConfirmation(
                        resource, colors, localizations),
                    colors: colors,
                  ),
                  _buildActionButton(
                    icon: Icons.update,
                    label: localizations.translate('update_quantity'),
                    onTap: () => _showUpdateQuantityModal(
                        resource, colors, localizations),
                    colors: colors,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColorTheme colors,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: colors.bg300)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colors.accent200),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.accent200,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddResourceModal(
      AppColorTheme colors, AppLocalizations localizations) {
    final TextEditingController resourceNameController =
        TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: colors.bg100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.bg300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.translate('add_new_resource'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.primary300,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.primary300),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizations.translate('resource_name')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: resourceNameController,
                          decoration: InputDecoration(
                            hintText:
                                localizations.translate('enter_resource_name'),
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('description')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                localizations.translate('resource_details'),
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('quantity')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: localizations.translate('enter_quantity'),
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('type')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colors.bg200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.bg300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: typeController.text.isEmpty
                                  ? null
                                  : typeController.text,
                              hint: Text(
                                localizations.translate('select_type'),
                                style: TextStyle(
                                  color: colors.text200.withOpacity(0.5),
                                ),
                              ),
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'Equipment',
                                  child: Text(
                                      localizations.translate('equipment')),
                                ),
                                DropdownMenuItem(
                                  value: 'Vehicle',
                                  child:
                                      Text(localizations.translate('vehicle')),
                                ),
                                DropdownMenuItem(
                                  value: 'Supply',
                                  child:
                                      Text(localizations.translate('supply')),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    typeController.text = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (resourceNameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('resource_name_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (descriptionController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('description_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (quantityController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('quantity_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (typeController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations.translate('type_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              int quantity;
                              try {
                                quantity = int.parse(quantityController.text);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('valid_number_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                await _teamService.addTeamResource(
                                  teamId: widget.teamId,
                                  resourceName: resourceNameController.text,
                                  description: descriptionController.text,
                                  quantity: quantity,
                                  type: typeController.text,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.translate(
                                            'resource_added_successfully'),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations
                                            .translate('error_adding_resource'),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accent200,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations.translate('add_resource'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditResourceModal(
    Map<String, dynamic> resource,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final TextEditingController resourceNameController =
        TextEditingController(text: resource['resource_name']);
    final TextEditingController descriptionController =
        TextEditingController(text: resource['description']);
    final TextEditingController quantityController =
        TextEditingController(text: resource['quantity'].toString());
    final TextEditingController typeController =
        TextEditingController(text: resource['type']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: colors.bg100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.bg300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.translate('edit_resource'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.primary300,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.primary300),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizations.translate('resource_name')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: resourceNameController,
                          decoration: InputDecoration(
                            hintText:
                                localizations.translate('enter_resource_name'),
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('description')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                localizations.translate('resource_details'),
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('quantity')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: localizations.translate('enter_quantity'),
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
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('type')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colors.bg200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.bg300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: typeController.text.isEmpty
                                  ? null
                                  : typeController.text,
                              hint: Text(
                                localizations.translate('select_type'),
                                style: TextStyle(
                                  color: colors.text200.withOpacity(0.5),
                                ),
                              ),
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'Equipment',
                                  child: Text(
                                      localizations.translate('equipment')),
                                ),
                                DropdownMenuItem(
                                  value: 'Vehicle',
                                  child:
                                      Text(localizations.translate('vehicle')),
                                ),
                                DropdownMenuItem(
                                  value: 'Supply',
                                  child:
                                      Text(localizations.translate('supply')),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    typeController.text = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (resourceNameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('resource_name_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (descriptionController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('description_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (quantityController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('quantity_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (typeController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations.translate('type_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              int quantity;
                              try {
                                quantity = int.parse(quantityController.text);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('valid_number_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                await _teamService.updateTeamResource(
                                  teamId: widget.teamId,
                                  resourceId: resource['id'],
                                  resourceName: resourceNameController.text,
                                  description: descriptionController.text,
                                  quantity: quantity,
                                  type: typeController.text,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.translate(
                                            'resource_updated_successfully'),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.translate(
                                            'error_updating_resource'),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accent200,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations.translate('update_resource'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateQuantityModal(
    Map<String, dynamic> resource,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final TextEditingController quantityController =
        TextEditingController(text: resource['quantity'].toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.bg100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.bg300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('update_quantity'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.primary300),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['resource_name'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${localizations.translate('current_quantity')}: ${resource['quantity']}',
                      style: TextStyle(
                        color: colors.text200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${localizations.translate('new_quantity')}*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.text200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: localizations.translate('enter_new_quantity'),
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
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            localizations.translate('cancel'),
                            style: TextStyle(color: colors.text200),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (quantityController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localizations
                                        .translate('quantity_required'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            int quantity;
                            try {
                              quantity = int.parse(quantityController.text);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localizations
                                        .translate('valid_number_required'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              await _teamService.updateTeamResource(
                                teamId: widget.teamId,
                                resourceId: resource['id'],
                                quantity: quantity,
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations.translate(
                                          'quantity_updated_successfully'),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('error_updating_quantity'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent200,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(localizations.translate('update')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    Map<String, dynamic> resource,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.bg100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.bg300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('delete_resource'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.primary300),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('confirm_delete_resource'),
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.text200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${localizations.translate('resource')}: ${resource['resource_name']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            localizations.translate('cancel'),
                            style: TextStyle(color: colors.text200),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await _teamService.deleteTeamResource(
                                widget.teamId,
                                resource['id'],
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations.translate(
                                          'resource_deleted_successfully'),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('error_deleting_resource'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(localizations.translate('delete')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
