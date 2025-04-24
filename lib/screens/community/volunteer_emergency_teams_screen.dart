import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/officer/services/emergency_team_service.dart';
import 'package:mydpar/screens/community/team_detail_volunteer_screen.dart';

class VolunteerEmergencyTeamsScreen extends StatefulWidget {
  const VolunteerEmergencyTeamsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerEmergencyTeamsScreen> createState() =>
      _VolunteerEmergencyTeamsScreenState();
}

class _VolunteerEmergencyTeamsScreenState
    extends State<VolunteerEmergencyTeamsScreen> {
  final EmergencyTeamService _teamService = EmergencyTeamService();
  final UserInformationService _userInformationService =
      UserInformationService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bg200,
      appBar: AppBar(
        backgroundColor: colors.bg100,
        elevation: 0,
        title: Text(
          l.translate('volunteer_emergency_teams'),
          style: TextStyle(color: colors.primary300),
        ),
        iconTheme: IconThemeData(color: colors.primary300),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(colors, l),
          Expanded(
            child: _buildTeamsList(colors, l),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(AppColorTheme colors, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.bg100,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: l.translate('search_teams'),
              prefixIcon: Icon(Icons.search, color: colors.text200),
              filled: true,
              fillColor: colors.bg200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', l.translate('all_teams'), colors, l),
                const SizedBox(width: 12),
                _buildFilterChip('joined', l.translate('my_teams'), colors, l),
                const SizedBox(width: 12),
                _buildFilterChip(
                    'not_joined', l.translate('not_joined_teams'), colors, l),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String filter, String label, AppColorTheme colors, AppLocalizations l) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent200 : colors.bg100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accent200 : colors.bg300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.text200,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsList(AppColorTheme colors, AppLocalizations l) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _teamService.getAllTeams(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              l.translate(
                  'error_loading_teams', {'error': snapshot.error.toString()}),
              style: TextStyle(color: colors.warning),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTeams = snapshot.data ?? [];
        final userId = _userInformationService.userId;

        // Filter teams by type and search query
        final filteredTeams = allTeams.where((team) {
          // Only show volunteer teams
          if (team['type'] != 'volunteer') {
            return false;
          }

          if (_selectedFilter == 'joined') {
            if (userId == null) return false;
            // Check if user is a member or the team leader
            if (team['leader_id'] == userId) {
              return true;
            }
            // Check if user is a member (assume memberIds is a list of user ids)
            if (team['member_ids'] != null && team['member_ids'] is List) {
              return (team['member_ids'] as List).contains(userId);
            }
            return false;
          } else if (_selectedFilter == 'not_joined') {
            if (userId == null) return true;
            // Exclude teams where user is leader or member
            if (team['leader_id'] == userId) {
              return false;
            }
            if (team['member_ids'] != null && team['member_ids'] is List) {
              return !(team['member_ids'] as List).contains(userId);
            }
            return true;
          }

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            final name = (team['name'] ?? '').toLowerCase();
            final description = (team['description'] ?? '').toLowerCase();
            final location = (team['location_text'] ?? '').toLowerCase();
            return name.contains(_searchQuery) ||
                description.contains(_searchQuery) ||
                location.contains(_searchQuery);
          }

          return true;
        }).toList();

        if (filteredTeams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 64, color: colors.bg300),
                const SizedBox(height: 16),
                Text(
                  l.translate('no_teams_found'),
                  style: TextStyle(color: colors.text200, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTeams.length,
            itemBuilder: (context, index) {
              final team = filteredTeams[index];
              final isVolunteerTeam = team['type'] == 'volunteer';
              final teamStatus = team['status'] as String? ?? 'standby';
              final statusColor = _getStatusColor(teamStatus, colors);
              final teamId = team['id'];
              final isLeader = team['leader_id'] == userId;

              return _buildTeamCard(
                team: team,
                colors: colors,
                l: l,
                isVolunteerTeam: isVolunteerTeam,
                statusColor: statusColor,
                isLeader: isLeader,
                teamStatus: teamStatus,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTeamCard({
    required Map<String, dynamic> team,
    required AppColorTheme colors,
    required AppLocalizations l,
    required bool isVolunteerTeam,
    required Color statusColor,
    required bool isLeader,
    required String teamStatus,
  }) {
    return InkWell(
      onTap: () async {
        // First check if user is part of the team
        if (isLeader || await _checkUserMembership(team['id'])) {
          // Navigate to team detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailVolunteerScreen(
                teamId: team['id'],
                isLeader: isLeader,
              ),
            ),
          );
        } else {
          // Show join team prompt
          _showJoinTeamPrompt(team['id'], team['name'], colors, l);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colors.bg100,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Team avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isVolunteerTeam
                          ? colors.primary200
                          : colors.accent200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        team['name']
                            .substring(
                                0,
                                team['name'].length > 2
                                    ? 2
                                    : team['name'].length)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Team name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team['name'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.primary300,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildChip(
                              isVolunteerTeam
                                  ? l.translate('volunteer')
                                  : l.translate('official'),
                              isVolunteerTeam
                                  ? colors.primary200
                                  : colors.accent200,
                              colors,
                            ),
                            const SizedBox(width: 8),
                            _buildChip(
                              _getStatusTranslation(teamStatus, l),
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
              const SizedBox(height: 12),
              // Description
              Text(
                team['description'] ?? '',
                style: TextStyle(color: colors.text200),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    icon: Icons.people_outline,
                    value: '${team['member_count'] ?? 0}',
                    label: l.translate('members'),
                    colors: colors,
                  ),
                  _buildStat(
                    icon: Icons.task_outlined,
                    value: '${team['task_count'] ?? 0}',
                    label: l.translate('active_tasks'),
                    colors: colors,
                  ),
                  _buildStat(
                    icon: Icons.location_on_outlined,
                    value: team['location_text'] ?? '',
                    label: l.translate('location'),
                    colors: colors,
                    isLocation: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color chipColor, AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required AppColorTheme colors,
    bool isLocation = false,
  }) {
    return Flexible(
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.text100),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isLocation ? value : '$value $label',
              style: TextStyle(
                fontSize: 12,
                color: colors.text200,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkUserMembership(String teamId) async {
    try {
      final userInfo = await _teamService.getUserMemberInfo(teamId);
      return userInfo != null;
    } catch (e) {
      return false;
    }
  }

  void _showJoinTeamPrompt(
    String teamId,
    String teamName,
    AppColorTheme colors,
    AppLocalizations l,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          l.translate('join_team'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Text(
          l.translate('join_team_message', {'teamName': teamName}),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.translate('cancel'),
              style: TextStyle(color: colors.text200),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              Navigator.pop(context);

              try {
                await _teamService.joinTeam(teamId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.translate('successfully_joined_team')),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate to team details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamDetailVolunteerScreen(
                        teamId: teamId,
                        isLeader: false,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.translate(
                          'failed_to_join_team', {'error': e.toString()})),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent200,
              foregroundColor: Colors.white,
            ),
            child: Text(l.translate('join')),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, AppColorTheme colors) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'standby':
        return Colors.orange;
      case 'deactivated':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusTranslation(String status, AppLocalizations l) {
    switch (status) {
      case 'active':
        return l.translate('active');
      case 'standby':
        return l.translate('standby');
      case 'deactivated':
        return l.translate('deactivated');
      default:
        return status;
    }
  }
}
