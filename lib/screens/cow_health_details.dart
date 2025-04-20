import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';  // Add this package for date formatting

class CowHealthDetails extends StatefulWidget {
  final String cowId, cowName, cowPic;

  CowHealthDetails({required this.cowId, required this.cowName, required this.cowPic});

  @override
  _CowHealthDetailsState createState() => _CowHealthDetailsState();
}

class _CowHealthDetailsState extends State<CowHealthDetails> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  DateTime? _lastCalvingDate;
  List<DateTime> _aiDates = [];
  bool _pregnancyStatus = false;
  List<Map<String, dynamic>> _vaccinations = [];
  List<Map<String, dynamic>> _healthCheckups = [];
  TextEditingController _noteController = TextEditingController();

  // Controllers for new vaccination
  TextEditingController _vaccinationNameController = TextEditingController();
  DateTime? _vaccinationDate;

  // Controllers for new checkup
  TextEditingController _checkupDetailsController = TextEditingController();
  DateTime? _checkupDate;

  // Controller for new AI date
  DateTime? _newAiDate;

  final String uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadExistingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _vaccinationNameController.dispose();
    _checkupDetailsController.dispose();
    super.dispose();
  }

  void _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final records = await FirebaseFirestore.instance
          .collection('healthBreeding')
          .where('cowId', isEqualTo: widget.cowId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (records.docs.isNotEmpty) {
        final data = records.docs.first.data();
        setState(() {
          _lastCalvingDate = data['lastCalvingDate'] != null
              ? (data['lastCalvingDate'] as Timestamp).toDate()
              : null;
          _pregnancyStatus = data['pregnancyStatus'] ?? false;

          // Handle aiDates
          if (data['aiDates'] != null) {
            _aiDates = (data['aiDates'] as List).map((date) =>
                (date as Timestamp).toDate()).toList();
          }

          // Handle vaccinations
          if (data['vaccinations'] != null) {
            _vaccinations = List<Map<String, dynamic>>.from(data['vaccinations']);
          }

          // Handle health checkups
          if (data['healthCheckups'] != null) {
            _healthCheckups = List<Map<String, dynamic>>.from(data['healthCheckups']);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addHealthRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('healthBreeding').add({
        'cowId': widget.cowId,
        'cowName': widget.cowName,
        'farmerUid': uid,
        'lastCalvingDate': _lastCalvingDate,
        'aiDates': _aiDates,
        'pregnancyStatus': _pregnancyStatus,
        'vaccinations': _vaccinations,
        'healthCheckups': _healthCheckups,
        'notes': _noteController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record saved successfully!'), backgroundColor: Colors.green)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e'), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addVaccination() {
    if (_vaccinationNameController.text.isEmpty || _vaccinationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter vaccination name and date'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() {
      _vaccinations.add({
        'name': _vaccinationNameController.text,
        'date': _vaccinationDate,
      });
      _vaccinationNameController.clear();
      _vaccinationDate = null;
    });
  }

  void _addHealthCheckup() {
    if (_checkupDetailsController.text.isEmpty || _checkupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter checkup details and date'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() {
      _healthCheckups.add({
        'details': _checkupDetailsController.text,
        'date': _checkupDate,
      });
      _checkupDetailsController.clear();
      _checkupDate = null;
    });
  }

  void _addAIDate() {
    if (_newAiDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() {
      _aiDates.add(_newAiDate!);
      _aiDates.sort((a, b) => b.compareTo(a)); // Sort in descending order
      _newAiDate = null;
    });
  }

  Widget _buildCowHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (widget.cowPic.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: widget.cowPic.startsWith('http')
                    ? Image.network(
                  widget.cowPic,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey[600]),
                    );
                  },
                )
                    : Image.memory(
                  base64Decode(widget.cowPic.split(',').last),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey[600]),
                    );
                  },
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pets, size: 40, color: Colors.grey[600]),
              ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cowName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pregnancyStatus ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _pregnancyStatus ? 'Pregnant' : 'Not Pregnant',
                      style: TextStyle(
                        color: _pregnancyStatus ? Colors.green[800] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last Calving Date',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _lastCalvingDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _lastCalvingDate = picked);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_lastCalvingDate == null
                                ? 'Select Date'
                                : DateFormat('MMM dd, yyyy').format(_lastCalvingDate!)),
                            Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pregnancy Status',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Switch(
                          value: _pregnancyStatus,
                          onChanged: (val) => setState(() => _pregnancyStatus = val),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    Text(_pregnancyStatus ? 'Pregnant' : 'Not Pregnant',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI (Artificial Insemination) Dates',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    // Display existing AI dates
                    if (_aiDates.isNotEmpty)
                      Column(
                        children: _aiDates.map((date) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMM dd, yyyy').format(date)),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _aiDates.remove(date);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No AI dates recorded",
                            style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                      ),
                    SizedBox(height: 8),
                    // Add new AI date
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _newAiDate = picked);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_newAiDate == null
                                      ? 'Select Date'
                                      : DateFormat('MMM dd, yyyy').format(_newAiDate!)),
                                  Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addAIDate,
                          icon: Icon(Icons.add),
                          label: Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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

  Widget _buildVaccinationsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vaccination History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 12),

                    // List existing vaccinations
                    if (_vaccinations.isNotEmpty)
                      Column(
                        children: _vaccinations.map((vaccination) {
                          final vaccDate = vaccination['date'] is Timestamp
                              ? (vaccination['date'] as Timestamp).toDate()
                              : vaccination['date'] as DateTime;

                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.medical_services, color: Colors.blue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vaccination['name'],
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(vaccDate),
                                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _vaccinations.remove(vaccination);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No vaccinations recorded",
                            style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                      ),

                    SizedBox(height: 16),
                    Text('Add New Vaccination',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _vaccinationNameController,
                      decoration: InputDecoration(
                        labelText: 'Vaccination Name',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _vaccinationDate = picked);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _vaccinationDate == null
                                  ? 'Select Vaccination Date'
                                  : DateFormat('MMM dd, yyyy').format(_vaccinationDate!),
                            ),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addVaccination,
                        icon: Icon(Icons.add),
                        label: Text('Add Vaccination'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
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

  Widget _buildHealthCheckupsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Checkup History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 12),

                    // List existing checkups
                    if (_healthCheckups.isNotEmpty)
                      Column(
                        children: _healthCheckups.map((checkup) {
                          final checkupDate = checkup['date'] is Timestamp
                              ? (checkup['date'] as Timestamp).toDate()
                              : checkup['date'] as DateTime;

                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_hospital, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(checkupDate),
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _healthCheckups.remove(checkup);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(checkup['details']),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("No health checkups recorded",
                            style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                      ),

                    SizedBox(height: 16),
                    Text('Add New Health Checkup',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _checkupDate = picked);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _checkupDate == null
                                  ? 'Select Checkup Date'
                                  : DateFormat('MMM dd, yyyy').format(_checkupDate!),
                            ),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _checkupDetailsController,
                      decoration: InputDecoration(
                        labelText: 'Checkup Details',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addHealthCheckup,
                        icon: Icon(Icons.add),
                        label: Text('Add Health Checkup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
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

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes & Observations',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add notes about this cow\'s health or behavior...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 6,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cowName} Health Records'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Column(
          children: [
            // Header with cow info
            _buildCowHeader(),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              tabs: [
                Tab(icon: Icon(Icons.pregnant_woman), text: 'Breeding'),
                Tab(icon: Icon(Icons.medical_services), text: 'Vaccines'),
                Tab(icon: Icon(Icons.healing), text: 'Checkups'),
                Tab(icon: Icon(Icons.note), text: 'Notes'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBreedingTab(),
                  _buildVaccinationsTab(),
                  _buildHealthCheckupsTab(),
                  _buildNotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: _addHealthRecord,
            child: _isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text('Save All Records'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}