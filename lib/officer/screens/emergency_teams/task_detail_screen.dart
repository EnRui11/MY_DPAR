import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/services/emergency_team_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailScreen extends StatefulWidget {
  final String teamId;
  final String taskId;
  final bool isLeader;

  const TaskDetailScreen({
    super.key,
    required this.teamId,
    required this.taskId,
    required this.isLeader,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final EmergencyTeamService _teamService = EmergencyTeamService();
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic>? _taskData;
  bool _isVolunteerMember = false;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    _checkVolunteerStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskData() async {
    setState(() => _isLoading = true);
    try {
      final taskData =
          await _teamService.getTeamTask(widget.teamId, widget.taskId);
      if (mounted) {
        setState(() {
          _taskData = taskData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(
          AppLocalizations.of(context)!.translate('failed_to_load_task'),
          e,
        );
      }
    }
  }

  Future<void> _checkVolunteerStatus() async {
    final isVolunteer = await _teamService.isVolunteerMember(widget.teamId);
    if (mounted) {
      setState(() {
        _isVolunteerMember = isVolunteer;
      });
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).currentTheme;
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading || _taskData == null) {
      return Scaffold(
        backgroundColor: colors.bg200,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _taskData!['status'] as String? ?? 'pending';
    final priority = _taskData!['priority'] as String? ?? 'medium';
    final membersAssigned =
        _taskData!['members_assigned'] as Map<String, dynamic>? ?? {};
    final startDate = _taskData!['start_date'] as DateTime;
    final expectedEndDate = _taskData!['expected_end_date'] != null
        ? (_taskData!['expected_end_date'] is DateTime
            ? _taskData!['expected_end_date'] as DateTime
            : (_taskData!['expected_end_date'] as Timestamp).toDate())
        : null;
    final startLocation = _taskData!['start_location'] as LatLng;
    final endLocation = _taskData!['end_location'] as LatLng?;

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(colors, localizations),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Header
                    Text(
                      _taskData!['task_name'] ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(
                          _getStatusLabel(status, localizations),
                          _getStatusColor(status, colors),
                          colors,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          _getPriorityLabel(priority, localizations),
                          _getPriorityColor(priority, colors),
                          colors,
                        ),
                        if (expectedEndDate != null) ...[
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            '${localizations.translate('due')}: ${_formatDate(expectedEndDate)}',
                            colors.accent200,
                            colors,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _taskData!['description'] ?? '',
                      style: TextStyle(color: colors.text200),
                    ),
                    const SizedBox(height: 24),

                    // Assigned Members
                    Text(
                      localizations.translate('assigned_members'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _teamService.getTeamMembers(widget.teamId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final assignedMembers = snapshot.data!
                            .where((member) =>
                                membersAssigned.containsKey(member['id']))
                            .toList();

                        if (assignedMembers.isEmpty) {
                          return Center(
                            child: Text(
                              localizations.translate('no_members_assigned'),
                              style: TextStyle(
                                color: colors.text200,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: assignedMembers.map((member) {
                            final isOnDuty = member['status'] == 'active';
                            final isTaskActive =
                                membersAssigned[member['id']] == true;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.bg100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  // Update border color based on duty status
                                  color: isOnDuty ? Colors.green : Colors.grey,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color:
                                          isOnDuty ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        member['name']
                                            .substring(0,
                                                _min(2, member['name'].length))
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    member['name'],
                                    style: TextStyle(color: colors.text200),
                                  ),
                                  const SizedBox(width: 8),
                                  // Updated status icons
                                  Icon(
                                    isOnDuty
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.do_not_disturb_on_outlined,
                                    color:
                                        isOnDuty ? Colors.green : Colors.grey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Timeline
                    Text(
                      localizations.translate('timeline'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _teamService.getTaskStatusHistory(
                          widget.teamId, widget.taskId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final statusHistory = snapshot.data!.docs.map((doc) {
                          final data = doc.data();
                          return {
                            'status': data['status'],
                            'changed_at': data['changed_at'] != null
                                ? (data['changed_at'] as Timestamp).toDate()
                                : null,
                            'changed_by_name': data['changed_by_name'],
                            'feedback': data['feedback'],
                          };
                        }).toList();

                        if (statusHistory.isEmpty) {
                          return Center(
                            child: Text(
                              localizations.translate('no_status_changes'),
                              style: TextStyle(
                                color: colors.text200,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: statusHistory.length,
                          itemBuilder: (context, index) {
                            final item = statusHistory[index];
                            final isLast = index == statusHistory.length - 1;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            item['status'], colors),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (!isLast)
                                      Container(
                                        width: 2,
                                        height: 40,
                                        color: colors.bg300,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getStatusLabel(
                                            item['status'], localizations),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: colors.primary300,
                                        ),
                                      ),
                                      if (item['changed_at'] != null)
                                        Text(
                                          _formatDateTime(item['changed_at']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.text200,
                                          ),
                                        ),
                                      Text(
                                        item['changed_by_name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.text200,
                                        ),
                                      ),
                                      if (item['feedback'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item['feedback'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.text200,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Comments
                    Text(
                      localizations.translate('comments'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.primary300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _teamService.getTaskComments(
                          widget.teamId, widget.taskId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final comments = snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'id': doc.id,
                            'message': data['message'],
                            'user_id': data['user_id'],
                            'user_name': data['user_name'],
                            'created_at':
                                (data['created_at'] as Timestamp).toDate(),
                          };
                        }).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final isCurrentUser = comment['user_id'] ==
                                _teamService.currentUserId;

                            return Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? colors.accent200
                                      : colors.bg100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Column(
                                  crossAxisAlignment: isCurrentUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isCurrentUser
                                                ? colors.bg100
                                                : colors.primary200,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              isCurrentUser
                                                  ? 'ME'
                                                  : comment['user_name']
                                                      .substring(
                                                          0,
                                                          _min(
                                                              2,
                                                              comment['user_name']
                                                                  .length))
                                                      .toUpperCase(),
                                              style: TextStyle(
                                                color: isCurrentUser
                                                    ? colors.accent200
                                                    : Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isCurrentUser
                                              ? localizations.translate('me')
                                              : comment['user_name'],
                                          style: TextStyle(
                                            color: isCurrentUser
                                                ? colors.bg100
                                                : colors.text200,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDateTime(
                                              comment['created_at']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isCurrentUser
                                                ? colors.bg100.withOpacity(0.8)
                                                : colors.text200
                                                    .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      comment['message'],
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? colors.bg100
                                            : colors.text200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Comment Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bg100,
                border: Border(top: BorderSide(color: colors.bg300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: localizations.translate('add_comment'),
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
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _addComment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent200,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(localizations.translate('send')),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                localizations.translate('task_detail'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary300,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (widget.isLeader)
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.accent200),
              onPressed: () => _showTaskOptionsMenu(colors, localizations),
            )
          else if (!_isVolunteerMember)
            IconButton(
              icon: Icon(Icons.update, color: colors.accent200),
              onPressed: () => _showUpdateStatusModal(colors, localizations),
            ),
        ],
      ),
    );
  }

  void _showTaskOptionsMenu(
      AppColorTheme colors, AppLocalizations localizations) {
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
              leading: Icon(Icons.edit_outlined, color: colors.accent200),
              title: Text(localizations.translate('edit_task_details'),
                  style: TextStyle(color: colors.text200)),
              onTap: () {
                Navigator.pop(context);
                _showEditTaskModal(colors, localizations);
              },
            ),
            ListTile(
              leading: Icon(Icons.update, color: colors.accent200),
              title: Text(localizations.translate('update_status'),
                  style: TextStyle(color: colors.text200)),
              onTap: () {
                Navigator.pop(context);
                _showUpdateStatusModal(colors, localizations);
              },
            ),
            ListTile(
              leading: Icon(Icons.group, color: colors.accent200),
              title: Text(localizations.translate('assign_members'),
                  style: TextStyle(color: colors.text200)),
              onTap: () {
                Navigator.pop(context);
                _showAssignMembersModal(colors, localizations);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusModal(
      AppColorTheme colors, AppLocalizations localizations) {
    final currentStatus = _taskData!['status'] as String? ?? 'pending';
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
                            taskId: widget.taskId,
                            status: selectedStatus,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _showSuccessSnackBar(
                              localizations.translate('status_updated'),
                            );
                            _loadTaskData(); // Refresh task data
                          }
                        } catch (e) {
                          if (mounted) {
                            _showErrorSnackBar(
                              localizations.translate('error_updating_status'),
                              e,
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

  void _showAssignMembersModal(
      AppColorTheme colors, AppLocalizations localizations) {
    final Map<String, bool> selectedMembers =
        Map<String, bool>.from(_taskData!['members_assigned'] ?? {});

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
                            taskId: widget.taskId,
                            membersAssigned: selectedMembers,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            _showSuccessSnackBar(
                              localizations.translate('members_assigned'),
                            );
                            _loadTaskData(); // Refresh task data
                          }
                        } catch (e) {
                          if (mounted) {
                            _showErrorSnackBar(
                              localizations
                                  .translate('error_assigning_members'),
                              e,
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

  void _showEditTaskModal(
      AppColorTheme colors, AppLocalizations localizations) {
    final TextEditingController taskNameController =
        TextEditingController(text: _taskData!['task_name']);
    final TextEditingController taskDescriptionController =
        TextEditingController(text: _taskData!['description']);
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    final TextEditingController priorityController =
        TextEditingController(text: _taskData!['priority']);

    // Set dates from task data
    final startDate = _taskData!['start_date'] as DateTime;
    startDateController.text =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

    if (_taskData!['expected_end_date'] != null) {
      final endDate = _taskData!['expected_end_date'] as DateTime;
      endDateController.text =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
    }

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
                          hintText: localizations.translate('enter_task_name'),
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
                        '${localizations.translate('priority')}*',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.text200,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatefulBuilder(
                        builder: (context, setState) => Container(
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
                            initialDate: _taskData!['expected_end_date'] != null
                                ? _taskData!['expected_end_date'] as DateTime
                                : DateTime.now().add(const Duration(days: 1)),
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
                                    ? localizations.translate('select_end_date')
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
                              _showErrorSnackBar(
                                localizations.translate('task_name_required'),
                                '',
                              );
                              return;
                            }
                            if (taskDescriptionController.text.isEmpty) {
                              _showErrorSnackBar(
                                localizations.translate('description_required'),
                                '',
                              );
                              return;
                            }
                            if (startDateController.text.isEmpty) {
                              _showErrorSnackBar(
                                localizations.translate('start_date_required'),
                                '',
                              );
                              return;
                            }
                            if (priorityController.text.isEmpty) {
                              _showErrorSnackBar(
                                localizations.translate('priority_required'),
                                '',
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
                                taskId: widget.taskId,
                                taskName: taskNameController.text,
                                description: taskDescriptionController.text,
                                startDate: startDate,
                                priority: priorityController.text,
                                expectedEndDate: expectedEndDate,
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                _showSuccessSnackBar(
                                  localizations
                                      .translate('task_updated_successfully'),
                                );
                                _loadTaskData(); // Refresh task data
                              }
                            } catch (e) {
                              if (mounted) {
                                _showErrorSnackBar(
                                  localizations
                                      .translate('error_updating_task'),
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
  }

  Widget _buildStatusChip(String label, Color color, AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  String _getPriorityLabel(String priority, AppLocalizations localizations) =>
      switch (priority.toLowerCase()) {
        'high' => localizations.translate('high'),
        'medium' => localizations.translate('medium'),
        'low' => localizations.translate('low'),
        _ => priority.toUpperCase(),
      };

  Color _getStatusColor(String status, AppColorTheme colors) =>
      switch (status.toLowerCase()) {
        'pending' => Colors.orange,
        'in_progress' => Colors.blue,
        'completed' => Colors.green,
        'cancelled' => Colors.red,
        _ => colors.accent200,
      };

  Color _getPriorityColor(String priority, AppColorTheme colors) =>
      switch (priority.toLowerCase()) {
        'high' => Colors.red,
        'medium' => Colors.orange,
        'low' => Colors.green,
        _ => colors.accent200,
      };

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.translate('just_now');
    }
    if (difference.inHours < 1) {
      return AppLocalizations.of(context)!.translate('time_minutes_ago', {
        'count': difference.inMinutes.toString(),
      });
    }
    if (difference.inDays < 1) {
      return AppLocalizations.of(context)!.translate('time_hours_ago', {
        'count': difference.inHours.toString(),
      });
    }
    if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.translate('yesterday');
    }
    if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.translate('time_days_ago', {
        'count': difference.inDays.toString(),
      });
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDate(DateTime date) {
    final localizations = AppLocalizations.of(context)!;
    final months = [
      localizations.translate('january'),
      localizations.translate('february'),
      localizations.translate('march'),
      localizations.translate('april'),
      localizations.translate('may'),
      localizations.translate('june'),
      localizations.translate('july'),
      localizations.translate('august'),
      localizations.translate('september'),
      localizations.translate('october'),
      localizations.translate('november'),
      localizations.translate('december'),
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _min(int a, int b) => a < b ? a : b;

  Future<void> _addComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    try {
      await _teamService.addTaskComment(
        teamId: widget.teamId,
        taskId: widget.taskId,
        message: message,
      );

      if (mounted) {
        _commentController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          AppLocalizations.of(context)!.translate('failed_to_add_comment'),
          e,
        );
      }
    }
  }
}
