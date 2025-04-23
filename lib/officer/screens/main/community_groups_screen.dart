import 'package:flutter/material.dart';
import 'package:mydpar/officer/screens/community_group/group_detail_admin_screen.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/services/community_group_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:flutter/services.dart';

/// Screen for managing community groups, including listing, filtering, and status updates.
class CommunityGroupsScreen extends StatefulWidget {
  const CommunityGroupsScreen({super.key});

  @override
  State<CommunityGroupsScreen> createState() => _CommunityGroupsScreenState();
}

class _CommunityGroupsScreenState extends State<CommunityGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _joinGroupController = TextEditingController();
  final CommunityGroupService _groupService = CommunityGroupService();
  final UserInformationService _userInformationService =
      UserInformationService();
  bool _isAddMenuOpen = false;
  String _selectedFilter = 'all'; // 'all', 'joined', 'not_joined'

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
    _joinGroupController.dispose();
    super.dispose();
  }

  /// Filters groups based on search text and selected filter.
  List<Map<String, dynamic>> _filterGroups(List<Map<String, dynamic>> groups) {
    final searchText = _searchController.text.toLowerCase();
    return groups.where((group) {
      // First apply text search filter
      if (searchText.isNotEmpty) {
        final name = (group['name'] ?? '').toLowerCase();
        final description = (group['description'] ?? '').toLowerCase();
        final communityName = (group['community_name'] ?? '').toLowerCase();
        if (!name.contains(searchText) &&
            !description.contains(searchText) &&
            !communityName.contains(searchText)) {
          return false;
        }
      }

      // Then apply membership filter
      switch (_selectedFilter) {
        case 'joined':
          return group['is_member'] == true;
        case 'not_joined':
          return group['is_member'] != true;
        default:
          return true;
      }
    }).toList();
  }

  /// Shows a bottom sheet with group options (view, edit, delete).
  void _showGroupOptionsMenu(
      BuildContext context, Map<String, dynamic> group, AppColorTheme colors) {
    final localizations = AppLocalizations.of(context)!;
    final isAdmin = group['is_admin'] ?? false;
    final isMember = group['is_member'] ?? false;

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
            if (isMember) ...[
              ListTile(
                leading: Icon(Icons.info_outline, color: colors.accent200),
                title: Text(localizations.translate('view_details'),
                    style: TextStyle(color: colors.text200)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GroupDetailScreen(groupId: group['id']),
                    ),
                  );
                },
              ),
              if (isAdmin) ...[
                ListTile(
                  leading: Icon(Icons.share, color: colors.accent200),
                  title: Text(localizations.translate('share_group'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _shareGroupId(group['id'], colors, localizations);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: colors.accent200),
                  title: Text(localizations.translate('edit_group'),
                      style: TextStyle(color: colors.text200)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditGroupDialog(group, colors, localizations);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colors.warning),
                  title: Text(localizations.translate('delete_group'),
                      style: TextStyle(color: colors.warning)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(group, colors, localizations);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: colors.warning),
                  title: Text(localizations.translate('leave_group'),
                      style: TextStyle(color: colors.warning)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _leaveGroup(group['id'], colors, localizations);
                  },
                ),
              ],
            ] else ...[
              ListTile(
                leading: Icon(Icons.group_add, color: colors.accent200),
                title: Text(localizations.translate('join_group'),
                    style: TextStyle(color: colors.text200)),
                onTap: () async {
                  Navigator.pop(context);
                  await _joinGroup(group['id'], colors, localizations);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Leaves a group.
  Future<void> _leaveGroup(String groupId, AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      await _groupService.removeGroupMember(
          groupId, _userInformationService.userId!);
      _showSnackBar(
        localizations.translate('successfully_left_group'),
        backgroundColor: Colors.green,
      );
      setState(() {});
    } catch (e) {
      _showErrorSnackBar(
        localizations.translate('failed_to_leave_group'),
        e,
      );
    }
  }

  /// Copies the group ID to the clipboard and shows a snackbar.
  void _shareGroupId(
      String groupId, AppColorTheme colors, AppLocalizations localizations) {
    Clipboard.setData(ClipboardData(text: groupId));
    _showSnackBar(
      localizations.translate('group_id_copied'),
      backgroundColor: Colors.green,
    );
  }

  /// Shows a dialog for joining a group by ID.
  void _showJoinGroupDialog(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('join_group'),
          style: TextStyle(color: colors.primary300),
        ),
        content: TextField(
          controller: _joinGroupController,
          decoration: InputDecoration(
            hintText: localizations.translate('enter_group_id'),
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
              _joinGroupController.clear();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text(
              localizations.translate('join'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () {
              final groupId = _joinGroupController.text.trim();
              if (groupId.isNotEmpty) {
                Navigator.pop(context);
                _joinGroup(groupId, colors, localizations);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Attempts to join a group with the given ID.
  Future<void> _joinGroup(String groupId, AppColorTheme colors,
      AppLocalizations localizations) async {
    try {
      _showSnackBar(
        localizations.translate('joining_group'),
        backgroundColor: Colors.blue,
      );

      await _groupService.addGroupMember(
        groupId: groupId,
        userId: _userInformationService.userId!,
      );

      _showSnackBar(
        localizations.translate('successfully_joined_group'),
        backgroundColor: Colors.green,
      );
      setState(() {});
    } catch (e) {
      _showErrorSnackBar(
        localizations.translate('failed_to_join_group'),
        e,
      );
    }
  }

  /// Shows a confirmation dialog for deleting a group.
  void _showDeleteConfirmation(Map<String, dynamic> group, AppColorTheme colors,
      AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(localizations.translate('confirm_delete'),
            style: TextStyle(color: colors.primary300)),
        content: Text(
          localizations.translate(
              'delete_group_confirmation', {'groupName': group['name']}),
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _groupService.deleteCommunityGroup(group['id']);
                _showSnackBar(
                  localizations.translate('group_deleted'),
                  backgroundColor: Colors.green,
                );
                setState(() {});
              } catch (e) {
                _showErrorSnackBar(
                  localizations.translate('failed_to_delete_group'),
                  e,
                );
              }
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
                      _buildGroupStatistics(colors, localizations),
                      const SizedBox(height: 24),
                      _buildGroupsList(colors, localizations),
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
              label: localizations.translate('join_group'),
              onPressed: () {
                setState(() => _isAddMenuOpen = false);
                _showJoinGroupDialog(colors, localizations);
              },
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildFloatingActionButton(
              icon: Icons.add_circle,
              label: localizations.translate('create_group'),
              onPressed: () {
                setState(() => _isAddMenuOpen = false);
                _showCreateGroupModal(colors, localizations);
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
              hintText: localizations.translate('search_groups'),
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
                    localizations.translate('all_groups'), 'all', colors),
                _buildFilterChip(
                    localizations.translate('my_groups'), 'joined', colors),
                _buildFilterChip(localizations.translate('not_joined'),
                    'not_joined', colors),
              ],
            ),
          ),
        ],
      );

  /// Builds a filter chip for group filtering.
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

  /// Builds the statistics section showing total groups and my groups count.
  Widget _buildGroupStatistics(
      AppColorTheme colors, AppLocalizations localizations) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _groupService.getCommunityGroups(),
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
        final groups = snapshot.data!;
        final filteredGroups = _filterGroups(groups);

        final totalGroups = groups.length;
        final myGroups =
            groups.where((group) => group['is_member'] == true).length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                localizations.translate('total_groups'),
                totalGroups.toString(),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                localizations.translate('my_groups'),
                myGroups.toString(),
                colors,
              ),
            ),
          ],
        );
      },
    );
  }

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

  /// Builds the list of filtered groups.
  Widget _buildGroupsList(
          AppColorTheme colors, AppLocalizations localizations) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _groupService.getCommunityGroups(),
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
          final groups = snapshot.data!;
          final filteredGroups = _filterGroups(groups);
          if (filteredGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: colors.bg300),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_groups_found'),
                    style: TextStyle(color: colors.text200, fontSize: 16),
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _searchController.clear();
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
            itemCount: filteredGroups.length,
            itemBuilder: (_, index) =>
                _buildGroupCard(filteredGroups[index], colors, localizations),
          );
        },
      );

  /// Shows a dialog prompting the user to join the group
  Future<void> _showJoinGroupPrompt(String groupId, String groupName,
      AppColorTheme colors, AppLocalizations localizations) async {
    final shouldJoin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('join_group_prompt'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Text(
          localizations
              .translate('join_group_message', {'groupName': groupName}),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: colors.text200),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(
              localizations.translate('join'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldJoin == true) {
      await _joinGroup(groupId, colors, localizations);
    }
  }

  /// Builds a card for a single group.
  Widget _buildGroupCard(Map<String, dynamic> group, AppColorTheme colors,
      AppLocalizations localizations) {
    final isAdmin = group['is_admin'] ?? false;
    final isMember = group['is_member'] ?? false;
    final roleColor = isAdmin ? colors.accent200 : colors.primary200;

    return InkWell(
      onTap: () async {
        if (isMember) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(groupId: group['id']),
            ),
          );
        } else {
          await _showJoinGroupPrompt(
              group['id'], group['name'], colors, localizations);
        }
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
                        BoxDecoration(color: roleColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        group['name']
                            .substring(0, _min(2, group['name'].length))
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
                          group['name'],
                          style: TextStyle(
                              color: colors.primary300,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (isMember)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.accent200.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAdmin
                                  ? localizations.translate('admin')
                                  : localizations.translate('member'),
                              style: TextStyle(
                                color: colors.accent200,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () =>
                        _showGroupOptionsMenu(context, group, colors),
                  ),
                ],
              ),
              if (group['description'] != null && group['description'] != '')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    group['description'],
                    style: TextStyle(color: colors.text200, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildGroupInfo(
                      Icons.people,
                      localizations.translate('number_members',
                          {'count': group['member_count'] ?? 0}),
                      colors),
                  const SizedBox(width: 16),
                  _buildGroupInfo(
                      Icons.location_on,
                      group['community_name'] ??
                          localizations.translate('community_not_set'),
                      colors),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  /// Builds a group information row with an icon and text.
  Widget _buildGroupInfo(IconData icon, String text, AppColorTheme colors) =>
      Row(
        children: [
          Icon(icon, size: 16, color: colors.text200),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: colors.text200, fontSize: 14)),
        ],
      );

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

  void _showCreateGroupModal(
      AppColorTheme colors, AppLocalizations localizations) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final communityNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('create_group'),
          style: TextStyle(color: colors.primary300),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('group_name'),
                  hintText: localizations.translate('enter_group_name'),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('description'),
                  hintText: localizations.translate('enter_description'),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: communityNameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('community_name'),
                  hintText: localizations.translate('enter_community_name'),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
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
              localizations.translate('create'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  communityNameController.text.isEmpty) {
                _showSnackBar(
                  localizations.translate('fill_required_fields'),
                  backgroundColor: Colors.red,
                );
                return;
              }

              try {
                await _groupService.createCommunityGroup(
                  name: nameController.text,
                  description: descriptionController.text,
                  communityName: communityNameController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar(
                    localizations.translate('group_created'),
                    backgroundColor: Colors.green,
                  );
                  setState(() {});
                }
              } catch (e) {
                _showErrorSnackBar(
                  localizations.translate('failed_to_create_group'),
                  e,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Returns the minimum of two integers.
  int _min(int a, int b) => a < b ? a : b;

  void _showEditGroupDialog(Map<String, dynamic> group, AppColorTheme colors,
      AppLocalizations localizations) {
    final nameController = TextEditingController(text: group['name']);
    final descriptionController =
        TextEditingController(text: group['description']);
    final communityNameController =
        TextEditingController(text: group['community_name']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('edit_group_details'),
          style: TextStyle(color: colors.primary300),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('group_name'),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.translate('description'),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: communityNameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('community_name'),
                  filled: true,
                  fillColor: colors.bg200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
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
              localizations.translate('save'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () async {
              try {
                await _groupService.updateCommunityGroup(
                  id: group['id'],
                  name: nameController.text,
                  description: descriptionController.text,
                  communityName: communityNameController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar(
                    localizations.translate('group_updated'),
                    backgroundColor: Colors.green,
                  );
                  setState(() {});
                }
              } catch (e) {
                _showErrorSnackBar(
                  localizations.translate('failed_to_update_group'),
                  e,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
