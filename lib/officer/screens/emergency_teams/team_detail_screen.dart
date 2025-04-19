import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/service/emergency_team_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydpar/officer/screens/emergency_teams/select_task_location_screen.dart';
import 'package:mydpar/officer/screens/emergency_teams/task_management_screen.dart';
import 'package:mydpar/officer/screens/emergency_teams/task_detail_screen.dart';
import 'package:flutter/services.dart';

/// Screen for displaying detailed information about an emergency team.
class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  final bool isLeader;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.isLeader,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  final EmergencyTeamService _teamService = EmergencyTeamService();
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _teamData;
  bool _isOnDuty = false;
  String _userRole = '';
  TextEditingController _roleController = TextEditingController();
  Map<String, dynamic>? _userMemberInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeamData();
    _loadUserMemberInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roleController.dispose();
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

  /// Loads the current user's member information
  Future<void> _loadUserMemberInfo() async {
    try {
      final userMemberInfo =
          await _teamService.getUserMemberInfo(widget.teamId);
      if (mounted && userMemberInfo != null) {
        setState(() {
          _userMemberInfo = userMemberInfo;
          _isOnDuty = userMemberInfo['status'] == 'active';
          _userRole = userMemberInfo['role'] ?? '';
          _roleController.text = _userRole;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!.translate('failed_to_load_user_info'),
            e);
      }
    }
  }

  /// Updates the user's role
  Future<void> _updateUserRole(String role) async {
    try {
      await _teamService.updateUserRole(
        teamId: widget.teamId,
        role: role,
      );
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.translate('role_updated'),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          AppLocalizations.of(context)!.translate('failed_to_update_role'),
          e,
        );
      }
    }
  }

  /// Updates the user's duty status
  Future<void> _updateUserDutyStatus(bool isOnDuty) async {
    try {
      await _teamService.updateUserDutyStatus(
        teamId: widget.teamId,
        isOnDuty: isOnDuty,
      );
      if (mounted) {
        setState(() {
          _isOnDuty = isOnDuty;
        });
        _showSnackBar(
          isOnDuty
              ? AppLocalizations.of(context)!.translate('now_on_duty')
              : AppLocalizations.of(context)!.translate('now_off_duty'),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          AppLocalizations.of(context)!
              .translate('failed_to_update_duty_status'),
          e,
        );
      }
    }
  }

  /// Shows the team options menu when more vert icon is clicked
  void _showTeamOptionsMenu(BuildContext context, AppColorTheme colors,
      AppLocalizations localizations) {
    final isLeader = _userRole == 'leader';
    final teamStatus = _teamData?['status'] as String? ?? 'standby';

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
            if (isLeader) ...[
              ListTile(
                leading: Icon(Icons.edit, color: colors.accent200),
                title: Text(localizations.translate('edit_team_details'),
                    style: TextStyle(color: colors.text200)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTeamDialog(colors, localizations);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: colors.accent200),
                title: Text(localizations.translate('share_team'),
                    style: TextStyle(color: colors.text200)),
                onTap: () {
                  Navigator.pop(context);
                  _shareTeamId(colors, localizations);
                },
              ),
              if (teamStatus != 'active')
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.green),
                  title: Text(localizations.translate('activate_team'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _updateTeamStatus('active');
                  },
                ),
              if (teamStatus != 'standby')
                ListTile(
                  leading: const Icon(Icons.pause, color: Colors.orange),
                  title: Text(localizations.translate('set_to_standby'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _updateTeamStatus('standby');
                  },
                ),
              if (teamStatus != 'deactivated')
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.grey),
                  title: Text(localizations.translate('deactivate_team'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _updateTeamStatus('deactivated');
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.warning),
                title: Text(localizations.translate('delete_team'),
                    style: TextStyle(color: colors.warning)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(colors, localizations);
                },
              ),
            ],
            if (!isLeader)
              ListTile(
                leading: Icon(Icons.exit_to_app, color: colors.warning),
                title: Text(localizations.translate('quit_team'),
                    style: TextStyle(color: colors.warning)),
                onTap: () {
                  Navigator.pop(context);
                  _quitTeam(colors, localizations);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Updates the team status
  Future<void> _updateTeamStatus(String status) async {
    try {
      await _teamService.updateTeam(
        teamId: widget.teamId,
        status: status,
      );
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.translate('team_status_updated'),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          AppLocalizations.of(context)!
              .translate('failed_to_update_team_status'),
          e,
        );
      }
    }
  }

  /// Shares the team ID by copying it to clipboard
  void _shareTeamId(AppColorTheme colors, AppLocalizations localizations) {
    Clipboard.setData(ClipboardData(text: widget.teamId));
    _showSnackBar(localizations.translate('team_id_copied'));
  }

  /// Handles the quit team action
  Future<void> _quitTeam(
      AppColorTheme colors, AppLocalizations localizations) async {
    try {
      final userId = _userMemberInfo?['id'];
      final userRole = _userMemberInfo?['collection'] == 'official_members'
          ? 'officer'
          : 'volunteer';

      if (userId == null) {
        throw Exception('User information not found');
      }

      await _teamService.quitTeam(widget.teamId, userId, userRole);

      if (mounted) {
        _showSnackBar(localizations.translate('successfully_quit_team'));
        Navigator.pop(context); // Return to previous screen after quitting
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          localizations.translate('failed_to_quit_team'),
          e,
        );
      }
    }
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

  /// Deletes the team.
  Future<void> _deleteTeam(
      AppColorTheme colors, AppLocalizations localizations) async {
    try {
      await _teamService.deleteTeam(widget.teamId);
      if (mounted) {
        _showSnackBar(
          localizations.translate('team_deleted'),
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
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
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

  /// Shows edit team details dialog
  void _showEditTeamDialog(
      AppColorTheme colors, AppLocalizations localizations) {
    final TextEditingController nameController =
        TextEditingController(text: _teamData?['name'] ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: _teamData?['description'] ?? '');
    final TextEditingController contactController =
        TextEditingController(text: _teamData?['contact'] ?? '');
    final TextEditingController locationTextController =
        TextEditingController(text: _teamData?['location_text'] ?? '');
    String selectedType = _teamData?['type'] ?? 'official';
    String selectedSpecialization = _teamData?['specialization'] ?? 'general';

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
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.bg300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.translate('edit_team_details'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.primary300,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.primary300),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Team Name
                        Text(
                          '${localizations.translate('team_name')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText:
                                localizations.translate('enter_team_name'),
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

                        // Description
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
                                localizations.translate('team_description'),
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

                        // Contact
                        Text(
                          '${localizations.translate('contact')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: contactController,
                          decoration: InputDecoration(
                            hintText: localizations.translate('enter_contact'),
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

                        // Location Text
                        Text(
                          '${localizations.translate('location')}*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locationTextController,
                          decoration: InputDecoration(
                            hintText: localizations.translate('enter_location'),
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

                        // Team Type
                        Text(
                          '${localizations.translate('team_type')}*',
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
                              value: selectedType,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'official',
                                  child:
                                      Text(localizations.translate('official')),
                                ),
                                DropdownMenuItem(
                                  value: 'volunteer',
                                  child: Text(
                                      localizations.translate('volunteer')),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => selectedType = value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Specialization
                        Text(
                          '${localizations.translate('specialization')}*',
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
                              value: selectedSpecialization,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'rescue',
                                  child: Text(localizations
                                      .translate('search_and_rescue')),
                                ),
                                DropdownMenuItem(
                                  value: 'medical',
                                  child:
                                      Text(localizations.translate('medical')),
                                ),
                                DropdownMenuItem(
                                  value: 'fire',
                                  child: Text(
                                      localizations.translate('fire_response')),
                                ),
                                DropdownMenuItem(
                                  value: 'logistics',
                                  child: Text(localizations
                                      .translate('logistics_and_supply')),
                                ),
                                DropdownMenuItem(
                                  value: 'evacuation',
                                  child: Text(
                                      localizations.translate('evacuation')),
                                ),
                                DropdownMenuItem(
                                  value: 'general',
                                  child: Text(localizations
                                      .translate('general_response')),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(
                                      () => selectedSpecialization = value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Validate required fields
                              if (nameController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('team_name_required'));
                                return;
                              }
                              if (descriptionController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('description_required'));
                                return;
                              }
                              if (contactController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('contact_required'));
                                return;
                              }
                              if (locationTextController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('location_required'));
                                return;
                              }

                              try {
                                await _teamService.updateTeam(
                                  teamId: widget.teamId,
                                  name: nameController.text,
                                  type: selectedType,
                                  description: descriptionController.text,
                                  contact: contactController.text,
                                  specialization: selectedSpecialization,
                                  locationText: locationTextController.text,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  _showSnackBar(localizations
                                      .translate('team_updated_successfully'));
                                  // Refresh team data
                                  _loadTeamData();
                                }
                              } catch (e) {
                                if (mounted) {
                                  _showErrorSnackBar(
                                    localizations
                                        .translate('failed_to_update_team'),
                                    e,
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
                              localizations.translate('update_team'),
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
          IconButton(
            icon: Icon(Icons.more_vert, color: colors.primary300),
            onPressed: () =>
                _showTeamOptionsMenu(context, colors, localizations),
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
        final currentUserId = _userMemberInfo?['id'];
        final isOfficialTeam = _teamData?['type'] == 'official';
        final isCurrentUserLeader = _userMemberInfo?['role'] == 'leader';

        // Sort members: current user first, then leader, then others
        members.sort((a, b) {
          if (a['id'] == currentUserId) return -1;
          if (b['id'] == currentUserId) return 1;
          if (a['role'] == 'leader') return -1;
          if (b['role'] == 'leader') return 1;
          return 0;
        });

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Text(
              localizations.translate('team_members'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primary300,
              ),
            ),
            const SizedBox(height: 16),
            if (members.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: colors.bg300),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('no_members'),
                      style: TextStyle(color: colors.text200, fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              ...members.map((member) {
                final isCurrentUser = member['id'] == currentUserId;
                final isLeader = member['role'] == 'leader';
                final status = member['status'] as String? ?? 'active';
                final statusColor = _getMemberStatusColor(status, colors);
                final collection =
                    member['collection'] as String? ?? 'official_members';
                final isOfficialMember = collection == 'official_members';

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
                        children: [
                          Container(
                            width: isLeader ? 48 : 40,
                            height: isLeader ? 48 : 40,
                            decoration: BoxDecoration(
                              color: isLeader
                                  ? colors.accent200
                                  : isOfficialMember
                                      ? colors.primary200
                                      : colors.primary100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                member['name']
                                    .substring(
                                        0, _min(2, member['name'].length))
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
                                Wrap(
                                  children: [
                                    if (isLeader)
                                      _buildStatusChip(
                                        localizations.translate('team_leader'),
                                        Colors.amber,
                                        colors,
                                      )
                                    else
                                      _buildStatusChip(
                                        member['role'] ?? '',
                                        colors.primary200,
                                        colors,
                                      ),
                                    if (isCurrentUser) ...[
                                      if (isLeader) const SizedBox(width: 8),
                                      _buildStatusChip(
                                        localizations.translate('me'),
                                        colors.accent200,
                                        colors,
                                      ),
                                    ],
                                    if (!isLeader && !isOfficialTeam) ...[
                                      if (isLeader || isCurrentUser)
                                        const SizedBox(width: 8),
                                      _buildStatusChip(
                                        isOfficialMember
                                            ? localizations
                                                .translate('official')
                                            : localizations
                                                .translate('volunteer'),
                                        isOfficialMember
                                            ? colors.primary200
                                            : colors.primary100,
                                        colors,
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    if (!isCurrentUser || !isLeader)
                                      _buildStatusChip(
                                        status == 'active'
                                            ? localizations.translate('on_duty')
                                            : localizations
                                                .translate('off_duty'),
                                        status == 'active'
                                            ? Colors.green
                                            : Colors.grey,
                                        colors,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isCurrentUser && isCurrentUserLeader)
                            PopupMenuButton<String>(
                              icon:
                                  Icon(Icons.more_vert, color: colors.text200),
                              onSelected: (value) {
                                if (value == 'call') {
                                  _callMember(member['contact']);
                                } else if (value == 'remove') {
                                  _showRemoveMemberDialog(
                                      colors, localizations, member);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'call',
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone,
                                          color: colors.accent200, size: 20),
                                      const SizedBox(width: 8),
                                      Text(localizations.translate('call')),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_remove,
                                          color: colors.warning, size: 20),
                                      const SizedBox(width: 8),
                                      Text(localizations.translate('remove')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (!isCurrentUser && !isCurrentUserLeader)
                            IconButton(
                              icon: Icon(Icons.phone, color: colors.accent200),
                              onPressed: () => _callMember(member['contact']),
                            ),
                          if (isCurrentUser && isLeader)
                            Row(
                              children: [
                                Switch(
                                  value: _isOnDuty,
                                  onChanged: (value) {
                                    setState(() {
                                      _isOnDuty = value;
                                    });
                                    _updateUserDutyStatus(value);
                                  },
                                  activeColor: colors.accent200,
                                ),
                              ],
                            ),
                          if (isCurrentUser && !isLeader)
                            PopupMenuButton<String>(
                              icon:
                                  Icon(Icons.more_vert, color: colors.text200),
                              onSelected: (value) {
                                if (value == 'change_duty_status') {
                                  _updateUserDutyStatus(!_isOnDuty);
                                } else if (value == 'change_role') {
                                  _showChangeRoleDialog(colors, localizations);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'change_duty_status',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isOnDuty
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: colors.accent200,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isOnDuty
                                            ? localizations
                                                .translate('go_off_duty')
                                            : localizations
                                                .translate('go_on_duty'),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'change_role',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit,
                                          color: colors.accent200, size: 20),
                                      const SizedBox(width: 8),
                                      Text(localizations
                                          .translate('change_role')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        );
      },
    );
  }

  void _showChangeRoleDialog(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('change_role'),
          style: TextStyle(color: colors.primary300),
        ),
        content: TextField(
          controller: _roleController,
          decoration: InputDecoration(
            labelText: localizations.translate('new_role'),
            labelStyle: TextStyle(color: colors.text200),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.text200),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _updateUserRole(_roleController.text);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent200,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.translate('update')),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog to remove a team member
  void _showRemoveMemberDialog(AppColorTheme colors,
      AppLocalizations localizations, Map<String, dynamic> member) {
    final collection = member['collection'] as String? ?? 'official_members';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('remove_member'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Text(
          localizations.translate(
            'remove_member_confirmation',
            {'name': member['name']},
          ),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.text200),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _teamService.removeTeamMember(
                  teamId: widget.teamId,
                  userId: member['id'],
                  collection: collection,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar(
                    localizations.translate('member_removed'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar(
                    localizations.translate('failed_to_remove_member'),
                    e,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.translate('remove')),
          ),
        ],
      ),
    );
  }

  /// Calls a team member using their contact information.
  void _callMember(String? contact) {
    if (contact == null || contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.translate('no_contact_info')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Launch phone call
    final Uri phoneUri = Uri(scheme: 'tel', path: contact);
    launchUrl(phoneUri).then((launched) {
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .translate('could_not_launch_phone')),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// Shows the add task modal
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
    final TextEditingController completedDateController =
        TextEditingController();

    // Set default date to today
    final now = DateTime.now();
    startDateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Store selected members
    final Map<String, bool> selectedMembers = {};

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
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.bg300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.translate('create_new_task'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.primary300,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.primary300),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Name
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

                        // Description
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

                        // Start Location
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
                                horizontal: 16, vertical: 12),
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

                        // End Location (Optional)
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
                                horizontal: 16, vertical: 12),
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

                        // Priority
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
                                    color: colors.text200.withOpacity(0.5)),
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

                        // Start Date
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
                                horizontal: 16, vertical: 12),
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

                        // Completed Date (Optional)
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
                                completedDateController.text =
                                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
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
                                  completedDateController.text.isEmpty
                                      ? localizations
                                          .translate('select_end_date')
                                      : completedDateController.text,
                                  style: TextStyle(
                                    color: completedDateController.text.isEmpty
                                        ? colors.text200.withOpacity(0.5)
                                        : colors.text200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Assign Members
                        Text(
                          localizations.translate('assign_members'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.text200,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: colors.bg200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.bg300),
                          ),
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _teamService.getTeamMembers(widget.teamId),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    localizations
                                        .translate('error_loading_members'),
                                    style: TextStyle(color: colors.warning),
                                  ),
                                );
                              }

                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
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

                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
                                  final memberId = member['id'];
                                  final memberName = member['name'];
                                  final memberRole = member['role'] ?? '';

                                  // Initialize selected state if not already set
                                  if (!selectedMembers.containsKey(memberId)) {
                                    selectedMembers[memberId] = false;
                                  }

                                  return CheckboxListTile(
                                    title: Text(
                                      '$memberName (${memberRole.isNotEmpty ? memberRole : localizations.translate('member')})',
                                      style: TextStyle(color: colors.text200),
                                    ),
                                    value: selectedMembers[memberId],
                                    activeColor: colors.accent200,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedMembers[memberId] =
                                            value ?? false;
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Create Task Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Validate required fields
                              if (taskNameController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('task_name_required'));
                                return;
                              }
                              if (taskDescriptionController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('description_required'));
                                return;
                              }
                              if (startDateController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('start_date_required'));
                                return;
                              }
                              if (priorityController.text.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('priority_required'));
                                return;
                              }
                              if (selectedMembers.isEmpty) {
                                _showSnackBar(localizations
                                    .translate('members_required'));
                                return;
                              }
                              if (startLocation == null) {
                                _showSnackBar(localizations
                                    .translate('start_location_required'));
                                return;
                              }

                              // Get selected members
                              final Map<String, dynamic> membersAssigned = {};
                              selectedMembers.forEach((memberId, isSelected) {
                                if (isSelected) {
                                  membersAssigned[memberId] = true;
                                }
                              });

                              // Parse dates
                              final startDate =
                                  DateTime.parse(startDateController.text);
                              DateTime? completedDate;
                              if (completedDateController.text.isNotEmpty) {
                                completedDate = DateTime.parse(
                                    completedDateController.text);
                              }

                              try {
                                // Create task
                                await _teamService.createTeamTask(
                                  teamId: widget.teamId,
                                  taskName: taskNameController.text,
                                  description: taskDescriptionController.text,
                                  startDate: startDate,
                                  priority: priorityController.text,
                                  startLocation: startLocation!,
                                  endLocation: endLocation,
                                  membersAssigned: membersAssigned,
                                  expectedEndDate: completedDate,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                  _showSnackBar(
                                    localizations
                                        .translate('task_created_successfully'),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  _showErrorSnackBar(
                                    localizations
                                        .translate('error_creating_task'),
                                    e,
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
                if (_userRole == 'leader')
                  ElevatedButton(
                    onPressed: () => _showAddTaskModal(colors, localizations),
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
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskManagementScreen(
                          teamId: widget.teamId,
                          isLeader: _userRole == 'leader',
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.settings, color: colors.accent200),
                  label: Text(
                    localizations.translate('view_all'),
                    style: TextStyle(color: colors.accent200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final status = task['status'] as String? ?? 'pending';
                  final statusColor = _getTaskStatusColor(status, colors);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(
                            teamId: widget.teamId,
                            taskId: task['id'],
                            isLeader: _userRole == 'leader',
                          ),
                        ),
                      );
                    },
                    child: Container(
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
                                task['task_name'] ?? '',
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
                                    _formatTimestamp(task['start_date']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.text200,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.group_outlined,
                                      size: 16, color: colors.text200),
                                  const SizedBox(width: 4),
                                  Text(
                                    localizations.translate('number_members', {
                                      'count': (task['members_assigned']
                                              as Map<String, dynamic>)
                                          .length
                                          .toString()
                                    }),
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
    return Wrap(
      children: [
        Container(
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
        ),
      ],
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

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return timestamp.toString();
      }
    } else {
      return '';
    }

    // Format the date based on how long ago it was
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // If it's a future date
    if (difference.isNegative) {
      return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
    }

    // If it's within the last 24 hours
    if (difference.inHours < 24 && dateTime.day == now.day) {
      return 'Today at ${_formatTime(dateTime)}';
    }

    // If it's yesterday
    if (difference.inHours < 48 && dateTime.day == now.day - 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    }

    // If it's within the current year
    if (dateTime.year == now.year) {
      return '${dateTime.day} ${_getMonthName(dateTime.month)} at ${_formatTime(dateTime)}';
    }

    // If it's a different year
    return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year} at ${_formatTime(dateTime)}';
  }

  /// Helper method to get month name
  String _getMonthName(int month) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];
  }

  /// Helper method to format time
  String _formatTime(DateTime dateTime) {
    String hours = dateTime.hour.toString().padLeft(2, '0');
    String minutes = dateTime.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Returns the minimum of two integers.
  int _min(int a, int b) => a < b ? a : b;
}
