import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get user role
  Future<DocumentSnapshot> getUserRole(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // ✅ Add a crop listing with Base64 image
  Future<void> addCropListing(
      String cropName, double quantity, double pricePerKg, String base64Image) async {
    try {
      String farmerId = FirebaseAuth.instance.currentUser!.uid;

      await _firestore.collection('marketplace').add({
        'farmerId': farmerId,
        'cropName': cropName,
        'quantity': quantity,
        'pricePerKg': pricePerKg,
        'uploadDate': FieldValue.serverTimestamp(),
        'freshnessScore': 10,
        'imageBase64': base64Image,
      });

      print('✅ Crop listing added successfully.');
    } catch (e) {
      print('❌ Failed to add crop listing: $e');
      throw e;
    }
  }

  // ✅ Get all crop listings
  Stream<QuerySnapshot> getCropListings() {
    return _firestore.collection('marketplace').snapshots();
  }

  // ✅ Update price and freshness score over time
  Future<void> updateCropListings() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('marketplace').get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        DateTime uploadDate = (doc['uploadDate'] as Timestamp).toDate();
        int daysElapsed = DateTime.now().difference(uploadDate).inDays;

        if (daysElapsed > 0) {
          double newPrice = doc['pricePerKg'] * (1 - (0.05 * daysElapsed));
          int newFreshness = (10 - daysElapsed).clamp(0, 10);

          await _firestore.collection('marketplace').doc(doc.id).update({
            'pricePerKg': newPrice,
            'freshnessScore': newFreshness,
          });
        }
      }
      print('✅ Crop listings updated successfully.');
    } catch (e) {
      print('❌ Error updating crop listings: $e');
      throw e;
    }
  }

  // ✅ Delete a crop listing
  Future<void> deleteCropListing(String cropId) async {
    try {
      await _firestore.collection('marketplace').doc(cropId).delete();
      print('✅ Crop listing deleted successfully.');
    } catch (e) {
      print('❌ Failed to delete crop listing: $e');
      throw e;
    }
  }

  // ✅ Update crop details (e.g., price, quantity)
  Future<void> updateCropDetails(String cropId, double newQuantity, double newPrice) async {
    try {
      await _firestore.collection('marketplace').doc(cropId).update({
        'quantity': newQuantity,
        'pricePerKg': newPrice,
      });

      print('✅ Crop details updated successfully.');
    } catch (e) {
      print('❌ Failed to update crop details: $e');
      throw e;
    }
  }

  // 🔥 Buyer sends a price negotiation offer
  Future<void> proposePrice({
    required String sellerId,
    required String cropId,
    required String cropName,
    required double proposedPrice,
    required double quantity,
  }) async {
    try {
      String buyerId = FirebaseAuth.instance.currentUser?.uid ?? "";

      if (buyerId.isEmpty) {
        throw Exception("User not authenticated");
      }

      print('📝 Creating negotiation: buyer=$buyerId, seller=$sellerId, crop=$cropId');

      await _firestore.collection('negotiations').add({
        'buyerId': buyerId,
        'sellerId': sellerId,
        'cropId': cropId,
        'cropName': cropName,
        'proposedPrice': proposedPrice,
        'quantity': quantity,
        'status': 'Pending', // Can be 'Pending', 'Accepted', or 'Rejected'
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ Negotiation request sent.');
    } catch (e) {
      print('❌ Failed to send negotiation request: $e');
      throw e;
    }
  }

  // 🔥 Fetch negotiations for the logged-in buyer
  Stream<QuerySnapshot> getNegotiationsForBuyer(String buyerId) {
    print('🔍 Getting negotiations for buyer: $buyerId');
    return _firestore
        .collection('negotiations')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // 🔥 Fetch negotiations for a seller's specific crop
  Stream<QuerySnapshot> getNegotiationsForCrop(String cropId) {
    print('🔍 Getting negotiations for crop: $cropId');

    // Get current user ID
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Query for negotiations where the current user is the seller
    // This addresses the permission issue by only showing negotiations where the user is the seller
    return _firestore
        .collection('negotiations')
        .where('cropId', isEqualTo: cropId)
        .where('sellerId', isEqualTo: userId)
        .where('status', isEqualTo: 'Pending')
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // 🔥 Fetch negotiations for a logged-in seller
  Stream<QuerySnapshot> getNegotiationsForSeller(String sellerId) {
    print('🔍 Getting negotiations for seller: $sellerId');
    return _firestore
        .collection('negotiations')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // 🔥 Accept an offer and update price in marketplace
  Future<void> acceptOffer(String cropId, String offerId, double newPrice) async {
    try {
      print('🔍 Accepting offer: $offerId for crop: $cropId');

      // Update the crop price in the marketplace
      await _firestore.collection('marketplace').doc(cropId).update({'pricePerKg': newPrice});

      // Update the negotiation status
      await _firestore.collection('negotiations').doc(offerId).update({'status': 'Accepted'});

      print('✅ Offer accepted.');
    } catch (e) {
      print('❌ Error accepting offer: $e');
      throw e;
    }
  }

  // 🔥 Reject an offer
  Future<void> rejectOffer(String offerId) async {
    try {
      print('🔍 Rejecting offer: $offerId');
      await _firestore.collection('negotiations').doc(offerId).update({'status': 'Rejected'});
      print('❌ Offer rejected.');
    } catch (e) {
      print('❌ Error rejecting offer: $e');
      throw e;
    }
  }
}