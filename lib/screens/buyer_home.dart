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
  bool isGridView = true;

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

    // Show animated snackbar with green color
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("${cropData['cropName']} added to cart!"),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _negotiatePrice(Map<String, dynamic> cropData, String cropId, String sellerId) async {
    TextEditingController priceController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    // Set default quantity to the available quantity or 1 if not available
    double availableQuantity = (cropData['quantity'] as num?)?.toDouble() ?? 1.0;
    quantityController.text = "1.0";  // Default to 1kg

    double maxQuantity = availableQuantity;
    double currentPrice = (cropData['pricePerKg'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.handshake, color: Colors.orange),
              SizedBox(width: 8),
              Flexible(child: Text("Propose Your Price")),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Current price: ₹${currentPrice.toStringAsFixed(2)}/kg",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Your price per kg",
                  prefixText: "₹ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity (kg)",
                  hintText: "Max: $maxQuantity kg",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange, width: 2),
                  ),
                  suffixText: "kg",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
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
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text("Price proposal sent successfully!"),
                        ],
                      ),
                      backgroundColor: Colors.orange.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Submit Offer"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 100, color: Colors.green.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            "No crops available at the moment",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Text(
            "Check back later for fresh harvests",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> cropData, String cropId) {
    String cropName = cropData['cropName'] ?? 'Unknown Crop';
    double quantity = (cropData['quantity'] as num?)?.toDouble() ?? 0.0;
    double pricePerKg = (cropData['pricePerKg'] as num?)?.toDouble() ?? 0.0;
    String base64Image = cropData['imageBase64'] ?? "";
    String sellerId = cropData['farmerId'] ?? "";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.green.withOpacity(0.3),
      child: ConstrainedBox(  // Add this ConstrainedBox
        constraints: BoxConstraints(
          minHeight: 100,
          maxHeight: 240,  // Limit the maximum height
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,  // Changed to min
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: base64Image.isNotEmpty
                      ? Image.memory(
                    base64Decode(base64Image),
                    height: 110,  // Slightly reduced from 120
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 110,  // Slightly reduced from 120
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image, color: Colors.grey.shade400, size: 40),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${quantity.toStringAsFixed(1)} kg",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(  // Wrap this section in Expanded
              child: Padding(
                padding: EdgeInsets.all(8),  // Reduced from 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,  // Use min size
                  children: [
                    Text(
                      cropName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),  // Reduced font size
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),  // Reduced from 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.currency_rupee, size: 14, color: Colors.green.shade700),  // Reduced size
                            Text(
                              "${pricePerKg.toStringAsFixed(2)}/kg",
                              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 14),  // Reduced font size
                            ),
                          ],
                        ),
                        Icon(Icons.verified, color: Colors.green, size: 14),  // Reduced size
                      ],
                    ),
                    SizedBox(height: 8),  // Reduced from 12
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 30,  // Reduced from 32
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.handshake, size: 14),  // Reduced size
                              label: Text("Negotiate", style: TextStyle(fontSize: 11)),  // Reduced font size
                              onPressed: () => _negotiatePrice(cropData, cropId, sellerId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),  // Reduced padding
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),  // Reduced from 8
                        Expanded(
                          child: SizedBox(
                            height: 30,  // Reduced from 32
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.add_shopping_cart, size: 14),  // Reduced size
                              label: Text("Add", style: TextStyle(fontSize: 11)),  // Reduced font size
                              onPressed: () => _addToCart(cropData),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),  // Reduced padding
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> cropData, String cropId) {
    String cropName = cropData['cropName'] ?? 'Unknown Crop';
    double quantity = (cropData['quantity'] as num?)?.toDouble() ?? 0.0;
    double pricePerKg = (cropData['pricePerKg'] as num?)?.toDouble() ?? 0.0;
    String base64Image = cropData['imageBase64'] ?? "";
    String sellerId = cropData['farmerId'] ?? "";

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.green.withOpacity(0.3),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            child: base64Image.isNotEmpty
                ? Image.memory(
              base64Decode(base64Image),
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            )
                : Container(
              height: 100,
              width: 100,
              color: Colors.grey.shade200,
              child: Icon(Icons.image, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          cropName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${quantity.toStringAsFixed(1)} kg",
                          style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "₹${pricePerKg.toStringAsFixed(2)}/kg",
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32, // Fixed height to prevent overflow
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.handshake, size: 16),
                            label: Text("Negotiate", style: TextStyle(fontSize: 12)),
                            onPressed: () => _negotiatePrice(cropData, cropId, sellerId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 32, // Fixed height to prevent overflow
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add_shopping_cart, size: 16),
                            label: Text("Add", style: TextStyle(fontSize: 12)),
                            onPressed: () => _addToCart(cropData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Fresh Harvest Market",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
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
              if (cartItems.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      "${cartItems.length}",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
          Container(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search for fresh produce...",
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Fresh Produce",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.grid_view,
                            color: isGridView ? Colors.white : Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              isGridView = true;
                            });
                          },
                          iconSize: 20,
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.view_list,
                            color: !isGridView ? Colors.white : Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              isGridView = false;
                            });
                          },
                          iconSize: 20,
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getCropListings(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
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
                  return _buildEmptyState();
                }

                if (isGridView) {
                  return GridView.builder(
                    padding: EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85, // Adjusted for proper fit without overflow
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      var cropDoc = listings[index];
                      var cropId = cropDoc.id;
                      var cropData = cropDoc.data() as Map<String, dynamic>;

                      // Add the document ID to the data for easy access
                      cropData['id'] = cropId;

                      return _buildGridItem(cropData, cropId);
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      var cropDoc = listings[index];
                      var cropId = cropDoc.id;
                      var cropData = cropDoc.data() as Map<String, dynamic>;

                      // Add the document ID to the data for easy access
                      cropData['id'] = cropId;

                      return _buildListItem(cropData, cropId);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}