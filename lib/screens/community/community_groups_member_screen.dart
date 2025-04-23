import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/services/community_group_service.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/screens/community/group_detail_member_screen.dart';
import 'package:mydpar/screens/community/event_detail_member_screen.dart';

class CommunityGroupsScreen extends StatefulWidget {
  const CommunityGroupsScreen({Key? key}) : super(key: key);

  @override
  State<CommunityGroupsScreen> createState() => _CommunityGroupsScreenState();
}

class _CommunityGroupsScreenState extends State<CommunityGroupsScreen> {
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  final CommunityGroupService _groupService = CommunityGroupService();
  final UserInformationService _userInformationService =
      UserInformationService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _joinGroupController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isAddMenuOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _joinGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: colors.bg200,
      appBar: AppBar(
        backgroundColor: colors.bg100,
        elevation: 0,
        title: Text(
          l.translate('community_groups'),
          style: TextStyle(
            color: colors.primary300,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary300),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(_paddingValue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchAndFilter(colors),
                      const SizedBox(height: _spacingLarge),
                      _buildGroupStatistics(colors),
                      const SizedBox(height: _spacingLarge),
                      _buildGroupsList(colors),
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
        children: [
          if (_isAddMenuOpen) ...[
            _buildFloatingActionButton(
              icon: Icons.group_add,
              label: 'join_group',
              onPressed: () {
                setState(() => _isAddMenuOpen = false);
                _showJoinGroupDialog(colors);
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
    final l = AppLocalizations.of(context);
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          l.translate(label),
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.bg100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.bg300.withOpacity(0.5)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(color: colors.text200),
            decoration: InputDecoration(
              hintText: l.translate('search_groups_hint'),
              hintStyle: TextStyle(color: colors.text200.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: colors.text200),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupStatistics(AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _groupService.getAllCommunityGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: colors.accent200));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              l.translate(
                  'error_loading_groups', {'error': snapshot.error.toString()}),
              style: TextStyle(color: colors.warning),
            ),
          );
        }

        final allGroups = snapshot.data ?? [];
        final joinedGroups = allGroups.where((group) {
          final members = group['members'] as List?;
          return members != null &&
              members.contains(_groupService.currentUserId);
        }).toList();
        final notJoinedGroups = allGroups.where((group) {
          final members = group['members'] as List?;
          return members == null ||
              !members.contains(_groupService.currentUserId);
        }).toList();

        return Container(
          padding: const EdgeInsets.all(_paddingValue),
          decoration: BoxDecoration(
            color: colors.bg100.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.bg100.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _buildStatisticItem(
                  l.translate('all_groups'), allGroups.length, colors),
              Container(width: 1, height: 40, color: colors.bg300),
              _buildStatisticItem(
                  l.translate('joined_groups'), joinedGroups.length, colors),
              Container(width: 1, height: 40, color: colors.bg300),
              _buildStatisticItem(l.translate('not_joined_groups'),
                  notJoinedGroups.length, colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticItem(String label, int count, AppColorTheme colors) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.text200,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              color: colors.primary300,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.translate('groups_list'),
          style: TextStyle(
            color: colors.primary300,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: _spacingMedium),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _selectedFilter == l.translate('joined')
              ? _groupService.getUserGroups()
              : _groupService.getAllCommunityGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: colors.accent200),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  l.translate('error_loading_groups',
                      {'error': snapshot.error.toString()}),
                  style: TextStyle(color: colors.warning),
                ),
              );
            }

            final groups = snapshot.data ?? [];

            final filteredGroups = groups.where((group) {
              if (_searchQuery.isNotEmpty) {
                final name = group['name']?.toString().toLowerCase() ?? '';
                final description =
                    group['description']?.toString().toLowerCase() ?? '';
                final communityName =
                    group['community_name']?.toString().toLowerCase() ?? '';

                return name.contains(_searchQuery.toLowerCase()) ||
                    description.contains(_searchQuery.toLowerCase()) ||
                    communityName.contains(_searchQuery.toLowerCase());
              }

              // 应用类型过滤
              if (_selectedFilter == '可加入') {
                // Fix: Check if members is null before using contains
                final members = group['members'] as List?;
                return members == null ||
                    !members.contains(_groupService.currentUserId);
              }

              return true;
            }).toList();

            if (filteredGroups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_off,
                      size: 64,
                      color: colors.text200.withOpacity(0.5),
                    ),
                    const SizedBox(height: _spacingMedium),
                    Text(
                      l.translate('no_groups_found'),
                      style: TextStyle(
                        color: colors.text200,
                        fontSize: 16,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            _selectedFilter = 'All';
                          });
                        },
                        child: Text(
                          l.translate('clear_filters'),
                          style: TextStyle(
                            color: colors.accent200,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                final group = filteredGroups[index];
                return _buildGroupCard(group, colors);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    final bool isUserMember =
        (group['members'] as List?)?.contains(_groupService.currentUserId) ??
            false;
    final memberCount = (group['members'] as List?)?.length ?? 0;

    return InkWell(
      onTap: () async {
        if (isUserMember) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GroupDetailMemberScreen(groupId: group['id']),
            ),
          );
        } else {
          try {
            await _groupService.joinCommunityGroup(group['id']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GroupDetailMemberScreen(groupId: group['id']),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.translate('error_joining_group')),
                  backgroundColor: colors.warning,
                ),
              );
            }
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: _spacingMedium),
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // 群组头部
            Container(
              padding: const EdgeInsets.all(_paddingValue),
              decoration: BoxDecoration(
                color: colors.bg100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        group['name']?.substring(0, 1).toUpperCase() ?? 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: _spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'] ?? l.translate('unnamed_group'),
                          style: TextStyle(
                            color: colors.primary300,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          group['community_name'] ?? l.translate('community'),
                          style: TextStyle(
                            color: colors.text200,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUserMember ? colors.accent200 : colors.bg200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUserMember
                          ? l.translate('joined')
                          : l.translate('can_join'),
                      style: TextStyle(
                        color: isUserMember ? Colors.white : colors.text200,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 群组内容
            Padding(
              padding: const EdgeInsets.all(_paddingValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group['description'] ?? l.translate('no_description'),
                    style: TextStyle(
                      color: colors.text200,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: _spacingMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: colors.text200,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount ${l.translate('members')}',
                            style: TextStyle(
                              color: colors.text200,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.event_note_outlined,
                            size: 16,
                            color: colors.text200,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.translate('activities'),
                            style: TextStyle(
                              color: colors.text200,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (isUserMember) {
                            // Navigate to group detail page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupDetailMemberScreen(
                                    groupId: group['id']),
                              ),
                            );
                          } else {
                            // Show join group confirmation dialog
                            _showJoinGroupPrompt(
                                group['id'], group['name'], colors);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUserMember
                              ? colors.primary100
                              : colors.accent200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          isUserMember
                              ? l.translate('view_details')
                              : l.translate('join_group'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showJoinGroupPrompt(
      String groupId, String groupName, AppColorTheme colors) async {
    final l = AppLocalizations.of(context);
    final shouldJoin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          l.translate('join_group'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Text(
          l.translate('confirm_join_group', {'group_name': groupName}),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(l.translate('cancel'),
                style: TextStyle(color: colors.text200)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(l.translate('join'),
                style: TextStyle(color: colors.accent200)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldJoin == true) {
      try {
        await _groupService.joinCommunityGroup(groupId);
        _showSnackBar(l.translate('join_group_success'), colors);
      } catch (e) {
        _showSnackBar(
            l.translate('join_group_error', {'error': e.toString()}), colors,
            isError: true);
      }
    }
  }

  void _showJoinGroupDialog(AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          l.translate('join_group_by_id'),
          style: TextStyle(color: colors.primary300),
        ),
        content: TextField(
          controller: _joinGroupController,
          decoration: InputDecoration(
            hintText: l.translate('enter_group_id'),
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
            child: Text(l.translate('cancel'),
                style: TextStyle(color: colors.text200)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(l.translate('join'),
                style: TextStyle(color: colors.accent200)),
            onPressed: () async {
              final groupId = _joinGroupController.text.trim();
              if (groupId.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _groupService.joinCommunityGroup(groupId);
                  _showSnackBar(l.translate('join_group_success'), colors);
                } catch (e) {
                  _showSnackBar(
                      l.translate('join_group_error', {'error': e.toString()}),
                      colors,
                      isError: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, AppColorTheme colors,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.warning : colors.accent200,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}
