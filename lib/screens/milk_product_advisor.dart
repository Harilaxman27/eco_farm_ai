import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MilkProductAdvisor extends StatefulWidget {
  const MilkProductAdvisor({super.key});

  @override
  State<MilkProductAdvisor> createState() => _MilkProductAdvisorState();
}

class _MilkProductAdvisorState extends State<MilkProductAdvisor> {
  final TextEditingController _milkQtyController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  List<ProductInfo> milkProducts = [];
  final ScrollController _scrollController = ScrollController();

  Future<void> _getMilkProductRecommendations() async {
    final milkQtyText = _milkQtyController.text.trim();
    if (milkQtyText.isEmpty || double.tryParse(milkQtyText) == null) {
      setState(() => errorMessage = 'Please enter a valid milk quantity.');
      return;
    }

    double milkQuantity = double.parse(milkQtyText);

    setState(() {
      isLoading = true;
      errorMessage = "";
      milkProducts = [];
    });

    try {
      String apiKey = "AIzaSyAQ2YmmqHCYG9rAP9ub5HWjNCQQ4WfQfUQ";
      String apiUrl =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey";

      String prompt = """
Suggest what dairy products can be made from $milkQuantity liters of milk.
List products like paneer, cheese, butter, curd, ghee, etc.
For each product, provide:
1. Name of the product
2. Estimated yield from $milkQuantity L
3. Required ingredients with quantities
4. Equipment needed for preparation
5. Step-by-step preparation method (numbered steps)
6. Estimated preparation time
7. Shelf life and storage recommendations
8. Potential market value or selling price in Indian Rupees
9. Health benefits
10. Common uses in Indian cuisine

Structure each product as follows (use exactly this format and these section titles):
PRODUCT: [Name of the product]
YIELD: [Estimated yield]
INGREDIENTS: [List of ingredients]
EQUIPMENT: [Required equipment]
STEPS: [Step-by-step preparation]
TIME: [Preparation time]
STORAGE: [Storage recommendations]
PRICE: [Market value]
BENEFITS: [Health benefits]
USES: [Common uses]

Format the response so each product section is clearly separated.
Keep it concise and easy to understand for Indian dairy farmers.
""";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        // Process the text into structured data
        List<ProductInfo> parsedProducts = parseProductData(text);

        setState(() {
          milkProducts = parsedProducts;
        });
      } else {
        throw "API error: ${response.statusCode}";
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  List<ProductInfo> parseProductData(String text) {
    List<ProductInfo> products = [];

    // Split by products - looking for "PRODUCT:" as the separator
    List<String> productSections = text.split('PRODUCT:');

    // Skip first element if it's empty
    for (int i = 1; i < productSections.length; i++) {
      String section = 'PRODUCT:' + productSections[i].trim();

      // Create a product object
      ProductInfo product = ProductInfo(
        name: extractSection(section, 'PRODUCT:'),
        yield: extractSection(section, 'YIELD:'),
        ingredients: extractSection(section, 'INGREDIENTS:'),
        equipment: extractSection(section, 'EQUIPMENT:'),
        steps: extractSection(section, 'STEPS:'),
        time: extractSection(section, 'TIME:'),
        storage: extractSection(section, 'STORAGE:'),
        price: extractSection(section, 'PRICE:'),
        benefits: extractSection(section, 'BENEFITS:'),
        uses: extractSection(section, 'USES:'),
      );

      products.add(product);
    }

    return products;
  }

  String extractSection(String text, String sectionTag) {
    try {
      int startIndex = text.indexOf(sectionTag);
      if (startIndex == -1) return '';

      startIndex += sectionTag.length;

      // Find the next section tag
      List<String> sectionTags = [
        'PRODUCT:', 'YIELD:', 'INGREDIENTS:', 'EQUIPMENT:',
        'STEPS:', 'TIME:', 'STORAGE:', 'PRICE:', 'BENEFITS:', 'USES:'
      ];

      int endIndex = text.length;
      for (String tag in sectionTags) {
        if (tag == sectionTag) continue;
        int tagIndex = text.indexOf(tag, startIndex);
        if (tagIndex != -1 && tagIndex < endIndex) {
          endIndex = tagIndex;
        }
      }

      return text.substring(startIndex, endIndex).trim();
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _milkQtyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Milk Product Advisor"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "What can I make with my milk?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _milkQtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Enter Milk Quantity (Liters)",
                          hintText: "e.g. 10",
                          prefixIcon: Icon(Icons.water_drop, color: Colors.green.shade800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.green.shade800, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : _getMilkProductRecommendations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search),
                            const SizedBox(width: 8),
                            Text(
                              "Get Recommendations",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.green.shade800),
                      const SizedBox(height: 12),
                      Text(
                        "Finding the best recipes for your milk...",
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ],
                  ),
                ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (milkProducts.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "Recommendations for ${_milkQtyController.text} liters of milk:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: milkProducts.length,
                          itemBuilder: (context, index) {
                            final product = milkProducts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.green.shade200, width: 1),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                    fontSize: 17,
                                  ),
                                ),
                                subtitle: Text(
                                  "Yield: ${product.yield}",
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.local_dining,
                                  color: Colors.green.shade700,
                                ),
                                childrenPadding: const EdgeInsets.all(16),
                                children: [
                                  ProductDetailsWidget(product: product),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: milkProducts.isNotEmpty
          ? FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: Colors.green.shade800,
        child: const Icon(Icons.arrow_upward),
      )
          : null,
    );
  }
}

class ProductInfo {
  final String name;
  final String yield;
  final String ingredients;
  final String equipment;
  final String steps;
  final String time;
  final String storage;
  final String price;
  final String benefits;
  final String uses;

  ProductInfo({
    required this.name,
    required this.yield,
    required this.ingredients,
    required this.equipment,
    required this.steps,
    required this.time,
    required this.storage,
    required this.price,
    required this.benefits,
    required this.uses,
  });
}

class ProductDetailsWidget extends StatelessWidget {
  final ProductInfo product;

  const ProductDetailsWidget({
    Key? key,
    required this.product,
  }) : super(key: key);

  Widget _buildSection(String title, String content, IconData icon) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.green.shade800),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            content,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  List<Widget> _formatSteps(String steps) {
    if (steps.isEmpty) return [];

    return steps
        .split('\n')
        .where((step) => step.trim().isNotEmpty)
        .map((step) {
      // Check if this is already numbered
      if (RegExp(r'^\d+\.').hasMatch(step.trim())) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(step.trim()),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('• ${step.trim()}'),
        );
      }
    })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Yield', product.yield, Icons.bar_chart),
        _buildSection('Ingredients', product.ingredients, Icons.shopping_cart),
        _buildSection('Equipment', product.equipment, Icons.kitchen),

        // Special handling for steps
        if (product.steps.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.list_alt, size: 20, color: Colors.green.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'Preparation Steps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _formatSteps(product.steps),
                ),
              ),
            ],
          ),

        _buildSection('Preparation Time', product.time, Icons.access_time),
        _buildSection('Storage', product.storage, Icons.inventory_2),
        _buildSection('Market Value', product.price, Icons.currency_rupee),
        _buildSection('Health Benefits', product.benefits, Icons.favorite),
        _buildSection('Common Uses', product.uses, Icons.restaurant),

        // Save Button
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save Recipe"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Recipe for ${product.name} has been saved'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}