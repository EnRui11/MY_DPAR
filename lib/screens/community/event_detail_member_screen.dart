import 'package:flutter/material.dart';
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

/// Screen for viewing event details as a member, including participants and location.
class EventDetailMemberScreen extends StatefulWidget {
  final String groupId;
  final String eventId;

  const EventDetailMemberScreen({
    super.key,
    required this.groupId,
    required this.eventId,
  });

  @override
  State<EventDetailMemberScreen> createState() =>
      _EventDetailMemberScreenState();
}

class _EventDetailMemberScreenState extends State<EventDetailMemberScreen>
    with SingleTickerProviderStateMixin {
  final CommunityGroupService _groupService = CommunityGroupService();
  final UserInformationService _userInformationService =
      UserInformationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _eventData;
  bool _isAttending = false;
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
        final List<dynamic> participants = eventData['participants'] ?? [];
        setState(() {
          _eventData = eventData;
          _isAttending = participants.contains(currentUserId);
        });
      }

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

  /// Join or leave the event
  Future<void> _toggleAttendance() async {
    if (_eventData == null) return;

    setState(() => _isLoading = true);
    try {
      // Get current participants list
      List<dynamic> participants =
          List<dynamic>.from(_eventData!['participants'] ?? []);

      if (_isAttending) {
        // Remove user from participants
        participants.remove(currentUserId);
      } else {
        // Add user to participants
        if (!participants.contains(currentUserId)) {
          participants.add(currentUserId);
        }
      }

      // Update the event
      await _firestore
          .collection('community_groups')
          .doc(widget.groupId)
          .collection('group_events')
          .doc(widget.eventId)
          .update({'participants': participants});

      setState(() {
        _isAttending = !_isAttending;
        _eventData!['participants'] = participants;
      });

      final message = _isAttending
          ? AppLocalizations.of(context)!.translate('joined_event')
          : AppLocalizations.of(context)!.translate('left_event');

      _showSnackBar(message, backgroundColor: Colors.green);
    } catch (e) {
      _showErrorSnackBar(
          AppLocalizations.of(context)!
              .translate('failed_to_update_attendance'),
          e);
    } finally {
      setState(() => _isLoading = false);
    }
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
              // Join/Leave button - only show for non-officers
              if (_userInformationService.role != 'officer')
                ElevatedButton.icon(
                  onPressed: _toggleAttendance,
                  icon: Icon(
                    _isAttending ? Icons.check_circle : Icons.add_circle,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isAttending
                        ? localizations.translate('leave_event')
                        : localizations.translate('join_event'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isAttending ? colors.primary200 : colors.accent200,
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
                      const SizedBox(height: 24),
                      if (!_isAttending)
                        ElevatedButton.icon(
                          onPressed: _toggleAttendance,
                          icon: Icon(Icons.add_circle, color: Colors.white),
                          label: Text(
                            localizations.translate('be_first_to_join'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
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
                  final fullName =
                      '${participant['firstName']} ${participant['lastName']}'
                          .trim();
                  final isAdmin = participant['role'] == 'admin';

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
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? colors.accent200.withOpacity(0.2)
                                            : colors.bg300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isAdmin
                                            ? localizations.translate('admin')
                                            : localizations.translate('member'),
                                        style: TextStyle(
                                          color: isAdmin
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

    // Check if event is in the past
    final eventTime = (_eventData!['event_time'] as Timestamp).toDate();
    final isPastEvent = eventTime.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: colors.bg200,
      appBar: AppBar(
        backgroundColor: colors.bg100,
        elevation: 0,
        title: Text(
          _eventData!['title'] ?? '',
          style: TextStyle(color: colors.primary300),
        ),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: colors.text200),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(_eventData!['event_time']),
                      style: TextStyle(color: colors.text200),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPastEvent
                            ? colors.bg300.withOpacity(0.5)
                            : colors.accent200.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPastEvent
                            ? localizations.translate('past')
                            : localizations.translate('upcoming'),
                        style: TextStyle(
                          color:
                              isPastEvent ? colors.text100 : colors.accent200,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_isAttending) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary100.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          localizations.translate('attending'),
                          style: TextStyle(
                            color: colors.primary300,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
