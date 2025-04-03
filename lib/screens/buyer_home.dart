import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../utils/firebase_service.dart';
import 'cart_screen.dart';

class BuyerHome extends StatefulWidget {
  @override
  _BuyerHomeState createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedCart = prefs.getStringList('cart') ?? [];

    setState(() {
      cartItems = storedCart.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _addToCart(Map<String, dynamic> cropData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String cropName = cropData['cropName'] ?? 'Unknown Crop';
    double pricePerKg = (cropData['pricePerKg'] as num?)?.toDouble() ?? 0.0;
    double quantity = (cropData['quantity'] as num?)?.toDouble() ?? 0.0;

    Map<String, dynamic> cartItem = {
      'cropName': cropName,
      'pricePerKg': pricePerKg,
      'quantity': quantity,
    };

    List<String> currentCart = prefs.getStringList('cart') ?? [];
    currentCart.add(jsonEncode(cartItem));
    await prefs.setStringList('cart', currentCart);

    setState(() {
      cartItems.add(cartItem);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$cropName added to cart!")),
    );
  }

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
            icon: Icon(Icons.shopping_cart),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              List<String> storedCart = prefs.getStringList('cart') ?? [];

              List<Map<String, dynamic>> decodedCart =
              storedCart.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(cartItems: decodedCart),
                ),
              );
            },
          ),
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
                    childAspectRatio: 0.75, // Increase this value to give more vertical space
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      _imagePlaceholder(),
                                )
                                    : _imagePlaceholder(),
                              ),
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
                          Padding(
                            padding: EdgeInsets.all(8),
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
                                SizedBox(height: 2),
                                Text(
                                  "${quantity.toStringAsFixed(1)} kg available",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "₹${updatedPrice.toStringAsFixed(2)}/kg",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _addToCart(cropData);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Add to Cart",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  double _calculatePrice(double pricePerKg, DateTime uploadDate) {
    int daysElapsed = DateTime.now().difference(uploadDate).inDays;
    return daysElapsed > 0 ? pricePerKg * (1 - (0.05 * daysElapsed)) : pricePerKg;
  }

  int _calculateFreshness(DateTime uploadDate) {
    int daysElapsed = DateTime.now().difference(uploadDate).inDays;
    return (10 - daysElapsed).clamp(0, 10);
  }

  Color _getFreshnessColor(int freshness) {
    return freshness >= 8 ? Colors.green : (freshness >= 5 ? Colors.orange : Colors.red);
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 100,
      color: Colors.grey.shade200,
      child: Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }
}