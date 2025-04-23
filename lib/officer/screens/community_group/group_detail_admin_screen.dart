import 'package:flutter/material.dart';
import 'package:mydpar/officer/screens/community_group/event_detail_admin_screen.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/services/community_group_service.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydpar/officer/screens/community_group/select_event_location_screen.dart';

/// Screen for displaying detailed information about a community group.
class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final CommunityGroupService _groupService = CommunityGroupService();
  final UserInformationService _userInformationService =
      UserInformationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _groupData;
  bool _isAdmin = false;
  TextEditingController _messageController = TextEditingController();
  TextEditingController _eventTitleController = TextEditingController();
  TextEditingController _eventDescriptionController = TextEditingController();
  DateTime _selectedEventDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  /// Loads the group data from Firestore.
  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    try {
      // Get group data
      final groupData =
          await _groupService.getCommunityGroupById(widget.groupId);
      if (groupData != null) {
        setState(() {
          _groupData = groupData;
        });
      }

      // Check if user is admin
      final isAdmin = await _groupService.isUserAdmin(widget.groupId);
      setState(() {
        _isAdmin = isAdmin;
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading group: $e')),
        );
      }
    }
  }

  /// Shows a snackbar with a message.
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

  /// Sends a message to the group.
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('Message cannot be empty', backgroundColor: Colors.red);
      return;
    }

    try {
      await _groupService.sendGroupMessage(
        groupId: widget.groupId,
        content: _messageController.text.trim(),
        messageType: 'text',
      );

      _messageController.clear();
      // No need to show success snackbar as the message will appear in the list
    } catch (e) {
      _showErrorSnackBar('Failed to send message', e);
    }
  }

  /// Shows a dialog to create a new event.
  Future<void> _showCreateEventDialog(
      AppColorTheme colors, AppLocalizations localizations) async {
    _eventTitleController.clear();
    _eventDescriptionController.clear();
    _selectedEventDate = DateTime.now();
    Map<String, dynamic>? selectedLocation;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.bg100,
          title: Text(
            localizations.translate('create_event'),
            style: TextStyle(color: colors.primary300),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                Text(
                  '${localizations.translate('event_title')}*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _eventTitleController,
                  decoration: InputDecoration(
                    hintText: localizations.translate('enter_event_title'),
                    filled: true,
                    fillColor: colors.bg200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                Text(
                  localizations.translate('event_description'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _eventDescriptionController,
                  decoration: InputDecoration(
                    hintText:
                        localizations.translate('enter_event_description'),
                    filled: true,
                    fillColor: colors.bg200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Date and Time Field
                Text(
                  '${localizations.translate('event_date')}*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedEventDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_selectedEventDate),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedEventDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.bg200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: colors.accent200),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_selectedEventDate.day}/${_selectedEventDate.month}/${_selectedEventDate.year} ${_selectedEventDate.hour}:${_selectedEventDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: colors.text200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Field
                Text(
                  '${localizations.translate('event_location')}*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SelectEventLocationScreen(
                          initialLocation: selectedLocation != null
                              ? LatLng(
                                  selectedLocation!['latitude'] as double,
                                  selectedLocation!['longitude'] as double,
                                )
                              : null,
                          initialLocationName:
                              selectedLocation?['locationName'] as String?,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() => selectedLocation = result);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.bg200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: colors.accent200),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedLocation != null
                                ? selectedLocation!['locationName'] as String
                                : localizations.translate('select_location'),
                            style: TextStyle(color: colors.text200),
                          ),
                        ),
                      ],
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
                if (_eventTitleController.text.isEmpty) {
                  _showSnackBar(
                    localizations.translate('event_title_required'),
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                if (selectedLocation == null) {
                  _showSnackBar(
                    localizations.translate('event_location_required'),
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                try {
                  await _groupService.createGroupEvent(
                    groupId: widget.groupId,
                    title: _eventTitleController.text,
                    description: _eventDescriptionController.text,
                    eventTime: _selectedEventDate,
                    latitude: selectedLocation!['latitude'] as double,
                    longitude: selectedLocation!['longitude'] as double,
                    locationName: selectedLocation!['locationName'] as String,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    _showSnackBar(
                      localizations.translate('event_created'),
                      backgroundColor: Colors.green,
                    );
                  }
                } catch (e) {
                  _showErrorSnackBar(
                    localizations.translate('failed_to_create_event'),
                    e,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog to edit an event.
  void _showEditEventDialog(Map<String, dynamic> event, AppColorTheme colors,
      AppLocalizations localizations) {
    _eventTitleController.text = event['title'] ?? '';
    _eventDescriptionController.text = event['description'] ?? '';
    _selectedEventDate = (event['event_time'] as Timestamp).toDate();

    // Safely handle location data
    Map<String, dynamic>? selectedLocation;
    if (event['latitude'] != null &&
        event['longitude'] != null &&
        event['location_name'] != null) {
      selectedLocation = {
        'latitude': event['latitude'] as double,
        'longitude': event['longitude'] as double,
        'locationName': event['location_name'] as String,
      };
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.bg100,
          title: Text(
            localizations.translate('edit_event'),
            style: TextStyle(color: colors.primary300),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                Text(
                  '${localizations.translate('event_title')}*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _eventTitleController,
                  decoration: InputDecoration(
                    hintText: localizations.translate('enter_event_title'),
                    filled: true,
                    fillColor: colors.bg200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                Text(
                  localizations.translate('event_description'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _eventDescriptionController,
                  decoration: InputDecoration(
                    hintText:
                        localizations.translate('enter_event_description'),
                    filled: true,
                    fillColor: colors.bg200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Date and Time Field
                Text(
                  '${localizations.translate('event_date')}*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedEventDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_selectedEventDate),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedEventDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.bg200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: colors.accent200),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_selectedEventDate.day}/${_selectedEventDate.month}/${_selectedEventDate.year} ${_selectedEventDate.hour}:${_selectedEventDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: colors.text200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Field
                Text(
                  '${localizations.translate('event_location')}*',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary300,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SelectEventLocationScreen(
                          initialLocation: selectedLocation != null
                              ? LatLng(
                                  selectedLocation!['latitude'] as double,
                                  selectedLocation!['longitude'] as double,
                                )
                              : null,
                          initialLocationName:
                              selectedLocation?['locationName'] as String?,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() => selectedLocation = result);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.bg200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: colors.accent200),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedLocation != null
                                ? selectedLocation!['locationName'] as String
                                : localizations.translate('select_location'),
                            style: TextStyle(color: colors.text200),
                          ),
                        ),
                      ],
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
                if (_eventTitleController.text.isEmpty) {
                  _showSnackBar(
                    localizations.translate('event_title_required'),
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                if (selectedLocation == null) {
                  _showSnackBar(
                    localizations.translate('event_location_required'),
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                try {
                  await _groupService.updateGroupEvent(
                    groupId: widget.groupId,
                    eventId: event['id'],
                    title: _eventTitleController.text,
                    description: _eventDescriptionController.text,
                    eventTime: _selectedEventDate,
                    latitude: selectedLocation!['latitude'] as double,
                    longitude: selectedLocation!['longitude'] as double,
                    locationName: selectedLocation!['locationName'] as String,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    _showSnackBar(
                      localizations.translate('event_updated'),
                      backgroundColor: Colors.green,
                    );
                  }
                } catch (e) {
                  _showErrorSnackBar(
                    localizations.translate('failed_to_update_event'),
                    e,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog for deleting an event.
  void _showDeleteEventConfirmation(Map<String, dynamic> event,
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(localizations.translate('confirm_delete'),
            style: TextStyle(color: colors.primary300)),
        content: Text(
          localizations.translate(
              'delete_event_confirmation', {'eventTitle': event['title']}),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(localizations.translate('cancel'),
                style: TextStyle(color: colors.accent200)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              localizations.translate('delete'),
              style: TextStyle(color: colors.warning),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _groupService.deleteGroupEvent(
                    widget.groupId, event['id']);
                _showSnackBar(
                  localizations.translate('event_deleted'),
                  backgroundColor: Colors.green,
                );
              } catch (e) {
                _showErrorSnackBar(
                  localizations.translate('failed_to_delete_event'),
                  e,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog for removing a member.
  void _showRemoveMemberConfirmation(Map<String, dynamic> member,
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(localizations.translate('confirm_remove'),
            style: TextStyle(color: colors.primary300)),
        content: Text(
          localizations.translate('remove_member_confirmation'),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(localizations.translate('cancel'),
                style: TextStyle(color: colors.accent200)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              localizations.translate('remove'),
              style: TextStyle(color: colors.warning),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _groupService.removeGroupMember(
                    widget.groupId, member['id']);
                _showSnackBar(
                  localizations.translate('member_removed'),
                  backgroundColor: Colors.green,
                );
              } catch (e) {
                _showErrorSnackBar(
                  localizations.translate('failed_to_remove_member'),
                  e,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to update a member's role.
  void _showUpdateRoleDialog(Map<String, dynamic> member, AppColorTheme colors,
      AppLocalizations localizations) {
    String selectedRole = member['role'] ?? 'member';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(
          localizations.translate('update_role'),
          style: TextStyle(color: colors.primary300),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(
                labelText: localizations.translate('role'),
                filled: true,
                fillColor: colors.bg200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'admin',
                  child: Text(localizations.translate('admin')),
                ),
                DropdownMenuItem(
                  value: 'member',
                  child: Text(localizations.translate('member')),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedRole = value;
                }
              },
            ),
          ],
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
              localizations.translate('update'),
              style: TextStyle(color: colors.accent200),
            ),
            onPressed: () async {
              try {
                await _groupService.updateGroupMember(
                  groupId: widget.groupId,
                  memberId: member['id'],
                  role: selectedRole,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar(
                    localizations.translate('role_updated'),
                    backgroundColor: Colors.green,
                  );
                }
              } catch (e) {
                _showErrorSnackBar(
                  localizations.translate('failed_to_update_role'),
                  e,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog for deleting the group.
  void _showDeleteGroupConfirmation(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(localizations.translate('confirm_delete_group'),
            style: TextStyle(color: colors.primary300)),
        content: Text(
          localizations.translate('delete_group_confirmation'),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(localizations.translate('cancel'),
                style: TextStyle(color: colors.accent200)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              localizations.translate('delete'),
              style: TextStyle(color: colors.warning),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _groupService.deleteCommunityGroup(widget.groupId);
                _showSnackBar(
                  localizations.translate('group_deleted'),
                  backgroundColor: Colors.green,
                );
                Navigator.pop(context);
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

  /// Shows a confirmation dialog for leaving the group.
  void _showLeaveGroupConfirmation(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(localizations.translate('confirm_leave_group'),
            style: TextStyle(color: colors.primary300)),
        content: Text(
          localizations.translate('leave_group_confirmation'),
          style: TextStyle(color: colors.text200),
        ),
        actions: [
          TextButton(
            child: Text(localizations.translate('cancel'),
                style: TextStyle(color: colors.accent200)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              localizations.translate('leave'),
              style: TextStyle(color: colors.warning),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _groupService.removeGroupMember(
                    widget.groupId, currentUserId);
                _showSnackBar(
                  localizations.translate('group_left'),
                  backgroundColor: Colors.green,
                );
                Navigator.pop(context);
              } catch (e) {
                _showErrorSnackBar(
                  localizations.translate('failed_to_leave_group'),
                  e,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Builds the Messages tab.
  Widget _buildMessagesTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _groupService.getGroupMessages(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    localizations.translate('error_loading_messages'),
                    style: TextStyle(color: colors.warning),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: colors.bg300),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('no_messages'),
                        style: TextStyle(color: colors.text200, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message['user_id'] == currentUserId;
                  final isAnnouncement =
                      message['message_type'] == 'announcement';

                  return FutureBuilder<String>(
                    future: _getUserName(message['user_id']),
                    builder: (context, snapshot) {
                      final userName = snapshot.data ?? 'Unknown User';

                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCurrentUser ? colors.accent200 : colors.bg100,
                            borderRadius: BorderRadius.circular(12),
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
                                            : userName
                                                .substring(
                                                  0,
                                                  _min(2, userName.length),
                                                )
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
                                        : userName,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? colors.bg100
                                          : colors.text200,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    message['created_at'] != null
                                        ? _formatDateTime(
                                            message['created_at'].toDate())
                                        : localizations.translate('unknown'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCurrentUser
                                          ? colors.bg100.withOpacity(0.8)
                                          : colors.text200.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message['content'] ?? '',
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
              );
            },
          ),
        ),
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
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: localizations.translate('type_message'),
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
                onPressed: _sendMessage,
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
    );
  }

  /// Builds the Events tab.
  Widget _buildEventsTab(AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('upcoming_events'),
                style: TextStyle(
                  color: colors.primary300,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isAdmin)
                ElevatedButton.icon(
                  onPressed: () =>
                      _showCreateEventDialog(colors, localizations),
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    localizations.translate('create_event'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _groupService.getGroupEvents(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    localizations.translate('error_loading_events'),
                    style: TextStyle(color: colors.warning),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data!;
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_outlined, size: 64, color: colors.bg300),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('no_events'),
                        style: TextStyle(color: colors.text200, fontSize: 16),
                      ),
                      if (_isAdmin) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showCreateEventDialog(colors, localizations),
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text(
                            localizations.translate('create_event'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final eventTime = (event['event_time'] as Timestamp).toDate();
                  final isPast = eventTime.isBefore(DateTime.now());

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(
                            groupId: widget.groupId,
                            eventId: event['id'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event['title'] ?? '',
                                    style: TextStyle(
                                      color: colors.primary300,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_isAdmin)
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert,
                                        color: colors.text200),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditEventDialog(
                                            event, colors, localizations);
                                      } else if (value == 'delete') {
                                        _showDeleteEventConfirmation(
                                            event, colors, localizations);
                                      } else if (value == 'view') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EventDetailScreen(
                                              groupId: widget.groupId,
                                              eventId: event['id'],
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Text(localizations
                                            .translate('view_details')),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                            localizations.translate('edit')),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                            localizations.translate('delete')),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['description'] ?? '',
                              style: TextStyle(color: colors.text200),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: colors.text200),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(eventTime),
                                  style: TextStyle(color: colors.text200),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? colors.bg300.withOpacity(0.5)
                                        : colors.accent200.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isPast
                                        ? localizations.translate('past')
                                        : localizations.translate('upcoming'),
                                    style: TextStyle(
                                      color: isPast
                                          ? colors.text100
                                          : colors.accent200,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the Members tab.
  Widget _buildMembersTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('group_members'),
                style: TextStyle(
                  color: colors.primary300,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _groupService.getGroupMembers(widget.groupId),
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
                );
              }

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isAdmin = member['role'] == 'admin';
                  final isCurrentUser = member['user_id'] == currentUserId;
                  final fullName =
                      '${member['firstName']} ${member['lastName']}'.trim();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? colors.accent200
                                  : colors.primary200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
                                Row(
                                  children: [
                                    Text(
                                      isCurrentUser
                                          ? localizations.translate('me')
                                          : fullName,
                                      style: TextStyle(
                                        color: colors.primary300,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              colors.accent200.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          localizations.translate('admin'),
                                          style: TextStyle(
                                            color: colors.accent200,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(member['joined_at']),
                                  style: TextStyle(
                                    color: colors.text100,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isAdmin && !isCurrentUser)
                            PopupMenuButton<String>(
                              icon:
                                  Icon(Icons.more_vert, color: colors.text200),
                              onSelected: (value) {
                                if (value == 'role') {
                                  _showUpdateRoleDialog(
                                      member, colors, localizations);
                                } else if (value == 'remove') {
                                  _showRemoveMemberConfirmation(
                                      member, colors, localizations);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'role',
                                  child: Text(
                                      localizations.translate('change_role')),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                      localizations.translate('remove_member')),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Formats a timestamp for display.
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  /// Formats a DateTime for display.
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.translate('just_now');
    }
    if (difference.inHours < 1) {
      return AppLocalizations.of(context)!.translate('minutes_ago', {
        'count': difference.inMinutes.toString(),
      });
    }
    if (difference.inDays < 1) {
      return AppLocalizations.of(context)!.translate('hours_ago', {
        'count': difference.inHours.toString(),
      });
    }
    if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.translate('yesterday');
    }
    if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.translate('days_ago', {
        'count': difference.inDays.toString(),
      });
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Returns the minimum of two integers.
  int _min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    final colors =
        Provider.of<ThemeProvider>(context, listen: true).currentTheme;
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bg200,
        body: Center(child: CircularProgressIndicator(color: colors.accent200)),
      );
    }

    if (_groupData == null) {
      return Scaffold(
        backgroundColor: colors.bg200,
        body: Center(
          child: Text(
            localizations.translate('group_not_found'),
            style: TextStyle(color: colors.warning),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bg200,
      appBar: AppBar(
        backgroundColor: colors.bg100,
        elevation: 0,
        title: Text(
          _groupData!['name'] ?? '',
          style: TextStyle(color: colors.primary300),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colors.accent200),
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await _showEditGroupDialog(colors, localizations);
                  break;
                case 'share':
                  Clipboard.setData(ClipboardData(text: widget.groupId));
                  _showSnackBar(
                    localizations.translate('group_id_copied'),
                    backgroundColor: Colors.green,
                  );
                  break;
                case 'delete':
                  _showDeleteGroupConfirmation(colors, localizations);
                  break;
                case 'leave':
                  _showLeaveGroupConfirmation(colors, localizations);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (_isAdmin)
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: colors.text200),
                    title: Text(localizations.translate('edit_group_details')),
                  ),
                ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share, color: colors.text200),
                  title: Text(localizations.translate('share_group')),
                ),
              ),
              if (_isAdmin)
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: colors.warning),
                    title: Text(localizations.translate('delete_group')),
                  ),
                ),
              if (!_isAdmin)
                PopupMenuItem(
                  value: 'leave',
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app, color: colors.warning),
                    title: Text(localizations.translate('leave_group')),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.bg100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _groupData!['description'] ?? '',
                  style: TextStyle(color: colors.text200),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colors.text200),
                    const SizedBox(width: 4),
                    Text(
                      _groupData!['community_name'] ?? '',
                      style: TextStyle(color: colors.text200),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: colors.accent200,
            unselectedLabelColor: colors.text100,
            indicatorColor: colors.accent200,
            tabs: [
              Tab(
                icon: Icon(Icons.chat_bubble_outline),
                text: localizations.translate('messages'),
              ),
              Tab(
                icon: Icon(Icons.event_outlined),
                text: localizations.translate('events'),
              ),
              Tab(
                icon: Icon(Icons.people_outline),
                text: localizations.translate('members'),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesTab(colors, localizations),
                _buildEventsTab(colors, localizations),
                _buildMembersTab(colors, localizations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditGroupDialog(
      AppColorTheme colors, AppLocalizations localizations) async {
    final nameController = TextEditingController(text: _groupData!['name']);
    final descriptionController =
        TextEditingController(text: _groupData!['description']);
    final communityNameController =
        TextEditingController(text: _groupData!['community_name']);

    await showDialog(
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
                  id: widget.groupId,
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
                  await _loadGroupData();
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

  /// Gets the user's name from the user information.
  Future<String> _getUserName(String userId) async {
    try {
      await _userInformationService.refreshUserData();
      final firstName = _userInformationService.firstName ?? '';
      final lastName = _userInformationService.lastName ?? '';
      return '$firstName $lastName'.trim();
    } catch (e) {
      debugPrint('Error getting user name: $e');
    }
    return 'Unknown User';
  }

  Future<String> _getUserFullName(String userId) async {
    try {
      final userData = await _userInformationService.getUserFullName(userId);
      return '${userData['firstName']} ${userData['lastName']}'.trim();
    } catch (e) {
      debugPrint('Error fetching user full name: $e');
      return 'Unknown User';
    }
  }
}
