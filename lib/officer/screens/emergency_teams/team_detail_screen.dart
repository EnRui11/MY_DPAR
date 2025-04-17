import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/service/emergency_team_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen for displaying detailed information about an emergency team.
class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  final EmergencyTeamService _teamService = EmergencyTeamService();
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _teamData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads the team data from Firestore.
  Future<void> _loadTeamData() async {
    setState(() => _isLoading = true);
    try {
      final teamData = await _teamService.getTeam(widget.teamId);
      if (mounted) {
        setState(() {
          _teamData = teamData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(
            AppLocalizations.of(context)!.translate('failed_to_load_team'), e);
      }
    }
  }

  /// Shows the team options bottom sheet.
  void _showTeamOptionsSheet(BuildContext context, AppColorTheme colors) {
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bg100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.translate('team_options'),
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
              const SizedBox(height: 24),
              _buildOptionButton(
                icon: Icons.history,
                label: localizations.translate('view_team_history'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to team history screen
                },
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildOptionButton(
                icon: Icons.archive,
                label: localizations.translate('archive_team'),
                onTap: () {
                  Navigator.pop(context);
                  _archiveTeam(colors, localizations);
                },
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildOptionButton(
                icon: Icons.delete,
                label: localizations.translate('delete_team'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(colors, localizations);
                },
                colors: colors,
                isDestructive: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an option button for the team options sheet.
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColorTheme colors,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? colors.warning : colors.accent200;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? colors.warning : colors.text200,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog for deleting a team.
  void _showDeleteConfirmation(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('confirm_delete'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Text(
          localizations.translate(
            'delete_team_confirmation',
            {'teamName': _teamData?['name'] ?? ''},
          ),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              localizations.translate('delete'),
              style: TextStyle(color: colors.warning),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteTeam(colors, localizations);
            },
          ),
        ],
      ),
    );
  }

  /// Archives the team.
  Future<void> _archiveTeam(
      AppColorTheme colors, AppLocalizations localizations) async {
    try {
      await _teamService.updateTeam(
        teamId: widget.teamId,
        status: 'archived',
      );
      if (mounted) {
        _showSnackBar(
          localizations.translate('team_archived'),
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          localizations.translate('failed_to_archive_team'),
          e,
        );
      }
    }
  }

  /// Deletes the team.
  Future<void> _deleteTeam(
      AppColorTheme colors, AppLocalizations localizations) async {
    try {
      await _teamService.deleteTeam(widget.teamId);
      if (mounted) {
        _showSnackBar(
          localizations.translate('team_deleted'),
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          localizations.translate('failed_to_delete_team'),
          e,
        );
      }
    }
  }

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
          content: Text('$message: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Provider.of<ThemeProvider>(context, listen: true).currentTheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: _isLoading || _teamData == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(colors, localizations),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTeamHeader(colors, localizations),
                            const SizedBox(height: 24),
                            _buildTabBar(colors),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 400, // Adjust based on content
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildMembersTab(colors, localizations),
                                  _buildTasksTab(colors, localizations),
                                  _buildResourcesTab(colors, localizations),
                                ],
                              ),
                            ),
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

  /// Builds the app header with back button and action buttons.
  Widget _buildHeader(AppColorTheme colors, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
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
                localizations.translate('team_detail'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: colors.accent200),
                onPressed: () {
                  // TODO: Navigate to edit team screen
                },
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: colors.primary300),
                onPressed: () => _showTeamOptionsSheet(context, colors),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the team header with avatar, name, type, status, and statistics.
  Widget _buildTeamHeader(
      AppColorTheme colors, AppLocalizations localizations) {
    final isOfficial = _teamData?['type'] == 'official';
    final status = _teamData?['status'] as String? ?? 'standby';
    final statusColor = _getStatusColor(status, colors);
    final typeColor = isOfficial ? colors.accent200 : colors.primary200;
    final memberCount = _teamData?['member_count'] as int? ?? 0;
    final taskCount = _teamData?['task_count'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _teamData?['name']
                          .substring(0, _min(2, _teamData?['name'].length ?? 0))
                          .toUpperCase() ??
                      '',
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
                    _teamData?['name'] ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.primary300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusChip(
                        isOfficial
                            ? localizations.translate('official')
                            : localizations.translate('volunteer'),
                        typeColor,
                        colors,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        _getStatusLabel(status, localizations),
                        statusColor,
                        colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _teamData?['description'] ?? '',
          style: TextStyle(color: colors.text200),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                localizations.translate('members'),
                memberCount.toString(),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                localizations.translate('active_tasks'),
                taskCount.toString(),
                colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a statistics card with a label and value.
  Widget _buildStatCard(String label, String value, AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.bg300),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.accent200,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.text200,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the tab bar for switching between members, tasks, and resources.
  Widget _buildTabBar(AppColorTheme colors) {
    return TabBar(
      controller: _tabController,
      labelColor: colors.accent200,
      unselectedLabelColor: colors.text200,
      indicatorColor: colors.accent200,
      indicatorWeight: 2,
      tabs: [
        Tab(text: AppLocalizations.of(context)!.translate('members')),
        Tab(text: AppLocalizations.of(context)!.translate('tasks')),
        Tab(text: AppLocalizations.of(context)!.translate('resources')),
      ],
    );
  }

  /// Builds the members tab content.
  Widget _buildMembersTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _teamService.getTeamMembers(widget.teamId),
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

        final members = snapshot.data!;
        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: colors.bg300),
                const SizedBox(height: 16),
                Text(
                  localizations.translate('no_members'),
                  style: TextStyle(color: colors.text200, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to add member screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(localizations.translate('add_member')),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.translate('team_members'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to manage members screen
                  },
                  child: Text(
                    localizations.translate('manage'),
                    style: TextStyle(color: colors.accent200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isLeader = member['role'] == 'leader';
                  final status = member['status'] as String? ?? 'active';
                  final statusColor = _getMemberStatusColor(status, colors);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bg100.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.bg300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isLeader ? 48 : 40,
                          height: isLeader ? 48 : 40,
                          decoration: BoxDecoration(
                            color:
                                isLeader ? colors.accent200 : colors.primary200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              member['name']
                                  .substring(0, _min(2, member['name'].length))
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'],
                                style: TextStyle(
                                  fontWeight: isLeader
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: colors.primary300,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isLeader)
                                    _buildStatusChip(
                                      localizations.translate('team_leader'),
                                      Colors.amber,
                                      colors,
                                    ),
                                  if (isLeader) const SizedBox(width: 8),
                                  Text(
                                    member['role'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.text200,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(
                                    _getMemberStatusLabel(
                                        status, localizations),
                                    statusColor,
                                    colors,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.phone, color: colors.accent200),
                          onPressed: () {
                            // TODO: Implement call functionality
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the tasks tab content.
  Widget _buildTasksTab(AppColorTheme colors, AppLocalizations localizations) {
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

        final tasks = snapshot.data!;
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: colors.bg300),
                const SizedBox(height: 16),
                Text(
                  localizations.translate('no_tasks'),
                  style: TextStyle(color: colors.text200, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to add task screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(localizations.translate('add_task')),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.translate('current_tasks'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to manage tasks screen
                  },
                  child: Text(
                    localizations.translate('manage'),
                    style: TextStyle(color: colors.accent200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final status = task['status'] as String? ?? 'pending';
                  final statusColor = _getTaskStatusColor(status, colors);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bg100.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.bg300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              task['title'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.primary300,
                              ),
                            ),
                            _buildStatusChip(
                              _getTaskStatusLabel(status, localizations),
                              statusColor,
                              colors,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task['description'] ?? '',
                          style: TextStyle(color: colors.text200),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: colors.text200),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimestamp(task['assigned_at']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.text200,
                                  ),
                                ),
                              ],
                            ),
                            if (task['started_at'] != null)
                              Row(
                                children: [
                                  Icon(Icons.play_circle_outline,
                                      size: 16, color: colors.text200),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimestamp(task['started_at']),
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
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the resources tab content.
  Widget _buildResourcesTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _teamService.getTeamResources(widget.teamId),
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
                  localizations.translate('no_resources'),
                  style: TextStyle(color: colors.text200, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to add resource screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(localizations.translate('add_resource')),
                ),
              ],
            ),
          );
        }

        // Group resources by type
        final Map<String, List<Map<String, dynamic>>> groupedResources = {};
        for (final resource in resources) {
          final type = resource['resource_type'] as String? ?? 'other';
          if (!groupedResources.containsKey(type)) {
            groupedResources[type] = [];
          }
          groupedResources[type]!.add(resource);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.translate('equipment_resources'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to manage resources screen
                  },
                  child: Text(
                    localizations.translate('manage'),
                    style: TextStyle(color: colors.accent200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: groupedResources.length,
                itemBuilder: (context, index) {
                  final type = groupedResources.keys.elementAt(index);
                  final typeResources = groupedResources[type]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bg100.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.bg300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getResourceTypeLabel(type, localizations),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.primary300,
                              ),
                            ),
                            Text(
                              '${typeResources.length} ${localizations.translate('items')}',
                              style: TextStyle(
                                color: colors.accent200,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...typeResources.map((resource) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  resource['description'] ?? '',
                                  style: TextStyle(color: colors.text200),
                                ),
                                Text(
                                  '${resource['quantity']} ${resource['unit']}',
                                  style: TextStyle(color: colors.text200),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds a status chip with a label and color.
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

  /// Returns the localized label for team status.
  String _getStatusLabel(String status, AppLocalizations localizations) =>
      switch (status.toLowerCase()) {
        'active' => localizations.translate('active'),
        'standby' => localizations.translate('on_standby'),
        'deactivated' => localizations.translate('deactivated'),
        'archived' => localizations.translate('archived'),
        _ => status.toUpperCase(),
      };

  /// Returns the localized label for member status.
  String _getMemberStatusLabel(String status, AppLocalizations localizations) =>
      switch (status.toLowerCase()) {
        'active' => localizations.translate('on_duty'),
        'inactive' => localizations.translate('off_duty'),
        _ => status.toUpperCase(),
      };

  /// Returns the localized label for task status.
  String _getTaskStatusLabel(String status, AppLocalizations localizations) =>
      switch (status.toLowerCase()) {
        'pending' => localizations.translate('pending'),
        'in_progress' => localizations.translate('in_progress'),
        'completed' => localizations.translate('completed'),
        'cancelled' => localizations.translate('cancelled'),
        _ => status.toUpperCase(),
      };

  /// Returns the localized label for resource type.
  String _getResourceTypeLabel(String type, AppLocalizations localizations) =>
      switch (type.toLowerCase()) {
        'rescue_equipment' => localizations.translate('rescue_equipment'),
        'medical_supplies' => localizations.translate('medical_supplies'),
        'communication' => localizations.translate('communication_equipment'),
        'transportation' => localizations.translate('transportation'),
        'other' => localizations.translate('other_resources'),
        _ => type,
      };

  /// Returns the color for a team status.
  Color _getStatusColor(String status, AppColorTheme colors) =>
      switch (status.toLowerCase()) {
        'active' => Colors.green,
        'standby' => Colors.orange,
        'deactivated' => Colors.grey,
        'archived' => Colors.purple,
        _ => colors.accent200,
      };

  /// Returns the color for a member status.
  Color _getMemberStatusColor(String status, AppColorTheme colors) =>
      switch (status.toLowerCase()) {
        'active' => Colors.green,
        'inactive' => Colors.grey,
        _ => colors.accent200,
      };

  /// Returns the color for a task status.
  Color _getTaskStatusColor(String status, AppColorTheme colors) =>
      switch (status.toLowerCase()) {
        'pending' => Colors.orange,
        'in_progress' => Colors.blue,
        'completed' => Colors.green,
        'cancelled' => Colors.red,
        _ => colors.accent200,
      };

  /// Formats a Firestore timestamp for display.
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    final DateTime dateTime =
        timestamp is Timestamp ? timestamp.toDate() : DateTime.now();

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns the minimum of two integers.
  int _min(int a, int b) => a < b ? a : b;
}
