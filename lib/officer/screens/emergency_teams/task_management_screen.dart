import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mydpar/officer/screens/emergency_teams/select_task_location_screen.dart';
import 'package:mydpar/officer/screens/emergency_teams/task_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/service/emergency_team_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class TaskManagementScreen extends StatefulWidget {
  final String teamId;
  final bool isLeader;

  const TaskManagementScreen({
    super.key,
    required this.teamId,
    required this.isLeader,
  });

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen>
    with SingleTickerProviderStateMixin {
  final EmergencyTeamService _teamService = EmergencyTeamService();
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                  Tab(text: localizations.translate('active_tasks')),
                  Tab(text: localizations.translate('completed')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active tasks tab
                  _buildTaskList(
                      colors, localizations, ['pending', 'in_progress']),
                  // Completed tasks tab
                  _buildTaskList(
                      colors, localizations, ['completed', 'cancelled']),
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
                localizations.translate('task_management'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                ),
              ),
            ],
          ),
          if (widget.isLeader)
            IconButton(
              icon: Icon(Icons.add, color: colors.accent200),
              onPressed: () => _showAddTaskModal(colors, localizations),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList(AppColorTheme colors, AppLocalizations localizations,
      List<String> statusFilter) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _teamService.getTeamTasks(widget.teamId),
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

        final allTasks = snapshot.data!;
        // Filter tasks based on status
        final tasks = allTasks
            .where((task) =>
                statusFilter.contains(task['status'] as String? ?? 'pending'))
            .toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: colors.bg300),
                const SizedBox(height: 16),
                Text(
                  localizations.translate(statusFilter.contains('completed')
                      ? 'no_completed_tasks'
                      : 'no_active_tasks'),
                  style: TextStyle(color: colors.text200, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _buildTaskCard(
            tasks[index],
            colors,
            localizations,
            isCompleted: statusFilter.contains('completed'),
          ),
        );
      },
    );
  }

  Future<String> _getCityNameFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Return only the city/locality name
        return (p.locality != null && p.locality!.isNotEmpty)
            ? p.locality!
            : '${latLng.latitude}, ${latLng.longitude}';
      }
      return '${latLng.latitude}, ${latLng.longitude}';
    } catch (e) {
      return '${latLng.latitude}, ${latLng.longitude}';
    }
  }

  Widget _buildTaskCard(Map<String, dynamic> task, AppColorTheme colors,
      AppLocalizations localizations,
      {required bool isCompleted}) {
    final status = task['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status, colors);
    final assignedMembers =
        (task['members_assigned'] as Map<String, dynamic>?) ?? {};
    final memberCount = assignedMembers.length;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              teamId: widget.teamId,
              taskId: task['id'],
              isLeader: widget.isLeader,
            ),
          ),
        );
      },
      child: Container(
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
                          task['task_name'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.primary300,
                          ),
                        ),
                      ),
                      if (widget.isLeader && !isCompleted)
                        InkWell(
                          onTap: () =>
                              _showEditTaskModal(task, colors, localizations),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.bg200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: colors.accent200,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task['description'] ?? '',
                    style: TextStyle(color: colors.text200),
                  ),
                  const SizedBox(height: 12),
                  // Row with date and priority/member count information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date information
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: colors.text200),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted && task['completed_date'] != null
                                ? '${localizations.translate('completed')}: ${_formatDate(task['completed_date'])}'
                                : '${localizations.translate('started')}: ${_formatDate(task['start_date'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.text200,
                            ),
                          ),
                        ],
                      ),
                      // Priority or member count
                      Flexible(
                        child: Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.group : Icons.flag,
                              size: 16,
                              color: colors.text200,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isCompleted
                                    ? '$memberCount ${localizations.translate(memberCount == 1 ? 'member_participated' : 'members_participated')}'
                                    : '${localizations.translate('priority')}: ${_capitalize(task['priority'] as String? ?? 'medium')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.text200,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Task chips (status, member count, location)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(
                        _getStatusLabel(status, localizations),
                        statusColor,
                        colors,
                      ),
                      _buildStatusChip(
                        '$memberCount ${localizations.translate(memberCount == 1 ? 'member_assigned' : 'members_assigned')}',
                        Colors.blue,
                        colors,
                      ),
                      FutureBuilder<String>(
                        future: task['start_location'] is LatLng
                            ? _getCityNameFromLatLng(task['start_location'])
                            : Future.value(''),
                        builder: (context, snapshot) {
                          final city = snapshot.data ?? '';
                          return _buildStatusChip(
                            city.isNotEmpty
                                ? city
                                : localizations.translate('location'),
                            Colors.purple,
                            colors,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.bg300)),
              ),
              child: isCompleted
                  ? Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _showTaskSummary(task, colors, localizations),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.description,
                                      size: 16, color: colors.accent200),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations.translate('view_summary'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.accent200,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (widget.isLeader) ...[
                          _buildActionButton(
                            icon: Icons.group,
                            label: localizations.translate('assign_members'),
                            onTap: () => _showAssignMembersModal(
                                task, colors, localizations),
                            colors: colors,
                          ),
                        ],
                        _buildActionButton(
                          icon: Icons.update,
                          label: localizations.translate('update_status'),
                          onTap: () => _showUpdateStatusModal(
                              task, colors, localizations),
                          colors: colors,
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: colors.bg300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: colors.accent200),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.accent200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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

  String _getStatusLabel(String status, AppLocalizations localizations) =>
      switch (status.toLowerCase()) {
        'pending' => localizations.translate('pending'),
        'in_progress' => localizations.translate('in_progress'),
        'completed' => localizations.translate('completed'),
        'cancelled' => localizations.translate('cancelled'),
        _ => status.toUpperCase(),
      };

  Color _getStatusColor(String status, AppColorTheme colors) =>
      switch (status.toLowerCase()) {
        'pending' => Colors.orange,
        'in_progress' => Colors.blue,
        'completed' => Colors.green,
        'cancelled' => Colors.red,
        _ => colors.accent200,
      };

  String _extractLocationName(LatLng location) {
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  void _showAddTaskModal(AppColorTheme colors, AppLocalizations localizations) {
    final TextEditingController taskNameController = TextEditingController();
    final TextEditingController taskDescriptionController =
        TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    final TextEditingController priorityController = TextEditingController();
    final TextEditingController startLocationController =
        TextEditingController();
    final TextEditingController endLocationController = TextEditingController();

    // Set default date to today
    final now = DateTime.now();
    startDateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Store selected locations
    LatLng? startLocation;
    LatLng? endLocation;
    String? startLocationName;
    String? endLocationName;

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
                        localizations.translate('create_new_task'),
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
                          '${localizations.translate('task_name')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: taskNameController,
                          decoration: InputDecoration(
                            hintText:
                                localizations.translate('enter_task_name'),
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
                          controller: taskDescriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: localizations.translate('task_details'),
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
                          '${localizations.translate('start_location')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelectTaskLocationScreen(),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                startLocation = LatLng(
                                  result['latitude'],
                                  result['longitude'],
                                );
                                startLocationName = result['locationName'];
                                startLocationController.text =
                                    startLocationName!;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bg200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.bg300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: colors.accent200),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    startLocationName ??
                                        localizations
                                            .translate('select_start_location'),
                                    style: TextStyle(
                                      color: startLocationName != null
                                          ? colors.text200
                                          : colors.text200.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.translate('end_location'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelectTaskLocationScreen(),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                endLocation = LatLng(
                                  result['latitude'],
                                  result['longitude'],
                                );
                                endLocationName = result['locationName'];
                                endLocationController.text = endLocationName!;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bg200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.bg300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: colors.accent200),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    endLocationName ??
                                        localizations
                                            .translate('select_end_location'),
                                    style: TextStyle(
                                      color: endLocationName != null
                                          ? colors.text200
                                          : colors.text200.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('priority')}*',
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
                              value: priorityController.text.isEmpty
                                  ? null
                                  : priorityController.text,
                              hint: Text(
                                localizations.translate('select_priority'),
                                style: TextStyle(
                                  color: colors.text200.withOpacity(0.5),
                                ),
                              ),
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text(localizations.translate('high')),
                                ),
                                DropdownMenuItem(
                                  value: 'medium',
                                  child:
                                      Text(localizations.translate('medium')),
                                ),
                                DropdownMenuItem(
                                  value: 'low',
                                  child: Text(localizations.translate('low')),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    priorityController.text = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('start_date')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );

                            if (picked != null) {
                              setState(() {
                                startDateController.text =
                                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bg200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.bg300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: colors.accent200),
                                const SizedBox(width: 8),
                                Text(
                                  startDateController.text.isEmpty
                                      ? localizations
                                          .translate('select_start_date')
                                      : startDateController.text,
                                  style: TextStyle(
                                    color: startDateController.text.isEmpty
                                        ? colors.text200.withOpacity(0.5)
                                        : colors.text200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.translate('expected_end_date'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );

                            if (picked != null) {
                              setState(() {
                                endDateController.text =
                                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bg200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.bg300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: colors.accent200),
                                const SizedBox(width: 8),
                                Text(
                                  endDateController.text.isEmpty
                                      ? localizations
                                          .translate('select_end_date')
                                      : endDateController.text,
                                  style: TextStyle(
                                    color: endDateController.text.isEmpty
                                        ? colors.text200.withOpacity(0.5)
                                        : colors.text200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (taskNameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('task_name_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (taskDescriptionController.text.isEmpty) {
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
                              if (startDateController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('start_date_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (priorityController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('priority_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (startLocation == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations
                                          .translate('start_location_required'),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final startDate =
                                  DateTime.parse(startDateController.text);
                              DateTime? expectedEndDate;
                              if (endDateController.text.isNotEmpty) {
                                expectedEndDate =
                                    DateTime.parse(endDateController.text);
                              }

                              try {
                                await _teamService.createTeamTask(
                                  teamId: widget.teamId,
                                  taskName: taskNameController.text,
                                  description: taskDescriptionController.text,
                                  startDate: startDate,
                                  priority: priorityController.text,
                                  startLocation: startLocation!,
                                  endLocation: endLocation,
                                  expectedEndDate: expectedEndDate,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.translate(
                                            'task_created_successfully'),
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
                                            .translate('error_creating_task'),
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
                              localizations.translate('create_task'),
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

  void _showAssignMembersModal(
    Map<String, dynamic> task,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final Map<String, bool> selectedMembers =
        Map<String, bool>.from(task['members_assigned'] ?? {});

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                      localizations.translate('assign_members'),
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
              Flexible(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _teamService.getTeamMembers(widget.teamId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          localizations.translate('error_loading_members'),
                          style: TextStyle(color: colors.warning),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data!;
                    if (members.isEmpty) {
                      return Center(
                        child: Text(
                          localizations.translate('no_members'),
                          style: TextStyle(color: colors.text200),
                        ),
                      );
                    }

                    return StatefulBuilder(
                      builder: (context, setState) => ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final memberId = member['id'];
                          final memberName = member['name'];
                          final memberRole = member['role'] ?? '';

                          return CheckboxListTile(
                            title: Text(
                              '$memberName (${memberRole.isNotEmpty ? memberRole : localizations.translate('member')})',
                              style: TextStyle(color: colors.text200),
                            ),
                            value: selectedMembers[memberId] ?? false,
                            activeColor: colors.accent200,
                            onChanged: (value) {
                              setState(() {
                                selectedMembers[memberId] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.bg300)),
                ),
                child: Row(
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
                          await _teamService.assignMembersToTask(
                            teamId: widget.teamId,
                            taskId: task['id'],
                            membersAssigned: selectedMembers,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.translate('members_assigned'),
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
                                      .translate('error_assigning_members'),
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
                      child: Text(localizations.translate('save')),
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

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Compose a readable address
        return [
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea,
          if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode,
          if (p.country != null && p.country!.isNotEmpty) p.country,
        ].whereType<String>().join(', ');
      }
      return '${latLng.latitude}, ${latLng.longitude}';
    } catch (e) {
      return '${latLng.latitude}, ${latLng.longitude}';
    }
  }

  void _showEditTaskModal(
    Map<String, dynamic> task,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final TextEditingController taskNameController =
        TextEditingController(text: task['task_name']);
    final TextEditingController taskDescriptionController =
        TextEditingController(text: task['description']);
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    final TextEditingController priorityController =
        TextEditingController(text: task['priority']);
    final TextEditingController startLocationController =
        TextEditingController();
    final TextEditingController endLocationController = TextEditingController();

    // Set dates from task data
    final startDate = task['start_date'] as DateTime;
    startDateController.text =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

    if (task['expected_end_date'] != null) {
      final endDate = task['expected_end_date'] as DateTime;
      endDateController.text =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
    }

    LatLng? startLocation = task['start_location'] as LatLng;
    LatLng? endLocation = task['end_location'] as LatLng?;
    String? startLocationName;
    String? endLocationName;

    // Fetch addresses asynchronously and set controllers
    Future<void> _initAddresses() async {
      if (startLocation != null) {
        startLocationName = await _getAddressFromLatLng(startLocation!);
        startLocationController.text = startLocationName!;
      }
      if (endLocation != null) {
        endLocationName = await _getAddressFromLatLng(endLocation!);
        endLocationController.text = endLocationName!;
      }
    }

    // Show dialog after addresses are loaded
    showDialog(
      context: context,
      builder: (context) => FutureBuilder(
        future: _initAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return StatefulBuilder(
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
                            localizations.translate('edit_task'),
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
                              '${localizations.translate('task_name')}*',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.text200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: taskNameController,
                              decoration: InputDecoration(
                                hintText:
                                    localizations.translate('enter_task_name'),
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
                                  borderSide:
                                      BorderSide(color: colors.accent200),
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
                              controller: taskDescriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    localizations.translate('task_details'),
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
                                  borderSide:
                                      BorderSide(color: colors.accent200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${localizations.translate('start_location')}*',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.text200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SelectTaskLocationScreen(),
                                  ),
                                );
                                if (result != null) {
                                  setState(() async {
                                    startLocation = LatLng(
                                      result['latitude'],
                                      result['longitude'],
                                    );
                                    startLocationName =
                                        await _getAddressFromLatLng(
                                            startLocation!);
                                    startLocationController.text =
                                        startLocationName!;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.bg200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.bg300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: colors.accent200),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        startLocationName ??
                                            localizations.translate(
                                                'select_start_location'),
                                        style: TextStyle(
                                          color: startLocationName != null
                                              ? colors.text200
                                              : colors.text200.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.translate('end_location'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.text200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SelectTaskLocationScreen(),
                                  ),
                                );
                                if (result != null) {
                                  setState(() async {
                                    endLocation = LatLng(
                                      result['latitude'],
                                      result['longitude'],
                                    );
                                    endLocationName =
                                        await _getAddressFromLatLng(
                                            endLocation!);
                                    endLocationController.text =
                                        endLocationName!;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.bg200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.bg300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: colors.accent200),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        endLocationName ??
                                            localizations.translate(
                                                'select_end_location'),
                                        style: TextStyle(
                                          color: endLocationName != null
                                              ? colors.text200
                                              : colors.text200.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${localizations.translate('priority')}*',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.text200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: colors.bg200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.bg300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: priorityController.text.isEmpty
                                      ? null
                                      : priorityController.text,
                                  hint: Text(
                                    localizations.translate('select_priority'),
                                    style: TextStyle(
                                      color: colors.text200.withOpacity(0.5),
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'high',
                                      child:
                                          Text(localizations.translate('high')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'medium',
                                      child: Text(
                                          localizations.translate('medium')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'low',
                                      child:
                                          Text(localizations.translate('low')),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        priorityController.text = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${localizations.translate('start_date')}*',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.text200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    startDateController.text =
                                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.bg200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.bg300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: colors.accent200),
                                    const SizedBox(width: 8),
                                    Text(
                                      startDateController.text.isEmpty
                                          ? localizations
                                              .translate('select_start_date')
                                          : startDateController.text,
                                      style: TextStyle(
                                        color: startDateController.text.isEmpty
                                            ? colors.text200.withOpacity(0.5)
                                            : colors.text200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.translate('expected_end_date'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.text200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: task['expected_end_date'] != null
                                      ? task['expected_end_date'] as DateTime
                                      : DateTime.now()
                                          .add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    endDateController.text =
                                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.bg200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.bg300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: colors.accent200),
                                    const SizedBox(width: 8),
                                    Text(
                                      endDateController.text.isEmpty
                                          ? localizations
                                              .translate('select_end_date')
                                          : endDateController.text,
                                      style: TextStyle(
                                        color: endDateController.text.isEmpty
                                            ? colors.text200.withOpacity(0.5)
                                            : colors.text200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (taskNameController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations
                                            .translate('task_name_required')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (taskDescriptionController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations
                                            .translate('description_required')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (startDateController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations
                                            .translate('start_date_required')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (priorityController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations
                                            .translate('priority_required')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (startLocation == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations.translate(
                                            'start_location_required')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final startDate =
                                      DateTime.parse(startDateController.text);
                                  DateTime? expectedEndDate;
                                  if (endDateController.text.isNotEmpty) {
                                    expectedEndDate =
                                        DateTime.parse(endDateController.text);
                                  }

                                  try {
                                    await _teamService.updateTeamTask(
                                      teamId: widget.teamId,
                                      taskId: task['id'],
                                      taskName: taskNameController.text,
                                      description:
                                          taskDescriptionController.text,
                                      startDate: startDate,
                                      priority: priorityController.text,
                                      startLocation: startLocation,
                                      endLocation: endLocation,
                                      expectedEndDate: expectedEndDate,
                                    );

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(localizations.translate(
                                              'task_updated_successfully')),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(localizations.translate(
                                              'error_updating_task')),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accent200,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  localizations.translate('update_task'),
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
          );
        },
      ),
    );
  }

  void _showUpdateStatusModal(
    Map<String, dynamic> task,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final currentStatus = task['status'] as String? ?? 'pending';
    String selectedStatus = currentStatus;

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
                      localizations.translate('update_status'),
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
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        localizations.translate('pending'),
                        style: TextStyle(color: colors.text200),
                      ),
                      value: 'pending',
                      groupValue: selectedStatus,
                      activeColor: colors.accent200,
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(
                        localizations.translate('in_progress'),
                        style: TextStyle(color: colors.text200),
                      ),
                      value: 'in_progress',
                      groupValue: selectedStatus,
                      activeColor: colors.accent200,
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(
                        localizations.translate('completed'),
                        style: TextStyle(color: colors.text200),
                      ),
                      value: 'completed',
                      groupValue: selectedStatus,
                      activeColor: colors.accent200,
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(
                        localizations.translate('cancelled'),
                        style: TextStyle(color: colors.text200),
                      ),
                      value: 'cancelled',
                      groupValue: selectedStatus,
                      activeColor: colors.accent200,
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.bg300)),
                ),
                child: Row(
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
                          await _teamService.updateTaskStatus(
                            teamId: widget.teamId,
                            taskId: task['id'],
                            status: selectedStatus,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.translate('status_updated'),
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
                                      .translate('error_updating_status'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showTaskSummary(
    Map<String, dynamic> task,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                      localizations.translate('task_details'),
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
                        localizations.translate('task_name'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.text200,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task['task_name'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('description'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.text200,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task['description'] ?? '',
                        style: TextStyle(color: colors.text200),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('start_date'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.text200,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(task['start_date']),
                        style: TextStyle(color: colors.text200),
                      ),
                      if (task['completed_date'] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          localizations.translate('completed_date'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(task['completed_date']),
                          style: TextStyle(color: colors.text200),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('priority'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.text200,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _capitalize(task['priority'] as String? ?? 'medium'),
                        style: TextStyle(color: colors.text200),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('status'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.text200,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(
                        _getStatusLabel(task['status'] as String? ?? 'pending',
                            localizations),
                        _getStatusColor(
                            task['status'] as String? ?? 'pending', colors),
                        colors,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('assigned_members'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.text200,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAssignedMembersList(task, colors, localizations),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedMembersList(
    Map<String, dynamic> task,
    AppColorTheme colors,
    AppLocalizations localizations,
  ) {
    final assignedMembers =
        (task['members_assigned'] as Map<String, dynamic>?) ?? {};

    if (assignedMembers.isEmpty) {
      return Text(
        localizations.translate('no_members_assigned'),
        style: TextStyle(color: colors.text200, fontStyle: FontStyle.italic),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _teamService.getTeamMembers(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return Text(
            localizations.translate('error_loading_members'),
            style: TextStyle(color: colors.warning),
          );
        }

        final allMembers = snapshot.data!;
        final List<Widget> memberWidgets = [];

        for (var memberId in assignedMembers.keys) {
          if (assignedMembers[memberId] == true) {
            final memberInfo = allMembers.firstWhere(
              (m) => m['id'] == memberId,
              orElse: () => {'name': 'Unknown', 'role': ''},
            );

            memberWidgets.add(
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bg200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: colors.text200),
                    const SizedBox(width: 8),
                    Text(
                      '${memberInfo['name']} (${memberInfo['role'] ?? localizations.translate('member')})',
                      style: TextStyle(color: colors.text200),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return Column(children: memberWidgets);
      },
    );
  }
}
