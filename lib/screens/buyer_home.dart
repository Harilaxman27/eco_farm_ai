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
  String searchQuery = "";

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

    Map<String, dynamic> cartItem = {
      'cropId': cropData.containsKey('id') ? cropData['id'] : '',
      'cropName': cropData['cropName'],
      'pricePerKg': cropData['pricePerKg'],
      'quantity': 1.0, // Default to 1kg
      'sellerId': cropData['farmerId'],
    };

    List<String> currentCart = prefs.getStringList('cart') ?? [];
    currentCart.add(jsonEncode(cartItem));
    await prefs.setStringList('cart', currentCart);

    setState(() {
      cartItems.add(cartItem);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${cropData['cropName']} added to cart!")),
    );
  }

  void _negotiatePrice(Map<String, dynamic> cropData, String cropId, String sellerId) async {
    TextEditingController priceController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    // Set default quantity to the available quantity or 1 if not available
    double availableQuantity = (cropData['quantity'] as num?)?.toDouble() ?? 1.0;
    quantityController.text = "1.0";  // Default to 1kg

    double maxQuantity = availableQuantity;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Propose Your Price"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Enter your price per kg",
                    hintText: "Current: ₹${cropData['pricePerKg'].toStringAsFixed(2)}"
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity (kg)",
                  hintText: "Max: $maxQuantity kg",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                double proposedPrice = double.tryParse(priceController.text) ?? 0.0;
                double quantity = double.tryParse(quantityController.text) ?? 0.0;

                if (proposedPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a valid price")),
                  );
                  return;
                }

                if (quantity <= 0 || quantity > maxQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a valid quantity (max: $maxQuantity kg)")),
                  );
                  return;
                }

                try {
                  await _firebaseService.proposePrice(
                    sellerId: sellerId,
                    cropId: cropId,
                    cropName: cropData['cropName'],
                    proposedPrice: proposedPrice,
                    quantity: quantity,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Price proposal sent!")),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
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
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
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

                // Filter listings based on search query if needed
                if (searchQuery.isNotEmpty) {
                  listings = listings.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String cropName = data['cropName']?.toString().toLowerCase() ?? '';
                    return cropName.contains(searchQuery);
                  }).toList();
                }

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
                    var cropDoc = listings[index];
                    var cropId = cropDoc.id;
                    var cropData = cropDoc.data() as Map<String, dynamic>;

                    // Add the document ID to the data for easy access
                    cropData['id'] = cropId;

                    String cropName = cropData['cropName'] ?? 'Unknown Crop';
                    double quantity = (cropData['quantity'] as num?)?.toDouble() ?? 0.0;
                    double pricePerKg = (cropData['pricePerKg'] as num?)?.toDouble() ?? 0.0;
                    String base64Image = cropData['imageBase64'] ?? "";
                    String sellerId = cropData['farmerId'] ?? "";

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            child: base64Image.isNotEmpty
                                ? Image.memory(
                              base64Decode(base64Image),
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              height: 100,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cropName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${quantity.toStringAsFixed(1)} kg available",
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                ),
                                Text(
                                  "₹${pricePerKg.toStringAsFixed(2)}/kg",
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _negotiatePrice(cropData, cropId, sellerId),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                        child: Text("Negotiate"),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _addToCart(cropData),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        child: Text("Add"),
                                      ),
                                    ),
                                  ],
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
}