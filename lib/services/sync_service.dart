import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tourist_object.dart';
import 'local_db_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDbService _localDbService = LocalDbService();

  Future<void> syncData() async {
    try {
      // 1. Fetch data from Firestore
      final snapshot = await _firestore.collection('tourist_objects').get();
      
      List<TouristObject> objects = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TouristObject.fromMap(data);
      }).toList();

      // 2. Save data to local SQLite database
      if (objects.isNotEmpty) {
        // Clear old data (or could implement a smarter diff sync)
        await _localDbService.clearAll();
        await _localDbService.insertMultipleTouristObjects(objects);
      }
    } catch (e) {
      print('Sync failed: $e');
      // Typically we handle offline scenario by just ignoring this error
      // and letting the app read from the local DB.
    }
  }

  // Method to add a new object to Firestore (mainly for Admin use)
  Future<void> addTouristObject(TouristObject object) async {
    await _firestore.collection('tourist_objects').doc(object.id).set(object.toMap());
  }

  // Stream for real-time updates if needed
  Stream<List<TouristObject>> streamTouristObjects() {
    return _firestore.collection('tourist_objects').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TouristObject.fromMap(data);
      }).toList();
    });
  }

  // Method to submit a review and update average rating
  Future<void> submitReview(String placeId, double rating, String comment) async {
    try {
      // 1. Add review to subcollection or separate collection
      await _firestore.collection('reviews').add({
        'placeId': placeId,
        'rating': rating,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update object's average rating transactionally
      final docRef = _firestore.collection('tourist_objects').doc(placeId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final double currentRating = data['rating']?.toDouble() ?? 0.0;
        final int currentCount = data['reviewCount'] ?? 0;

        final double newRating = ((currentRating * currentCount) + rating) / (currentCount + 1);
        final int newCount = currentCount + 1;

        transaction.update(docRef, {
          'rating': newRating,
          'reviewCount': newCount,
        });
      });
    } catch (e) {
      print('Failed to submit review: $e');
      throw Exception('Review submission failed');
    }
  }
}
