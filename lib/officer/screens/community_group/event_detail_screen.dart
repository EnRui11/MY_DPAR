import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/localization/app_localizations.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/officer/services/community_group_service.dart';

/// Screen for viewing and managing event details, including participants and location.
class EventDetailScreen extends StatefulWidget {
  final String groupId;
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.groupId,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  final CommunityGroupService _groupService = CommunityGroupService();
  final UserInformationService _userInformationService =
      UserInformationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _eventData;
  bool _isAdmin = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEventData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads the event data from Firestore.
  Future<void> _loadEventData() async {
    setState(() => _isLoading = true);
    try {
      // Get event data
      final eventData =
          await _groupService.getGroupEventById(widget.groupId, widget.eventId);
      if (eventData != null) {
        setState(() {
          _eventData = eventData;
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
          SnackBar(content: Text('Error loading event: $e')),
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

  /// Shows a confirmation dialog for deleting the event.
  void _showDeleteEventConfirmation(
      AppColorTheme colors, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bg100,
        title: Text(localizations.translate('confirm_delete'),
            style: TextStyle(color: colors.primary300)),
        content: Text(
          localizations.translate('delete_event_confirmation'),
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
                    widget.groupId, widget.eventId);
                _showSnackBar(
                  localizations.translate('event_deleted'),
                  backgroundColor: Colors.green,
                );
                Navigator.pop(context);
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

  /// Builds the Participants tab.
  Widget _buildParticipantsTab(
      AppColorTheme colors, AppLocalizations localizations) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('event_participants'),
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
            stream: _groupService.getEventParticipants(
                widget.groupId, widget.eventId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    localizations.translate('error_loading_participants'),
                    style: TextStyle(color: colors.warning),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final participants = snapshot.data!;
              if (participants.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: colors.bg300),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('no_participants'),
                        style: TextStyle(color: colors.text200, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  final isCurrentUser = participant['id'] == currentUserId;

                  return FutureBuilder<String>(
                    future: _getUserName(participant['id']),
                    builder: (context, snapshot) {
                      final userName = snapshot.data ?? 'Unknown User';

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
                                  color: colors.primary200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
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
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        color: colors.primary300,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _formatTimestamp(
                                              participant['joined_at']),
                                          style: TextStyle(
                                            color: colors.text100,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                participant['role'] == 'admin'
                                                    ? colors.accent200
                                                        .withOpacity(0.2)
                                                    : colors.bg300,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            participant['role'] == 'admin'
                                                ? localizations
                                                    .translate('admin')
                                                : localizations
                                                    .translate('member'),
                                            style: TextStyle(
                                              color:
                                                  participant['role'] == 'admin'
                                                      ? colors.accent200
                                                      : colors.text200,
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
      ],
    );
  }

  /// Builds the Location tab.
  Widget _buildLocationTab(
      AppColorTheme colors, AppLocalizations localizations) {
    if (_eventData == null ||
        _eventData!['latitude'] == null ||
        _eventData!['longitude'] == null) {
      return Center(
        child: Text(
          localizations.translate('no_location_available'),
          style: TextStyle(color: colors.text200),
        ),
      );
    }

    final latitude = _eventData!['latitude'] as double;
    final longitude = _eventData!['longitude'] as double;
    final locationName = _eventData!['location_name'] as String? ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.location_on, color: colors.accent200),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locationName,
                  style: TextStyle(
                    color: colors.primary300,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              center: LatLng(latitude, longitude),
              zoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mydpar.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 40,
                    height: 40,
                    builder: (context) => Icon(
                      Icons.location_on,
                      color: colors.accent200,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

  /// Formats a timestamp for display.
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

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

    if (_eventData == null) {
      return Scaffold(
        backgroundColor: colors.bg200,
        body: Center(
          child: Text(
            localizations.translate('event_not_found'),
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
          _eventData!['title'] ?? '',
          style: TextStyle(color: colors.primary300),
        ),
        actions: [
          if (_isAdmin)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colors.accent200),
              onSelected: (value) async {
                if (value == 'edit') {
                  // Implement edit event functionality
                  await _groupService.updateGroupEvent(
                    groupId: widget.groupId,
                    eventId: widget.eventId,
                    title: _eventData!['title'],
                    description: _eventData!['description'],
                    eventTime:
                        (_eventData!['event_time'] as Timestamp).toDate(),
                    latitude: _eventData!['latitude'],
                    longitude: _eventData!['longitude'],
                    locationName: _eventData!['location_name'],
                  );
                  _showSnackBar(localizations.translate('event_edited'),
                      backgroundColor: Colors.green);
                } else if (value == 'share') {
                  // Copy event ID to clipboard
                  Clipboard.setData(ClipboardData(text: widget.eventId));
                  _showSnackBar(localizations.translate('event_id_copied'),
                      backgroundColor: Colors.green);
                } else if (value == 'delete') {
                  _showDeleteEventConfirmation(colors, localizations);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: colors.accent200),
                    title: Text(localizations.translate('edit_event')),
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share, color: colors.accent200),
                    title: Text(localizations.translate('share_event')),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: colors.warning),
                    title: Text(localizations.translate('delete_event')),
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
                  _eventData!['description'] ?? '',
                  style: TextStyle(color: colors.text200),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: colors.text200),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(_eventData!['event_time']),
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
                icon: Icon(Icons.people_outline),
                text: localizations.translate('participants'),
              ),
              Tab(
                icon: Icon(Icons.location_on_outlined),
                text: localizations.translate('location'),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParticipantsTab(colors, localizations),
                _buildLocationTab(colors, localizations),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
