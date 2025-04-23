import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/officer/services/shelter_and_resource_service.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

class HelpRequestsScreen extends StatefulWidget {
  const HelpRequestsScreen({Key? key}) : super(key: key);

  @override
  State<HelpRequestsScreen> createState() => _HelpRequestsScreenState();
}

class _HelpRequestsScreenState extends State<HelpRequestsScreen> {
  static const double _paddingValue = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  final ShelterService _shelterService = ShelterService();
  final UserInformationService _userInformationService =
      UserInformationService();

  String _searchQuery = '';
  String _selectedCategory = 'all';
  final List<String> _categories = ['all', 'food', 'water', 'medical', 'other'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final AppColorTheme colors = themeProvider.currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg200,
      appBar: AppBar(
        backgroundColor: colors.bg100,
        elevation: 0,
        title: Text(
          l.translate('help_requests'),
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
      body: Column(
        children: [
          _buildSearchAndFilter(colors, l),
          Expanded(
            child: _buildHelpRequestsList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AppColorTheme colors, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(_paddingValue),
      color: colors.bg100,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l.translate('search_help_requests_hint'),
              hintStyle: TextStyle(color: colors.text100),
              prefixIcon: Icon(Icons.search, color: colors.text200),
              filled: true,
              fillColor: colors.bg200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: TextStyle(color: colors.text100),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: _spacingMedium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: _spacingSmall),
                  child: FilterChip(
                    label: Text(l.translate('category_$category')),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: colors.bg100,
                    selectedColor: colors.accent200.withOpacity(0.2),
                    checkmarkColor: colors.accent200,
                    labelStyle: TextStyle(
                      color: isSelected ? colors.accent200 : colors.text200,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? colors.accent200 : colors.bg300,
                        width: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRequestsList(AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
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

        // Apply filters
        final filteredRequests = helpRequests.where((request) {
          // Apply category filter
          if (_selectedCategory != 'all') {
            final requestType = request['type']?.toString().toLowerCase() ?? '';
            final selectedCategory = _selectedCategory.toLowerCase();

            if (requestType != selectedCategory) {
              return false;
            }
          }

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            final title = request['type']?.toString().toLowerCase() ?? '';
            final description =
                request['description']?.toString().toLowerCase() ?? '';
            final shelterName =
                request['shelterName']?.toString().toLowerCase() ?? '';

            return title.contains(_searchQuery.toLowerCase()) ||
                description.contains(_searchQuery.toLowerCase()) ||
                shelterName.contains(_searchQuery.toLowerCase());
          }

          return true;
        }).toList();

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: colors.text200.withOpacity(0.5),
                ),
                const SizedBox(height: _spacingMedium),
                Text(
                  l.translate('no_help_requests_found'),
                  style: TextStyle(
                    color: colors.text200,
                    fontSize: 16,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedCategory != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _selectedCategory = 'all';
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
          padding: const EdgeInsets.all(_paddingValue),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index];

            // Fix for Timestamp conversion
            DateTime createdAt;
            if (request['createdAt'] != null) {
              if (request['createdAt'] is int) {
                createdAt =
                    DateTime.fromMillisecondsSinceEpoch(request['createdAt']);
              } else {
                // Handle Firestore Timestamp type
                createdAt = request['createdAt'].toDate();
              }
            } else {
              createdAt = DateTime.now();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: _spacingMedium),
              child: _buildHelpRequestCard(
                request['type'] ?? l.translate('unknown'),
                request['description'] ?? l.translate('no_description'),
                l.translate('items_needed_fulfilled', {
                  'requested': request['requestedQuantity']?.toString() ?? '0',
                  'fulfilled': request['fulfilledQuantity']?.toString() ?? '0'
                }),
                request['type'] ?? l.translate('general'),
                colors,
                request['shelterId'],
                request['id'],
                request['shelterName'] ?? l.translate('unknown_shelter'),
                createdAt,
              ),
            );
          },
        );
      },
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
    String shelterName,
    DateTime createdAt,
  ) =>
      StreamBuilder<Map<String, dynamic>>(
          stream: _shelterService.getHelpRequestStream(shelterId, requestId),
          builder: (context, snapshot) {
            final l = AppLocalizations.of(context);
            // Use the initial data passed to the card if stream hasn't loaded yet
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

            // Calculate progress
            final requestedQuantity = request['requestedQuantity'] ?? 0;
            final fulfilledQuantity = request['fulfilledQuantity'] ?? 0;
            final progress = requestedQuantity > 0
                ? (fulfilledQuantity / requestedQuantity).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              decoration: BoxDecoration(
                color: colors.bg100.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.bg100.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with shelter info
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
                        Icon(Icons.location_on,
                            size: 16, color: colors.accent200),
                        const SizedBox(width: _spacingSmall),
                        Expanded(
                          child: Text(
                            shelterName,
                            style: TextStyle(
                              color: colors.primary300,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: _spacingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _spacingSmall, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.bg200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatTimeAgo(createdAt),
                            style: TextStyle(
                              color: colors.text200,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Request details
                  Padding(
                    padding: const EdgeInsets.all(_paddingValue),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: _spacingSmall),
                                  Text(
                                    request['description'] ?? description,
                                    style: TextStyle(
                                      color: colors.text200,
                                      fontSize: 14,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: _spacingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: _spacingSmall, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.bg200,
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

                        // Progress indicator
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  liveNeeds,
                                  style: TextStyle(
                                    color: colors.text200,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  l.translate('progress_percentage', {
                                    'progress':
                                        (progress * 100).toInt().toString()
                                  }),
                                  style: TextStyle(
                                    color: colors.accent200,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: _spacingSmall),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colors.bg300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.accent200),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),

                        const SizedBox(height: _spacingMedium),

                        // Action button
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
