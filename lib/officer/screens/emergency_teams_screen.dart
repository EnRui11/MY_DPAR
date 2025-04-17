import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/service/emergency_team_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/officer/screens/emergency_teams/create_emergency_team_screen.dart';
import 'package:mydpar/officer/screens/emergency_teams/team_detail_screen.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:flutter/services.dart';

/// Screen for managing emergency teams, including listing, filtering, and status updates.
class EmergencyTeamsScreen extends StatefulWidget {
  const EmergencyTeamsScreen({super.key});

  @override
  State<EmergencyTeamsScreen> createState() => _EmergencyTeamsScreenState();
}

class _EmergencyTeamsScreenState extends State<EmergencyTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _joinTeamController = TextEditingController();
  String _selectedFilter = 'all';
  final EmergencyTeamService _teamService = EmergencyTeamService();
  final UserInformationService _userInformationService =
      UserInformationService();
  bool _isAddMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  /// Updates the UI when the search text changes.
  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _searchController.dispose();
    _joinTeamController.dispose();
    super.dispose();
  }

  /// Filters teams based on search text and selected filter.
  List<Map<String, dynamic>> _filterTeams(List<Map<String, dynamic>> teams) {
    final searchText = _searchController.text.toLowerCase();
    return teams.where((team) {
      // Apply filter by type or status
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'official' && team['type'] != 'official')
          return false;
        if (_selectedFilter == 'volunteer' && team['type'] != 'volunteer')
          return false;
        if (_selectedFilter != 'official' &&
            _selectedFilter != 'volunteer' &&
            team['status'] != _selectedFilter) return false;
      }
      // Apply search text filter
      if (searchText.isEmpty) return true;
      final name = (team['name'] ?? '').toLowerCase();
      final id = (team['id'] ?? '').toLowerCase();
      final location = (team['location_text'] ?? '').toLowerCase();
      final specialization = (team['specialization'] ?? '').toLowerCase();
      return name.contains(searchText) ||
          id.contains(searchText) ||
          location.contains(searchText) ||
          specialization.contains(searchText);
    }).toList();
  }

  /// Updates the status of a team.
  Future<void> _changeTeamStatus(String teamId, String newStatus) async {
    try {
      await _teamService.updateTeam(teamId: teamId, status: newStatus);
      if (mounted) {
        _showSnackBar(
            AppLocalizations.of(context)!.translate('team_status_updated'),
            backgroundColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!
                .translate('failed_to_update_team_status'),
            e);
      }
    }
  }

  /// Deletes a team.
  Future<void> _deleteTeam(String teamId) async {
    try {
      await _teamService.deleteTeam(teamId);
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.translate('team_deleted'),
            backgroundColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!.translate('failed_to_delete_team'),
            e);
      }
    }
  }

  /// Shows a bottom sheet with team options (view, activate, standby, deactivate, delete).
  void _showTeamOptionsMenu(
      BuildContext context, Map<String, dynamic> team, AppColorTheme colors) {
    final localizations = AppLocalizations.of(context)!;
    final currentUserId = _userInformationService.userId;
    final isTeamLeader = currentUserId == team['leader_id'];
    final teamStatus = team['status'];

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
              leading: Icon(Icons.info_outline, color: colors.accent200),
              title: Text(localizations.translate('view_details'),
                  style: TextStyle(color: colors.text200)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamDetailScreen(teamId: team['id']),
                  ),
                );
              },
            ),
            if (isTeamLeader) ...[
              ListTile(
                leading: Icon(Icons.share, color: colors.accent200),
                title: Text(localizations.translate('share_team'),
                    style: TextStyle(color: colors.text200)),
                onTap: () {
                  Navigator.pop(context);
                  _shareTeamId(team['id'], colors, localizations);
                },
              ),
              if (teamStatus != 'active')
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.green),
                  title: Text(localizations.translate('activate_team'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _changeTeamStatus(team['id'], 'active');
                  },
                ),
              if (teamStatus != 'standby')
                ListTile(
                  leading: const Icon(Icons.pause, color: Colors.orange),
                  title: Text(localizations.translate('set_to_standby'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _changeTeamStatus(team['id'], 'standby');
                  },
                ),
              if (teamStatus != 'deactivated')
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.grey),
                  title: Text(localizations.translate('deactivate_team'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _changeTeamStatus(team['id'], 'deactivated');
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.warning),
                title: Text(localizations.translate('delete_team'),
                    style: TextStyle(color: colors.warning)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(team, colors, localizations);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.share, color: colors.accent200),
                title: Text(localizations.translate('share_team'),
                    style: TextStyle(color: colors.text200)),
                onTap: () {
                  Navigator.pop(context);
                  _shareTeamId(team['id'], colors, localizations);
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: colors.warning),
                title: Text(localizations.translate('quit_team'),
                    style: TextStyle(color: colors.warning)),
                onTap: () async {
                  Navigator.pop(context);
                  await _quitTeam(team['id'], colors, localizations);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _quitTeam(String teamId, AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      final userId = _userInformationService.userId!;
      final userRole = _userInformationService.role!;
      
      await _teamService.quitTeam(teamId, userId, userRole);
      
      _showSnackBar(
        localizations.translate('successfully_quit_team'),
        backgroundColor: Colors.green,
      );

      // Refresh the team list
      setState(() {});
    } catch (e) {
      _showErrorSnackBar(
        localizations.translate('failed_to_quit_team'),
        e,
      );
    }
  }

  /// Copies the team ID to the clipboard and shows a snackbar.
  void _shareTeamId(
      String teamId, AppColorTheme colors, AppLocalizations localizations) {
    Clipboard.setData(ClipboardData(text: teamId));
    _showSnackBar(
      localizations.translate('team_id_copied'),
      backgroundColor: Colors.green,
    );
  }

  /// Shows a dialog for joining a team by ID.
  void _showJoinTeamDialog(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('join_team'),
          style: TextStyle(color: colors.primary300),
        ),
        content: TextField(
          controller: _joinTeamController,
          decoration: InputDecoration(
            hintText: localizations.translate('enter_team_id'),
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
              _joinTeamController.clear();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(
              localizations.translate('join'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () {
              final teamId = _joinTeamController.text.trim();
              if (teamId.isNotEmpty) {
                Navigator.pop(context);
                _joinTeam(teamId, colors, localizations);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Attempts to join a team with the given ID.
  Future<void> _joinTeam(String teamId, AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      // Show snackbar indicating the joining process has started
      _showSnackBar(
        localizations.translate('joining_team'),
        backgroundColor: Colors.blue,
      );

      await _teamService.joinTeam(teamId);

      // Show snackbar for successful join
      _showSnackBar(
        localizations.translate('successfully_joined_team'),
        backgroundColor: Colors.green,
      );
    } catch (e) {
      // Show snackbar for failed join
      _showErrorSnackBar(
        localizations.translate('failed_to_join_team'),
        e,
      );
    }
  }

  /// Shows a confirmation dialog for deleting a team.
  void _showDeleteConfirmation(Map<String, dynamic> team, AppColorTheme colors,
      AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(localizations.translate('confirm_delete'),
            style: TextStyle(color: colors.primary300)),
        content: Text(
          localizations.translate(
              'delete_team_confirmation', {'teamName': team['name']}),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(localizations.translate('cancel'),
                style: TextStyle(color: colors.accent200)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(localizations.translate('delete'),
                style: TextStyle(color: colors.warning)),
            onPressed: () {
              Navigator.pop(context);
              _deleteTeam(team['id']);
            },
          ),
        ],
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchAndFilter(colors, localizations),
                      const SizedBox(height: 24),
                      _buildTeamStatistics(colors, localizations),
                      const SizedBox(height: 24),
                      _buildTeamsList(colors, localizations),
                    ],
                  ),
                ),
              ),
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
              icon: Icons.group_add,
              label: localizations.translate('join_team'),
              onPressed: () {
                setState(() => _isAddMenuOpen = false);
                _showJoinTeamDialog(colors, localizations);
              },
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildFloatingActionButton(
              icon: Icons.add_circle,
              label: localizations.translate('create_team'),
              onPressed: () {
                setState(() => _isAddMenuOpen = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateEmergencyTeamScreen()),
                );
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

  /// Builds a floating action button with an icon and label.
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

  /// Builds the search bar and filter chips.
  Widget _buildSearchAndFilter(
          AppColorTheme colors, AppLocalizations localizations) =>
      Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: localizations.translate('search_teams'),
              hintStyle: TextStyle(color: colors.text100),
              prefixIcon: Icon(Icons.search, color: colors.text100),
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
                    localizations.translate('all_teams'), 'all', colors),
                _buildFilterChip(
                    localizations.translate('official'), 'official', colors),
                _buildFilterChip(
                    localizations.translate('volunteer'), 'volunteer', colors),
                _buildFilterChip(
                    localizations.translate('active'), 'active', colors),
                _buildFilterChip(
                    localizations.translate('on_standby'), 'standby', colors),
                _buildFilterChip(localizations.translate('deactivated'),
                    'deactivated', colors),
              ],
            ),
          ),
        ],
      );

  /// Builds a filter chip for team filtering.
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

  /// Builds the statistics section showing active teams and total members.
  Widget _buildTeamStatistics(
      AppColorTheme colors, AppLocalizations localizations) =>
    StreamBuilder<List<Map<String, dynamic>>>(
      stream: _teamService.getUserTeams(),
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final teams = snapshot.data!;
        
        // Filter teams based on the selected filter
        final filteredTeams = _filterTeams(teams);
        
        // Calculate the number of teams and total members based on the filtered teams
        final teamCount = filteredTeams.length;
        final totalMembers = filteredTeams.fold<int>(
            0, (sum, team) => sum + ((team['member_count'] as int?) ?? 0));
        
        // Determine the label for the statistics card based on the selected filter
        String teamLabel;
        switch (_selectedFilter) {
          case 'official':
            teamLabel = localizations.translate('official_teams');
            break;
          case 'volunteer':
            teamLabel = localizations.translate('volunteer_teams');
            break;
          case 'active':
            teamLabel = localizations.translate('active_teams');
            break;
          case 'standby':
            teamLabel = localizations.translate('standby_teams');
            break;
          case 'deactivated':
            teamLabel = localizations.translate('deactivated_teams');
            break;
          default:
            teamLabel = localizations.translate('all_teams');
        }
  
        return Row(
          children: [
            Expanded(
                child: _buildStatCard(teamLabel, teamCount.toString(), colors)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard(
                    localizations.translate('total_members'),
                    totalMembers.toString(),
                    colors)),
          ],
        );
      },
    );

  /// Builds a statistics card with a label and value.
  Widget _buildStatCard(String label, String value, AppColorTheme colors) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.bg300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colors.text200, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  color: colors.accent200,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  /// Builds the list of filtered teams.
  Widget _buildTeamsList(
          AppColorTheme colors, AppLocalizations localizations) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _teamService.getUserTeams(),
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final teams = snapshot.data!;
          final filteredTeams = _filterTeams(teams);
          if (filteredTeams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: colors.bg300),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_teams_found'),
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
                      child: Text(localizations.translate('clear_filters'),
                          style: TextStyle(color: colors.accent200)),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTeams.length,
            itemBuilder: (_, index) =>
                _buildTeamCard(filteredTeams[index], colors, localizations),
          );
        },
      );

  /// Builds a card for a single team.
  Widget _buildTeamCard(Map<String, dynamic> team, AppColorTheme colors,
      AppLocalizations localizations) {
    final isOfficial = team['type'] == 'official';
    final status = team['status'] as String;
    final statusColor = _getStatusColor(status, colors);
    final typeColor = isOfficial ? colors.accent200 : colors.primary200;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDetailScreen(teamId: team['id']),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(color: typeColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        team['name']
                            .substring(0, _min(2, team['name'].length))
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team['name'],
                          style: TextStyle(
                              color: colors.primary300,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
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
                                colors),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () =>
                        _showTeamOptionsMenu(context, team, colors),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTeamInfo(
                      Icons.people,
                      localizations.translate(
                          'members', {'count': team['member_count'] ?? 0}),
                      colors),
                  const SizedBox(width: 16),
                  _buildTeamInfo(
                      Icons.location_on,
                      team['location_text'] ??
                          localizations.translate('location_not_set'),
                      colors),
                  const SizedBox(width: 16),
                  _buildTeamInfo(
                      Icons.assignment,
                      localizations.translate(
                          'tasks', {'count': team['task_count'] ?? 0}),
                      colors),
                ],
              ),
              if (team['specialization'] != null &&
                  team['specialization'] != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildTeamInfo(
                      Icons.security,
                      _getSpecializationLabel(
                          team['specialization'], localizations),
                      colors),
                ),
              const SizedBox(height: 8),
              if (team['current_task'] != null &&
                  team['current_task'] != '') ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(localizations.translate('current_task'),
                        style: TextStyle(color: colors.text200, fontSize: 14)),
                    Text(
                      team['current_task'] ??
                          localizations.translate('no_active_task'),
                      style: TextStyle(
                          color: colors.accent200,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
        _ => status.toUpperCase(),
      };

  /// Returns the localized label for team specialization.
  String _getSpecializationLabel(
          String specialization, AppLocalizations localizations) =>
      switch (specialization) {
        'rescue' => localizations.translate('search_and_rescue'),
        'medical' => localizations.translate('medical'),
        'fire' => localizations.translate('fire_response'),
        'logistics' => localizations.translate('logistics_and_supply'),
        'evacuation' => localizations.translate('evacuation'),
        'general' => localizations.translate('general_response'),
        _ => specialization,
      };

  /// Builds a status chip with a label and color.
  Widget _buildStatusChip(String label, Color color, AppColorTheme colors) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );

  /// Builds a team information row with an icon and text.
  Widget _buildTeamInfo(IconData icon, String text, AppColorTheme colors) =>
      Row(
        children: [
          Icon(icon, size: 16, color: colors.text200),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: colors.text200, fontSize: 14)),
        ],
      );

  /// Returns the color for a team status.
  Color _getStatusColor(String status, AppColorTheme colors) =>
      switch (status.toLowerCase()) {
        'active' => Colors.green,
        'standby' => Colors.orange,
        'deactivated' => Colors.grey,
        _ => colors.accent200,
      };

  /// Returns the minimum of two integers.
  int _min(int a, int b) => a < b ? a : b;

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
}
