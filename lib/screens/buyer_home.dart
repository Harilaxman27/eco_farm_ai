import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../utils/firebase_service.dart';

class BuyerHome extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Fresh Harvest Market",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search crops...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          // Crop listings
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getCropListings(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var listings = snapshot.data!.docs;

                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, size: 64, color: Colors.green.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text(
                          "No crops available at the moment",
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    var crop = listings[index];
                    var cropData = crop.data() as Map<String, dynamic>;

                    String cropName = cropData['cropName'] ?? 'Unknown Crop';
                    double quantity = (cropData['quantity'] as num?)?.toDouble() ?? 0.0;
                    double pricePerKg = (cropData['pricePerKg'] as num?)?.toDouble() ?? 0.0;
                    String base64Image = cropData['imageBase64'] ?? "";
                    Timestamp? uploadTimestamp = cropData['uploadDate'];

                    DateTime uploadDate = uploadTimestamp?.toDate() ?? DateTime.now();
                    double updatedPrice = _calculatePrice(pricePerKg, uploadDate);
                    int updatedFreshness = _calculateFreshness(uploadDate);
                    Color freshnessColor = _getFreshnessColor(updatedFreshness);

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          _showCropDetails(context, cropData);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Crop image
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  child: base64Image.isNotEmpty
                                      ? Image.memory(
                                    base64Decode(base64Image),
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                                  )
                                      : _imagePlaceholder(),
                                ),
                                // Freshness badge
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: freshnessColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "$updatedFreshness/10",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Crop details
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cropName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "${quantity.toStringAsFixed(1)} kg available",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "₹${updatedPrice.toStringAsFixed(2)}/kg",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
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

  void _showCropDetails(BuildContext context, Map<String, dynamic> cropData) {
    String cropName = cropData['cropName'] ?? 'Unknown Crop';
    double quantity = (cropData['quantity'] as num?)?.toDouble() ?? 0.0;
    double pricePerKg = (cropData['pricePerKg'] as num?)?.toDouble() ?? 0.0;
    String base64Image = cropData['imageBase64'] ?? "";
    Timestamp? uploadTimestamp = cropData['uploadDate'];

    DateTime uploadDate = uploadTimestamp?.toDate() ?? DateTime.now();
    double updatedPrice = _calculatePrice(pricePerKg, uploadDate);
    int freshness = _calculateFreshness(uploadDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(cropName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              base64Image.isNotEmpty
                  ? Image.memory(base64Decode(base64Image), height: 150, width: 150, fit: BoxFit.cover)
                  : _imagePlaceholder(),
              SizedBox(height: 10),
              Text("₹${updatedPrice.toStringAsFixed(2)} per kg", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Available: ${quantity.toStringAsFixed(1)} kg"),
              Text("Freshness: $freshness/10", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
            TextButton(
              onPressed: () {
                // Add to cart functionality
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to cart")));
                Navigator.pop(context);
              },
              child: Text("Add to Cart"),
            ),
          ],
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 100,
      color: Colors.grey.shade200,
      child: Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }

  Color _getFreshnessColor(int freshness) {
    if (freshness >= 8) return Colors.green;
    if (freshness >= 5) return Colors.orange;
    return Colors.red;
  }

  double _calculatePrice(double pricePerKg, DateTime uploadDate) {
    int daysElapsed = DateTime.now().difference(uploadDate).inDays;
    return daysElapsed > 0 ? pricePerKg * (1 - (0.05 * daysElapsed)) : pricePerKg;
  }

  int _calculateFreshness(DateTime uploadDate) {
    int daysElapsed = DateTime.now().difference(uploadDate).inDays;
    return (10 - daysElapsed).clamp(0, 10);
  }
}
