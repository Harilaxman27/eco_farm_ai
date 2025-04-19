import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class CowMilkingTracker extends StatefulWidget {
  @override
  _CowMilkingTrackerState createState() => _CowMilkingTrackerState();
}

class _CowMilkingTrackerState extends State<CowMilkingTracker> {
  List<Map<String, dynamic>> cows = [];
  String selectedCowId = '';
  String selectedCowName = '';
  String selectedCowImage = '';
  TextEditingController amYieldController = TextEditingController();
  TextEditingController pmYieldController = TextEditingController();
  String status = 'Lactating';
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  // Daily summary stats
  double totalDailyYield = 0.0;
  int cowsRecorded = 0;

  @override
  void initState() {
    super.initState();
    fetchCows();
    fetchDailySummary();
  }

  @override
  void dispose() {
    amYieldController.dispose();
    pmYieldController.dispose();
    super.dispose();
  }

  // Format date as yyyy-MM-dd
  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Format date for display
  String formatDateForDisplay(DateTime date) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> fetchCows() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cowsSnapshot = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(user.uid)
            .collection('cows')
            .get();

        setState(() {
          cows = cowsSnapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc['name'],
              'imageBase64': doc['imageBase64'],
            };
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cows: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchDailySummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final todayDate = formatDate(DateTime.now());

      final records = await FirebaseFirestore.instance
          .collection('milk_tracker')
          .where('farmerId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayDate)
          .get();

      double total = 0.0;
      Set<String> uniqueCows = {};

      for (var doc in records.docs) {
        double am = double.tryParse(doc['amYield'] ?? '0') ?? 0;
        double pm = double.tryParse(doc['pmYield'] ?? '0') ?? 0;
        total += (am + pm);
        uniqueCows.add(doc['cowId']);
      }

      setState(() {
        totalDailyYield = total;
        cowsRecorded = uniqueCows.length;
      });
    }
  }

  Future<void> saveMilkingData() async {
    // Validate input
    if (selectedCowId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a cow')),
      );
      return;
    }

    if (amYieldController.text.isEmpty && pmYieldController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter at least one yield value')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final todayDate = formatDate(selectedDate);

        await FirebaseFirestore.instance.collection('milk_tracker').add({
          'farmerId': user.uid,
          'cowId': selectedCowId,
          'cowName': selectedCowName,
          'cowImageBase64': selectedCowImage,
          'date': todayDate,
          'amYield': amYieldController.text,
          'pmYield': pmYieldController.text,
          'status': status,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Milking record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear fields after saving
        setState(() {
          amYieldController.clear();
          pmYieldController.clear();
        });

        // Refresh the daily summary
        fetchDailySummary();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildCowImage(String base64String) {
    try {
      // Proper Base64 decoding
      Uint8List imageBytes = base64Decode(base64String);
      return CircleAvatar(
        backgroundImage: MemoryImage(imageBytes),
        radius: 20,
        onBackgroundImageError: (e, stackTrace) {
          print('Error loading image: $e');
        },
      );
    } catch (e) {
      print('Error decoding image: $e');
      return CircleAvatar(
        child: Icon(Icons.broken_image),
        radius: 20,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cow Milking Tracker'),
        backgroundColor: Colors.green[700],
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              fetchCows();
              fetchDailySummary();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(
                            icon: Icons.water_drop,
                            label: 'Total Yield',
                            value: '${totalDailyYield.toStringAsFixed(1)} L',
                            color: Colors.blue,
                          ),
                          _buildSummaryItem(
                            icon: Icons.pets,
                            label: 'Cows Recorded',
                            value: '$cowsRecorded',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Date Selector
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Record Date:', style: TextStyle(fontSize: 16)),
                      TextButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text(formatDateForDisplay(selectedDate)),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Cow Selection
              Text(
                  'Select Cow:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 8),
              cows.isEmpty
                  ? _buildEmptyCowsMessage()
                  : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCowId.isEmpty ? null : selectedCowId,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Choose Cow'),
                    ),
                    isExpanded: true,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    items: cows.map((cow) {
                      return DropdownMenuItem<String>(
                        value: cow['id'],
                        child: Row(
                          children: [
                            _buildCowImage(cow['imageBase64']),
                            SizedBox(width: 12),
                            Text(
                              cow['name'],
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final selected = cows.firstWhere((cow) => cow['id'] == val);
                        setState(() {
                          selectedCowId = selected['id'];
                          selectedCowName = selected['name'];
                          selectedCowImage = selected['imageBase64'];
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Yields Input
              if (selectedCowId.isNotEmpty)
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedCowName.isNotEmpty)
                          Row(
                            children: [
                              _buildCowImage(selectedCowImage),
                              SizedBox(width: 12),
                              Text(
                                selectedCowName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 16),

                        _buildYieldInput(
                          label: 'Morning Yield (liters)',
                          icon: Icons.wb_sunny,
                          controller: amYieldController,
                        ),
                        SizedBox(height: 12),
                        _buildYieldInput(
                          label: 'Evening Yield (liters)',
                          icon: Icons.nights_stay,
                          controller: pmYieldController,
                        ),
                        SizedBox(height: 16),

                        // Status selector
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 12),
                            Text(
                              'Status:',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 16),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: status,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Lactating',
                                      child: Row(
                                        children: [
                                          Icon(Icons.water_drop, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Lactating'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Dry',
                                      child: Row(
                                        children: [
                                          Icon(Icons.not_interested, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Dry'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => status = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 24),

              // Save Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: selectedCowId.isEmpty ? null : saveMilkingData,
                  icon: Icon(Icons.save),
                  label: Text('SAVE RECORD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCowsMessage() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
            SizedBox(height: 12),
            Text(
              'No cows found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Add cows to your herd to track milk production'),
            SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(Icons.add),
              label: Text('ADD COWS'),
              onPressed: () {
                // Navigate to add cows page
                // This would be implemented based on your app navigation
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYieldInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixText: 'L',
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}