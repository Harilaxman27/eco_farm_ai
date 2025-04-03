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

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _base64Image;
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyOffersScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getCropListings(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var listings = snapshot.data!.docs;

                if (listings.isEmpty) {
                  return Center(child: Text("No crops listed yet."));
                }

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

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: base64Image.isNotEmpty
                            ? Image.memory(base64Decode(base64Image), width: 60, height: 60, fit: BoxFit.cover)
                            : Icon(Icons.image, size: 60, color: Colors.grey),
                        title: Text("$cropName - ${quantity.toStringAsFixed(2)} kg"),
                        subtitle: Text("₹${pricePerKg.toStringAsFixed(2)}/kg"),
                        trailing: farmerId == _currentUserId
                            ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "edit") {
                              _showEditCropDialog(context, cropId, cropName, quantity, pricePerKg);
                            } else if (value == "view_offers") {
                              // Navigate to negotiation screen with cropId
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NegotiationScreen(cropId: cropId, cropName: cropName),
                                ),
                              );
                            } else if (value == "delete") {
                              _showDeleteConfirmation(context, cropId, cropName);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: "edit", child: Text("Edit")),
                            PopupMenuItem(value: "view_offers", child: Text("View Offers")),
                            PopupMenuItem(value: "delete", child: Text("Delete", style: TextStyle(color: Colors.red))),
                          ],
                        )
                            : ElevatedButton(
                          onPressed: () => _showNegotiationDialog(context, cropId, cropName, farmerId),
                          child: Text("Negotiate"),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCropDialog(context),
        label: Text("Add Crop"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
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
                TextField(
                  controller: _cropNameController,
                  decoration: InputDecoration(labelText: "Crop Name"),
                ),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Quantity (kg)"),
                ),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Price per kg (₹)"),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.photo),
                  label: Text("Add Image"),
                  onPressed: _pickImage,
                ),
                SizedBox(height: 12),
                if (_base64Image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(_base64Image!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                  SnackBar(content: Text("Crop added successfully")),
                );
              },
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
          title: Text("Edit Crop Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cropNameController,
                decoration: InputDecoration(labelText: "Crop Name"),
              ),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Quantity (kg)"),
              ),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Price per kg (₹)"),
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
                  SnackBar(content: Text("Crop details updated")),
                );
              },
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
          title: Text("Negotiate Price for $cropName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Your Offer Price (₹/kg)"),
              ),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Quantity (kg)"),
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
                    SnackBar(content: Text("Price proposal sent!")),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              },
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
          title: Text("Delete $cropName?"),
          content: Text("This action cannot be undone."),
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
                  SnackBar(content: Text("Crop listing deleted")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}