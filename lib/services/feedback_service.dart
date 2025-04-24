import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFeedback({
    required String userId,
    required String title,
    required String message,
    required String category,
    required int rating,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'userId': userId,
        'title': title,
        'message': message,
        'category': category,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  Stream<QuerySnapshot> getUserFeedback(String userId) {
    return _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
