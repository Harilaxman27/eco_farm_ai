import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firebase_service.dart';

class MyOffersScreen extends StatefulWidget {
  @override
  _MyOffersScreenState createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isSeller = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      DocumentSnapshot userDoc = await _firebaseService.getUserRole(_currentUserId);
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          _isSeller = userData?['role'] == 'farmer';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Negotiations'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _isSeller
            ? _firebaseService.getNegotiationsForSeller(_currentUserId)
            : _firebaseService.getNegotiationsForBuyer(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading negotiations: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No negotiations yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _isSeller
                        ? "You'll see offers from buyers here"
                        : "Your offers to sellers will appear here",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          var negotiations = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: negotiations.length,
            itemBuilder: (context, index) {
              var offer = negotiations[index].data() as Map<String, dynamic>;
              String cropName = offer['cropName'] ?? "Unknown Crop";
              double proposedPrice = (offer['proposedPrice'] as num).toDouble();
              double quantity = offer['quantity'] != null
                  ? (offer['quantity'] as num).toDouble()
                  : 0.0;
              String status = offer['status'] ?? "Pending";
              Timestamp timestamp = offer['timestamp'] as Timestamp? ?? Timestamp.now();

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _getStatusColor(status).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cropName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(status),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.monetization_on, size: 16, color: Colors.green[700]),
                          SizedBox(width: 4),
                          Text(
                            "Offered Price: ₹${proposedPrice.toStringAsFixed(2)}/kg",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      if (quantity > 0) SizedBox(height: 4),
                      if (quantity > 0)
                        Row(
                          children: [
                            Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              "Quantity: ${quantity.toStringAsFixed(1)} kg",
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            timestamp.toDate().toString().substring(0, 16),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Accepted":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}