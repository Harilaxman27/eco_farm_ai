import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get user role
  Future<DocumentSnapshot> getUserRole(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Function to upload crop image to Firebase Storage
  Future<String> uploadCropImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = _storage.ref().child("crop_images/$fileName.jpg");
    UploadTask uploadTask = ref.putFile(imageFile);

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL(); // Return the image URL
  }

  // Function to add a crop listing with image
  Future<void> addCropListing(String cropName, double quantity, double pricePerKg, File imageFile) async {
    String farmerId = FirebaseAuth.instance.currentUser!.uid;

    // Upload the image and get the URL
    String imageUrl = await uploadCropImage(imageFile);

    await _firestore.collection('marketplace').add({
      'farmerId': farmerId,
      'cropName': cropName,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'uploadDate': FieldValue.serverTimestamp(),
      'freshnessScore': 10, // Initial freshness score
      'imageUrl': imageUrl,  // Store the image URL
    });
  }

  // Function to get all crop listings
  Stream<QuerySnapshot> getCropListings() {
    return _firestore.collection('marketplace').snapshots();
  }

  // Function to update price and freshness score over time
  Future<void> updateCropListings() async {
    QuerySnapshot querySnapshot = await _firestore.collection('marketplace').get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      DateTime uploadDate = (doc['uploadDate'] as Timestamp).toDate();
      int daysElapsed = DateTime.now().difference(uploadDate).inDays;

      if (daysElapsed > 0) {
        double newPrice = doc['pricePerKg'] * (1 - (0.05 * daysElapsed)); // Decrease by 5% each day
        int newFreshness = (10 - daysElapsed).clamp(0, 10); // Reduce freshness score

        await _firestore.collection('marketplace').doc(doc.id).update({
          'pricePerKg': newPrice,
          'freshnessScore': newFreshness,
        });
      }
    }
  }
}
