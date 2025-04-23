import 'package:flutter/material.dart';
import 'package:mydpar/screens/community/help_requests_screen.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/widgets/bottom_nav_bar.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/main/map_screen.dart';
import 'package:mydpar/screens/main/profile_screen.dart';
import 'package:mydpar/officer/services/shelter_and_resource_service.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/screens/community/community_groups_member_screen.dart';
import 'package:mydpar/localization/app_localizations.dart';

// Model for feature items
class FeatureItem {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  const FeatureItem({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}

// Model for help requests, Firebase-ready
class HelpRequest {
  final String title;
  final String description;
  final String needs;
  final String category;

  const HelpRequest({
    required this.title,
    required this.description,
    required this.needs,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'needs': needs,
        'category': category,
      };
}

// Model for available resources, Firebase-ready
class Resource {
  final String title;
  final String description;
  final String location;
  final bool isAvailable;

  const Resource({
    required this.title,
    required this.description,
    required this.location,
    required this.isAvailable,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        'isAvailable': isAvailable,
      };
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  final ShelterService _shelterService = ShelterService();
  final UserInformationService _userInformationService =
      UserInformationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationService>(context, listen: false).changeIndex(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;
    final navigationService = Provider.of<NavigationService>(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildContent(context, colors),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        onTap: (index) {
          if (index != 2) {
            // Only navigate if not already on community screen
            navigationService.changeIndex(index);
            _navigateToScreen(index);
          }
        },
      ),
    );
  }

  void _navigateToScreen(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const MapScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildContent(BuildContext context, AppColorTheme colors) => Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_paddingValue),
          child: Column(
            children: [
              _buildFeatureGrid(context, colors),
              const SizedBox(height: _spacingLarge),
              _buildActiveHelpRequests(context, colors),
            ],
          ),
        ),
      );

  Widget _buildFeatureGrid(BuildContext context, AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    const List<FeatureItem> features = [
      FeatureItem(
        icon: Icons.group_outlined,
        titleKey: 'volunteer',
        descriptionKey: 'join_volunteer_network',
      ),
      FeatureItem(
        icon: Icons.inventory_2_outlined,
        titleKey: 'resources',
        descriptionKey: 'respond_to_resources',
      ),
      FeatureItem(
        icon: Icons.people_outline,
        titleKey: 'groups',
        descriptionKey: 'join_community_groups',
      ),
      FeatureItem(
        icon: Icons.help_outline,
        titleKey: 'help_and_support',
        descriptionKey: 'request_assistance',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: _spacingLarge,
      crossAxisSpacing: _spacingLarge,
      children: features
          .map((feature) => _buildFeatureCard(feature, colors))
          .toList(),
    );
  }

  Widget _buildFeatureCard(FeatureItem feature, AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        if (l.translate(feature.titleKey) == l.translate('resources')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HelpRequestsScreen(),
            ),
          );
        } else if (l.translate(feature.titleKey) == l.translate('groups')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommunityGroupsScreen(),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg100.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.bg100.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(_paddingValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(feature.icon, size: 32, color: colors.accent200),
            const SizedBox(height: _spacingSmall),
            Text(
              l.translate(feature.titleKey),
              style: TextStyle(
                color: colors.primary300,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.translate(feature.descriptionKey),
              style: TextStyle(
                color: colors.text200,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveHelpRequests(BuildContext context, AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.translate('active_help_requests'),
              style: TextStyle(
                color: colors.primary300,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpRequestsScreen(),
                  ),
                );
              },
              child: Text(
                l.translate('view_all'),
                style: TextStyle(
                  color: colors.accent200,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _spacingLarge),
        SizedBox(
          height: 300,
          child: Scrollbar(
            thickness: 6,
            radius: const Radius.circular(8),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _shelterService.getAllActiveHelpRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l.translate('error_loading_help_requests',
                          {'error': snapshot.error.toString()}),
                      style: TextStyle(color: colors.warning),
                    ),
                  );
                }

                final helpRequests = snapshot.data ?? [];

                if (helpRequests.isEmpty) {
                  return Center(
                    child: Text(
                      l.translate('no_active_help_requests'),
                      style: TextStyle(color: colors.text200),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: helpRequests.length > 3 ? 3 : helpRequests.length,
                  itemBuilder: (context, index) {
                    final request = helpRequests[index];

                    // Extract createdAt from the request
                    DateTime createdAt;
                    if (request.containsKey('createdAt')) {
                      if (request['createdAt'] is DateTime) {
                        createdAt = request['createdAt'];
                      } else {
                        createdAt = request['createdAt'].toDate();
                      }
                    } else {
                      createdAt = DateTime.now();
                    }

                    // Get the correct shelter name
                    final shelterName = request['shelterName'] ??
                        l.translate('unknown_shelter');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: _spacingMedium),
                      child: _buildHelpRequestCard(
                        request['type'] ?? l.translate('unknown'),
                        request['description'] ?? l.translate('no_description'),
                        l.translate('items_needed_fulfilled', {
                          'requested':
                              request['requestedQuantity']?.toString() ?? '0',
                          'fulfilled':
                              request['fulfilledQuantity']?.toString() ?? '0'
                        }),
                        request['type'] ?? l.translate('general'),
                        colors,
                        request['shelterId'],
                        request['id'],
                        shelterName, // Pass the correct shelter name
                        createdAt,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpRequestCard(
    String title,
    String description,
    String needs,
    String category,
    AppColorTheme colors,
    String shelterId,
    String requestId,
    String name,
    DateTime createdAt,
  ) =>
      StreamBuilder<Map<String, dynamic>>(
          stream: _shelterService.getHelpRequestStream(shelterId, requestId),
          builder: (context, snapshot) {
            final l = AppLocalizations.of(context);
            // Safely parse requested and fulfilled quantities from needs string
            int parsedRequestedQuantity = 0;
            int parsedFulfilledQuantity = 0;

            try {
              final parts = needs.split(' ');
              if (parts.isNotEmpty) {
                parsedRequestedQuantity = int.tryParse(parts[0]) ?? 0;
              }

              if (needs.contains('(')) {
                final fulfilledPart = needs.split('(')[1];
                final fulfilledParts = fulfilledPart.split(' ');
                if (fulfilledParts.isNotEmpty) {
                  parsedFulfilledQuantity =
                      int.tryParse(fulfilledParts[0]) ?? 0;
                }
              }
            } catch (e) {
              // If any parsing error occurs, default to 0
              parsedRequestedQuantity = 0;
              parsedFulfilledQuantity = 0;
            }

            // Use the initial data passed to the card if stream hasn't loaded yet
            final request = snapshot.data ??
                {
                  'type': title,
                  'description': description,
                  'requestedQuantity': parsedRequestedQuantity,
                  'fulfilledQuantity': parsedFulfilledQuantity,
                  'status': 'in_progress',
                };

            // Update the needs text with live data if available
            final liveNeeds = snapshot.hasData
                ? l.translate('items_needed_fulfilled', {
                    'requested': (request['requestedQuantity'] ?? 0).toString(),
                    'fulfilled': (request['fulfilledQuantity'] ?? 0).toString(),
                  })
                : needs;

            return Container(
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.bg100.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(_paddingValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.translate(
                                  'help_request_type_${(request['type'] ?? title).toLowerCase()}'),
                              style: TextStyle(
                                color: colors.primary300,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request['description'] ?? description,
                              style: TextStyle(
                                color: colors.text200,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.translate('from_shelter', {'name': name}),
                              style: TextStyle(
                                color: colors.text200,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: _spacingSmall, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.bg100.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.translate(
                              'category_${(request['type'] ?? category).toLowerCase()}'),
                          style: TextStyle(
                            color: colors.accent200,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _spacingMedium),
                  Text(
                    liveNeeds,
                    style: TextStyle(
                      color: colors.text200,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: _spacingSmall),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showRespondDialog(context, colors, shelterId,
                            requestId, request['type'] ?? title);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent200,
                        foregroundColor: colors.bg100,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(l.translate('respond_to_request')),
                    ),
                  ),
                ],
              ),
            );
          });

  void _showRespondDialog(
    BuildContext context,
    AppColorTheme colors,
    String shelterId,
    String requestId,
    String requestTitle,
  ) {
    final l = AppLocalizations.of(context);
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.translate('respond_to_help_request')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.translate('request_title', {'title': requestTitle}),
              style: TextStyle(color: colors.primary300),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: l.translate('amount_to_contribute'),
                hintText: l.translate('enter_amount_hint'),
                labelStyle: TextStyle(color: colors.text100),
                hintStyle: TextStyle(color: colors.text100),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.translate('please_enter_amount')),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.translate('please_enter_valid_amount')),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final userId = _userInformationService.userId;
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.translate('must_be_logged_in')),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
                return;
              }

              try {
                await _shelterService.respondToHelpRequest(
                  shelterId: shelterId,
                  requestId: requestId,
                  responderId: userId,
                  amount: amount,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.translate('thank_you_for_contribution')),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        l.translate('error_occurred', {'error': e.toString()})),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(l.translate('submit')),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return l.translate('date_format', {
        'day': dateTime.day.toString(),
        'month': dateTime.month.toString(),
        'year': dateTime.year.toString()
      });
    } else if (difference.inDays > 0) {
      return l.translate('days_ago', {'days': difference.inDays.toString()});
    } else if (difference.inHours > 0) {
      return l.translate('hours_ago', {'hours': difference.inHours.toString()});
    } else if (difference.inMinutes > 0) {
      return l.translate(
          'minutes_ago', {'minutes': difference.inMinutes.toString()});
    } else {
      return l.translate('just_now');
    }
  }
}
