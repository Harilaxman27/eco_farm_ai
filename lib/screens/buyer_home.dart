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
              await FirebaseAuth.instance.signOut(); // Logout user
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
                    var cropData = crop.data() as Map<String, dynamic>; // Explicitly cast to Map

                    // Ensure required fields exist
                    String cropName = cropData.containsKey('cropName') ? cropData['cropName'] : 'Unknown Crop';
                    double quantity = cropData.containsKey('quantity') ? (cropData['quantity'] as num).toDouble() : 0.0;
                    double pricePerKg = cropData.containsKey('pricePerKg') ? (cropData['pricePerKg'] as num).toDouble() : 0.0;
                    String imageUrl = cropData.containsKey('imageUrl') ? cropData['imageUrl'] : "";
                    Timestamp? uploadTimestamp = cropData.containsKey('uploadDate') ? cropData['uploadDate'] : null;

                    // Handle missing uploadDate
                    DateTime uploadDate = uploadTimestamp != null ? uploadTimestamp.toDate() : DateTime.now();
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
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                    imageUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 100,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                                    ),
                                  )
                                      : Container(
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                                  ),
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
    String imageUrl = cropData['imageUrl'] ?? "";
    Timestamp? uploadTimestamp = cropData['uploadDate'];

    DateTime uploadDate = uploadTimestamp != null ? uploadTimestamp.toDate() : DateTime.now();
    double updatedPrice = _calculatePrice(pricePerKg, uploadDate);
    int freshness = _calculateFreshness(uploadDate);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    )
                        : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cropName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "₹${updatedPrice.toStringAsFixed(2)} per kg",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Available: ${quantity.toStringAsFixed(1)} kg",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.eco, color: _getFreshnessColor(freshness), size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Freshness: $freshness/10",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                "Description",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                cropData['description'] ?? "Fresh produce directly from the farm. No chemicals used.",
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.favorite_border),
                      label: Text("Save"),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Add purchase functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Added to cart")),
                        );
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.shopping_cart),
                      label: Text("Add to Cart"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getFreshnessColor(int freshness) {
    if (freshness >= 8) return Colors.green;
    if (freshness >= 5) return Colors.orange;
    return Colors.red;
  }

  // Function to calculate the updated price based on the time elapsed
  double _calculatePrice(double pricePerKg, DateTime uploadDate) {
    int daysElapsed = DateTime.now().difference(uploadDate).inDays;
    return daysElapsed > 0 ? pricePerKg * (1 - (0.05 * daysElapsed)) : pricePerKg;
  }

  // Function to calculate the freshness score dynamically
  int _calculateFreshness(DateTime uploadDate) {
    int daysElapsed = DateTime.now().difference(uploadDate).inDays;
    return (10 - daysElapsed).clamp(0, 10);
  }
}