import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cow_health_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class HealthBreedingManagement extends StatefulWidget {
  @override
  _HealthBreedingManagementState createState() => _HealthBreedingManagementState();
}

class _HealthBreedingManagementState extends State<HealthBreedingManagement> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method to filter cows based on search query
  bool _filterCow(Map<String, dynamic> cow) {
    if (_searchQuery.isEmpty) return true;

    final name = (cow['name'] ?? '').toString().toLowerCase();
    final tag = (cow['tagNumber'] ?? '').toString().toLowerCase();
    final breed = (cow['breed'] ?? '').toString().toLowerCase();

    return name.contains(_searchQuery.toLowerCase()) ||
        tag.contains(_searchQuery.toLowerCase()) ||
        breed.contains(_searchQuery.toLowerCase());
  }

  // Method to get pregnancy status count
  Future<Map<String, int>> _getPregnancyStatusCount() async {
    try {
      final result = {'pregnant': 0, 'notPregnant': 0};

      final healthRecords = await FirebaseFirestore.instance
          .collection('healthBreeding')
          .where('farmerUid', isEqualTo: uid)
          .get();

      // Get unique cow IDs with most recent records
      final Map<String, bool> cowPregnancyStatus = {};

      for (var doc in healthRecords.docs) {
        final data = doc.data();
        final cowId = data['cowId'];
        final timestamp = data['timestamp'] as Timestamp;

        // If cow isn't in map or this record is newer
        if (!cowPregnancyStatus.containsKey(cowId) ||
            (cowPregnancyStatus.containsKey(cowId) && timestamp.compareTo(Timestamp.now()) > 0)) {
          cowPregnancyStatus[cowId] = data['pregnancyStatus'] ?? false;
        }
      }

      // Count pregnancies
      cowPregnancyStatus.forEach((key, value) {
        if (value) {
          result['pregnant'] = (result['pregnant'] ?? 0) + 1;
        } else {
          result['notPregnant'] = (result['notPregnant'] ?? 0) + 1;
        }
      });

      return result;
    } catch (e) {
      print('Error getting pregnancy counts: $e');
      return {'pregnant': 0, 'notPregnant': 0};
    }
  }

  Widget _buildSummaryCard() {
    return FutureBuilder<Map<String, int>>(
      future: _getPregnancyStatusCount(),
      builder: (context, snapshot) {
        final pregnantCount = snapshot.data?['pregnant'] ?? 0;
        final notPregnantCount = snapshot.data?['notPregnant'] ?? 0;

        return Card(
          margin: EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Herd Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.pregnant_woman, color: Colors.green, size: 28),
                            SizedBox(height: 8),
                            Text(
                              pregnantCount.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.green[700],
                              ),
                            ),
                            Text('Pregnant'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.pets, color: Colors.grey[700], size: 28),
                            SizedBox(height: 8),
                            Text(
                              notPregnantCount.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text('Not Pregnant'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search cows by name, tag, or breed...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCowList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .collection('cows')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No cows found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  'Add cows to start tracking health records',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Filter cows based on search query
        final cows = snapshot.data!.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .where(_filterCow)
            .toList();

        if (cows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No matches found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: cows.length,
          itemBuilder: (context, index) {
            final cow = cows[index];
            final bool hasImage = cow['imageBase64'] != null &&
                cow['imageBase64'].toString().isNotEmpty;

            // Check pregnancy status from health records (in a real app, you might want to fetch this separately)
            bool isPregnant = false;  // Default status is not pregnant

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CowHealthDetails(
                        cowId: cow['id'],
                        cowName: cow['name'] ?? 'Unnamed Cow',
                        cowPic: cow['imageBase64'] ?? '',
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Cow image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasImage
                            ? Image.memory(
                          base64Decode(cow['imageBase64'].split(',').last),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                            );
                          },
                        )
                            : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child: Icon(Icons.pets, color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Cow details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cow['name'] ?? 'Unnamed Cow',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (cow['tagNumber'] != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Tag: ${cow['tagNumber']}',
                                      style: TextStyle(color: Colors.blue[800], fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Breed: ${cow['breed'] ?? 'Unknown'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            // Add last health record info or breeding status
                            FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('healthBreeding')
                                  .where('cowId', isEqualTo: cow['id'])
                                  .orderBy('timestamp', descending: true)
                                  .limit(1)
                                  .get(),
                              builder: (context, healthSnapshot) {
                                if (healthSnapshot.connectionState == ConnectionState.waiting) {
                                  return Text('Loading status...',
                                      style: TextStyle(color: Colors.grey));
                                }

                                if (healthSnapshot.hasData && healthSnapshot.data!.docs.isNotEmpty) {
                                  final healthData = healthSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                                  final isPregnant = healthData['pregnancyStatus'] ?? false;
                                  final timestamp = healthData['timestamp'] as Timestamp?;
                                  final lastUpdated = timestamp != null
                                      ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                                      : 'Unknown';

                                  return Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPregnant ? Colors.green[100] : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isPregnant ? 'Pregnant' : 'Not Pregnant',
                                          style: TextStyle(
                                            color: isPregnant ? Colors.green[800] : Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Updated: $lastUpdated',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Text('No health records',
                                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health & Breeding Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildSearchBar(),
          SizedBox(height: 8),
          Expanded(
            child: _buildCowList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add cow page or show message to add cow first
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please add a cow from the main inventory first'))
          );
        },
        backgroundColor: Colors.teal,
        child: Icon(Icons.add),
        tooltip: 'Add New Cow',
      ),
    );
  }
}