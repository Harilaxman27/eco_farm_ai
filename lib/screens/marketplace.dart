import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firebase_service.dart';
import 'my_offers_screen.dart';
import 'negotiation_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  String? _base64Image;
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late AnimationController _animationController;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = "";
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search crops...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          autofocus: true,
        )
            : Text('Farmer Marketplace',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            )),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'My Offers',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyOffersScreen())
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategorySelector(),
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

                // Filter based on search query if necessary
                if (_searchQuery.isNotEmpty) {
                  listings = listings.where((doc) {
                    var crop = doc.data() as Map<String, dynamic>;
                    return (crop['cropName'] as String?)?.toLowerCase().contains(_searchQuery) ?? false;
                  }).toList();
                }

                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, size: 70, color: Colors.green.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? "No crops listed yet." : "No matching crops found.",
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = "";
                                _searchController.clear();
                                _isSearching = false;
                              });
                            },
                            child: Text("Clear Search"),
                          ),
                      ],
                    ),
                  );
                }

                return _buildCropListings(listings);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCropDialog(context),
        label: Text("Add Crop"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.green.shade800,
        elevation: 4,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.green.shade100.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          _categoryChip("All", true),
          _categoryChip("Vegetables", false),
          _categoryChip("Fruits", false),
          _categoryChip("Grains", false),
          _categoryChip("Spices", false),
          _categoryChip("Others", false),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          // This would be implemented to filter by category
          // Not changing functionality as per requirements
        },
        backgroundColor: isSelected ? Colors.green.shade800 : Colors.white,
        selectedColor: Colors.green.shade800,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        elevation: 3,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildCropListings(List<QueryDocumentSnapshot> listings) {
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        var crop = listings[index].data() as Map<String, dynamic>;
        String cropId = listings[index].id;
        String cropName = crop['cropName'] ?? "Unknown Crop";
        double quantity = (crop['quantity'] as num?)?.toDouble() ?? 0.0;
        double pricePerKg = (crop['pricePerKg'] as num?)?.toDouble() ?? 0.0;
        String base64Image = crop['imageBase64'] ?? "";
        String farmerId = crop['farmerId'] ?? "";

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop image
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: base64Image.isNotEmpty
                        ? Image.memory(
                      base64Decode(base64Image),
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: double.infinity,
                      height: 140,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
                  ),
                  // Crop details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cropName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "₹${pricePerKg.toStringAsFixed(2)}/kg",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Available: ${quantity.toStringAsFixed(2)} kg",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        SizedBox(height: 16),
                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (farmerId == _currentUserId)
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: Icon(Icons.edit, size: 18),
                                    label: Text("Edit"),
                                    onPressed: () => _showEditCropDialog(
                                        context, cropId, cropName, quantity, pricePerKg
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: Icon(Icons.list_alt, size: 18),
                                    label: Text("Offers"),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NegotiationScreen(
                                            cropId: cropId,
                                            cropName: cropName
                                        ),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red.shade300),
                                    onPressed: () => _showDeleteConfirmation(
                                        context, cropId, cropName
                                    ),
                                  ),
                                ],
                              )
                            else
                              ElevatedButton.icon(
                                icon: Icon(Icons.handshake),
                                label: Text("Negotiate"),
                                onPressed: () => _showNegotiationDialog(
                                    context, cropId, cropName, farmerId
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  // Show dialog to add a new crop
  void _showAddCropDialog(BuildContext context) {
    // Reset controllers
    _cropNameController.clear();
    _quantityController.clear();
    _priceController.clear();
    _base64Image = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Crop"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_base64Image != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_base64Image!),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _base64Image = null;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Add Image", style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                TextField(
                  controller: _cropNameController,
                  decoration: InputDecoration(
                    labelText: "Crop Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.eco),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Quantity (kg)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Price per kg (₹)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String cropName = _cropNameController.text.trim();
                double quantity = double.tryParse(_quantityController.text) ?? 0.0;
                double pricePerKg = double.tryParse(_priceController.text) ?? 0.0;

                if (cropName.isEmpty || quantity <= 0 || pricePerKg <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter valid crop details")),
                  );
                  return;
                }

                await _firebaseService.addCropListing(
                  cropName,
                  quantity,
                  pricePerKg,
                  _base64Image ?? "",
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Crop added successfully"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to edit crop details
  void _showEditCropDialog(BuildContext context, String cropId, String cropName, double quantity, double pricePerKg) {
    _cropNameController.text = cropName;
    _quantityController.text = quantity.toString();
    _priceController.text = pricePerKg.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.green.shade700),
              SizedBox(width: 8),
              Text("Edit $cropName"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cropNameController,
                decoration: InputDecoration(
                  labelText: "Crop Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.eco),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity (kg)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price per kg (₹)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
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
                double newQuantity = double.tryParse(_quantityController.text) ?? 0.0;
                double newPrice = double.tryParse(_priceController.text) ?? 0.0;

                if (newQuantity <= 0 || newPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter valid values")),
                  );
                  return;
                }

                await _firebaseService.updateCropDetails(cropId, newQuantity, newPrice);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Crop details updated"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to negotiate price
  void _showNegotiationDialog(BuildContext context, String cropId, String cropName, String sellerId) {
    TextEditingController priceController = TextEditingController();
    TextEditingController quantityController = TextEditingController();
    quantityController.text = "1.0"; // Default quantity

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Negotiate for $cropName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Make a fair offer. Good negotiations build lasting relationships!",
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Your Offer Price (₹/kg)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity (kg)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
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

                if (quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a valid quantity")),
                  );
                  return;
                }

                try {
                  await _firebaseService.proposePrice(
                    sellerId: sellerId,
                    cropId: cropId,
                    cropName: cropName,
                    proposedPrice: proposedPrice,
                    quantity: quantity,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Price proposal sent!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              child: Text("Send Offer"),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for deleting a crop
  void _showDeleteConfirmation(BuildContext context, String cropId, String cropName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
          title: Text("Delete $cropName?"),
          content: Text("This action cannot be undone and will remove all associated offers."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firebaseService.deleteCropListing(cropId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Crop listing deleted"),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}