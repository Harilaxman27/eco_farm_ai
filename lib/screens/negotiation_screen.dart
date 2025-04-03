import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firebase_service.dart';

class NegotiationScreen extends StatelessWidget {
  final String cropId;
  final String cropName;
  final FirebaseService _firebaseService = FirebaseService();

  NegotiationScreen({required this.cropId, required this.cropName});

  @override
  Widget build(BuildContext context) {
    print("Building NegotiationScreen for crop: $cropId with name: $cropName");

    return Scaffold(
      appBar: AppBar(
        title: Text('Offers for $cropName'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Pending Offers",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getNegotiationsForCrop(cropId),
              builder: (context, snapshot) {
                print("StreamBuilder state: ${snapshot.connectionState}");

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print("Error in negotiation stream: ${snapshot.error}");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          "Error loading offers: ${snapshot.error}",
                          style: TextStyle(fontSize: 16, color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Force refresh
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NegotiationScreen(
                                  cropId: cropId,
                                  cropName: cropName,
                                ),
                              ),
                            );
                          },
                          child: Text("Try Again"),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No pending offers yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                }

                var offers = snapshot.data!.docs;
                print("Found ${offers.length} pending offers");

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    var offer = offers[index].data() as Map<String, dynamic>;
                    String offerId = offers[index].id;
                    double proposedPrice = (offer['proposedPrice'] as num).toDouble();
                    double quantity = offer['quantity'] != null
                        ? (offer['quantity'] as num).toDouble()
                        : 0.0;
                    String buyerId = offer['buyerId'] ?? 'Unknown';
                    Timestamp timestamp = offer['timestamp'] as Timestamp? ?? Timestamp.now();

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(buyerId).get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                                      return Text("Loading buyer...");
                                    }

                                    String buyerName = "Unknown Buyer";
                                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                      var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                      buyerName = userData?['name'] ?? "Unknown Buyer";
                                    }

                                    return Text(
                                      buyerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  timestamp.toDate().toString().substring(0, 16),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Offered Price: ₹${proposedPrice.toStringAsFixed(2)}/kg",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (quantity > 0)
                              Text(
                                "Quantity: ${quantity.toStringAsFixed(1)} kg",
                                style: TextStyle(fontSize: 14),
                              ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.check),
                                    label: Text("Accept"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await _firebaseService.acceptOffer(cropId, offerId, proposedPrice);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Offer accepted!")),
                                        );
                                      } catch (e) {
                                        print("Error accepting offer: $e");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error: $e")),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.close),
                                    label: Text("Reject"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await _firebaseService.rejectOffer(offerId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Offer rejected")),
                                        );
                                      } catch (e) {
                                        print("Error rejecting offer: $e");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error: $e")),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}