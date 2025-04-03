import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user role
  Future<DocumentSnapshot> getUserRole(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Function to add a crop listing with Base64 image
  Future<void> addCropListing(String cropName, double quantity, double pricePerKg, String base64Image) async {
    try {
      String farmerId = FirebaseAuth.instance.currentUser!.uid;

      await _firestore.collection('marketplace').add({
        'farmerId': farmerId,
        'cropName': cropName,
        'quantity': quantity,
        'pricePerKg': pricePerKg,
        'uploadDate': FieldValue.serverTimestamp(),
        'freshnessScore': 10,
        'imageBase64': base64Image,  // ✅ Store Base64 string
      });

      print('✅ Crop listing added successfully.');
    } catch (e) {
      print('❌ Failed to add crop listing: $e');
    }
  }

  // Function to get all crop listings
  Stream<QuerySnapshot> getCropListings() {
    return _firestore.collection('marketplace').snapshots();
  }

  // Function to update price and freshness score over time
  Future<void> updateCropListings() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('marketplace').get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        DateTime uploadDate = (doc['uploadDate'] as Timestamp).toDate();
        int daysElapsed = DateTime.now().difference(uploadDate).inDays;

        if (daysElapsed > 0) {
          double newPrice = doc['pricePerKg'] * (1 - (0.05 * daysElapsed)); // Decrease by 5% per day
          int newFreshness = (10 - daysElapsed).clamp(0, 10); // Reduce freshness score

          await _firestore.collection('marketplace').doc(doc.id).update({
            'pricePerKg': newPrice,
            'freshnessScore': newFreshness,
          });
        }
      }
      print('✅ Crop listings updated successfully.');
    } catch (e) {
      print('❌ Error updating crop listings: $e');
    }
  }

  // Function to delete a crop listing
  Future<void> deleteCropListing(String cropId) async {
    try {
      await _firestore.collection('marketplace').doc(cropId).delete();
      print('✅ Crop listing deleted successfully.');
    } catch (e) {
      print('❌ Failed to delete crop listing: $e');
    }
  }

  // Function to update crop details (e.g., price, quantity)
  Future<void> updateCropDetails(String cropId, double newQuantity, double newPrice) async {
    try {
      await _firestore.collection('marketplace').doc(cropId).update({
        'quantity': newQuantity,
        'pricePerKg': newPrice,
      });

      print('✅ Crop details updated successfully.');
    } catch (e) {
      print('❌ Failed to update crop details: $e');
    }
  }
}
