import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  CartScreen({required this.cartItems});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<int, int> itemQuantities = {};
  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize quantities and calculate initial total
    for (int i = 0; i < widget.cartItems.length; i++) {
      itemQuantities[i] = 1;
    }
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0;
    for (int i = 0; i < widget.cartItems.length; i++) {
      total += (widget.cartItems[i]['pricePerKg'] as double) * (itemQuantities[i] ?? 1);
    }
    setState(() {
      totalAmount = total;
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity > 0) {
      setState(() {
        itemQuantities[index] = quantity;
      });
      _calculateTotal();
    }
  }

  Future<void> removeFromCart(int index) async {
    setState(() {
      widget.cartItems.removeAt(index);
      itemQuantities.remove(index);

      // Re-index quantities after removal
      Map<int, int> newQuantities = {};
      itemQuantities.forEach((key, value) {
        if (key > index) {
          newQuantities[key - 1] = value;
        } else if (key < index) {
          newQuantities[key] = value;
        }
      });
      itemQuantities = newQuantities;
    });

    _calculateTotal();

    // Update SharedPreferences
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> encodedCart = widget.cartItems.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList('cart', encodedCart);
    } catch (e) {
      print('Error updating cart in SharedPreferences: $e');
    }
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Order Confirmation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your order has been placed!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
            SizedBox(height: 10),
            Text('Your fresh produce will be delivered soon.'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              _clearCart();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _clearCart() async {
    setState(() {
      widget.cartItems.clear();
      itemQuantities.clear();
      totalAmount = 0;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cart', []);
    } catch (e) {
      print('Error clearing cart in SharedPreferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: widget.cartItems.isEmpty
                ? null
                : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Clear Cart?'),
                  content: Text('Are you sure you want to remove all items?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: Text('Clear'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearCart();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: widget.cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 20),
            Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Add fresh produce to get started",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text("Continue Shopping"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                var item = widget.cartItems[index];
                double itemPrice = (item['pricePerKg'] as double) * (itemQuantities[index] ?? 1);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Product image or icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.eco,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 16),
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['cropName'] ?? 'Unknown Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "₹${(item['pricePerKg'] as double).toStringAsFixed(2)}/kg",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  // Quantity controls
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _updateQuantity(
                                              index, (itemQuantities[index] ?? 1) - 1),
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.remove, size: 18),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            "${itemQuantities[index] ?? 1}",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _updateQuantity(
                                              index, (itemQuantities[index] ?? 1) + 1),
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.add, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  // Item subtotal
                                  Text(
                                    "₹${itemPrice.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Remove button
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                          onPressed: () => removeFromCart(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Checkout section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${totalAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _showCheckoutDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "CHECKOUT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}