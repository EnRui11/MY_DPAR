import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:mydpar/services/feedback_service.dart';
import 'package:mydpar/services/user_information_service.dart';
import 'package:mydpar/localization/app_localizations.dart';

class FAQFeedbackScreen extends StatefulWidget {
  const FAQFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FAQFeedbackScreen> createState() => _FAQFeedbackScreenState();
}

class _FAQFeedbackScreenState extends State<FAQFeedbackScreen>
    with SingleTickerProviderStateMixin {
  static const double _padding = 16.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 12.0;
  static const double _spacingLarge = 24.0;

  late TabController _tabController;
  final FeedbackService _feedbackService = FeedbackService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  int _rating = 0;

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'faq_question_1', // What is MY_DPAR and what does it do?
      'answer': 'faq_answer_1',
    },
    {
      'question': 'faq_question_2', // How do I join a volunteer team?
      'answer': 'faq_answer_2',
    },
    {
      'question': 'faq_question_3', // How can I report a disaster?
      'answer': 'faq_answer_3',
    },
    {
      'question':
          'faq_question_4', // How does the SOS Emergency feature work and what is its purpose?
      'answer': 'faq_answer_4',
    },
    {
      'question':
          'faq_question_5', // How are reported disasters verified as happening or false alerts?
      'answer': 'faq_answer_5',
    },
    {
      'question':
          'faq_question_6', // How can I contribute resources to shelters or community groups?
      'answer': 'faq_answer_6',
    },
    {
      'question':
          'faq_question_7', // How do I add or manage my emergency contacts?
      'answer': 'faq_answer_7',
    },
    {
      'question': 'faq_question_8', // How do I change the app language?
      'answer': 'faq_answer_8',
    },
    {
      'question':
          'faq_question_9', // How do I update my profile information or photo?
      'answer': 'faq_answer_9',
    },
    {
      'question':
          'faq_question_10', // How do I view or join upcoming community events?
      'answer': 'faq_answer_10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('help_and_support')),
        backgroundColor: colors.bg100,
        foregroundColor: colors.primary300,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l.translate('faq')),
            Tab(text: l.translate('feedback')),
          ],
          labelColor: colors.accent200,
          unselectedLabelColor: colors.text200,
          indicatorColor: colors.accent200,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(colors),
          _buildFeedbackTab(colors),
        ],
      ),
    );
  }

  Widget _buildFAQTab(AppColorTheme colors) {
    final l = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(_padding),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: _spacingMedium),
          color: colors.bg100,
          child: ExpansionTile(
            title: Text(
              l.translate(faq['question']),
              style: TextStyle(
                color: colors.primary300,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(_padding),
                child: Text(
                  l.translate(faq['answer']),
                  style: TextStyle(color: colors.text200),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackTab(AppColorTheme colors) {
    final l = AppLocalizations.of(context);
    final userInformation = Provider.of<UserInformationService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_padding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.translate('feedback_title'),
              style: TextStyle(
                color: colors.primary300,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: _spacingLarge),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l.translate('feedback_subject'),
                labelStyle: TextStyle(color: colors.text200),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.bg300),
                ),
              ),
              style: TextStyle(color: colors.text100),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.translate('please_enter_subject');
                }
                return null;
              },
            ),
            const SizedBox(height: _spacingMedium),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: l.translate('feedback_category'),
                labelStyle: TextStyle(color: colors.text200),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.bg300),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'general',
                  child: Text(l.translate('category_general')),
                ),
                DropdownMenuItem(
                  value: 'bug',
                  child: Text(l.translate('category_bug')),
                ),
                DropdownMenuItem(
                  value: 'feature',
                  child: Text(l.translate('category_feature')),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(l.translate('category_other')),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: _spacingMedium),
            Text(
              l.translate('rating'),
              style: TextStyle(color: colors.text200),
            ),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: colors.accent200,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: _spacingMedium),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: l.translate('feedback_message'),
                labelStyle: TextStyle(color: colors.text200),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.bg300),
                ),
              ),
              style: TextStyle(color: colors.text100),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.translate('please_enter_message');
                }
                return null;
              },
            ),
            const SizedBox(height: _spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final userId = userInformation.userId;
                      if (userId == null) {
                        throw Exception('User not logged in');
                      }

                      await _feedbackService.submitFeedback(
                        userId: userId,
                        title: _titleController.text,
                        message: _messageController.text,
                        category: _selectedCategory,
                        rating: _rating,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l.translate('feedback_submitted')),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(l.translate('error_submitting_feedback')),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent200,
                  foregroundColor: colors.bg100,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(l.translate('submit_feedback')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
