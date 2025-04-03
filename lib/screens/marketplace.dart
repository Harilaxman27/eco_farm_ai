import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/firebase_service.dart';

class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  File? _selectedImage;
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Active Listings", "4"),
                _buildStatItem("Total Sales", "₹2,450"),
                _buildStatItem("Avg. Price", "₹42/kg"),
              ],
            ),
          ),
          // Crop Listings
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getCropListings(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var listings = snapshot.data!.docs;

                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, size: 64, color: Colors.green.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text("No crops listed yet", style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                        SizedBox(height: 8),
                        Text("Add your first crop to start selling", style: TextStyle(color: Colors.grey.shade600)),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddCropDialog(context),
                          icon: Icon(Icons.add),
                          label: Text("Add Your First Crop"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    var crop = listings[index].data() as Map<String, dynamic>;

                    // Extract data safely
                    String cropName = crop['cropName'] ?? "Unknown Crop";
                    double quantity = (crop['quantity'] as num?)?.toDouble() ?? 0.0;
                    double pricePerKg = (crop['pricePerKg'] as num?)?.toDouble() ?? 0.0;
                    String imageUrl = crop['imageUrl'] ?? "";
                    Timestamp? uploadTimestamp = crop['uploadDate'];

                    // Calculate days on market and freshness
                    DateTime uploadDate = uploadTimestamp?.toDate() ?? DateTime.now();
                    int daysOnMarket = DateTime.now().difference(uploadDate).inDays;
                    int freshness = (10 - daysOnMarket).clamp(0, 10);

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                            : Icon(Icons.image, size: 60, color: Colors.grey),
                        title: Text("$cropName - ${quantity.toStringAsFixed(2)} kg"),
                        subtitle: Text("₹${pricePerKg.toStringAsFixed(2)}/kg - Freshness: $freshness/10"),
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showAddCropDialog(BuildContext context) {
    _cropNameController.clear();
    _quantityController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _selectedImage = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Add New Crop", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      setState(() {});
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(controller: _cropNameController, decoration: InputDecoration(labelText: "Crop Name*")),
                  SizedBox(height: 12),
                  TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Quantity (kg)*")),
                  SizedBox(height: 12),
                  TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Price per kg (₹)*")),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedImage != null) {
                        await _firebaseService.addCropListing(
                          _cropNameController.text,
                          double.parse(_quantityController.text),
                          double.parse(_priceController.text),
                          _selectedImage!,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Text("Add Crop"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
