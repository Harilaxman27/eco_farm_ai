import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AlertsReminders extends StatefulWidget {
  @override
  _AlertsRemindersState createState() => _AlertsRemindersState();
}

class _AlertsRemindersState extends State<AlertsReminders> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _reminderTypes = ['Milking', 'Heat Cycle', 'Calving', 'Vaccination', 'Health Check'];
  String _selectedFilter = 'All';

  // Green theme color
  final Color primaryGreen = Colors.green[800]!;
  final Color secondaryGreen = Colors.green[900]!;
  final Color lightGreen = Colors.green[50]!;

  void _addReminderDialog(Map<String, dynamic> cow) {
    String selectedType = _reminderTypes.first;
    DateTime selectedDateTime = DateTime.now();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Reminder for ${cow['name']}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: cow['imageBase64'] != null
                              ? MemoryImage(base64Decode(cow['imageBase64'].split(',').last))
                              : null,
                          child: cow['imageBase64'] == null
                              ? Icon(Icons.pets, size: 30, color: primaryGreen)
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cow['name'] ?? 'Unnamed Cow',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                'Breed: ${cow['breed'] ?? 'Unknown'}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Reminder Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      icon: Icon(Icons.arrow_drop_down_circle, color: primaryGreen),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                      ),
                      items: _reminderTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedType = val!),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Date & Time',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event, color: primaryGreen),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, yyyy HH:mm').format(selectedDateTime),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime.now().subtract(Duration(days: 365)),
                              lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: primaryGreen,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: primaryGreen,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedTime != null) {
                                setDialogState(() {
                                  selectedDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Change',
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Notes (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any additional details here...',
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('remainder').add({
                'cowId': cow['id'],
                'cowName': cow['name'],
                'cowImageBase64': cow['imageBase64'],
                'type': selectedType,
                'date': Timestamp.fromDate(selectedDateTime),
                'note': noteController.text,
                'farmerUid': uid,
                'status': 'upcoming',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder added successfully'),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsets.all(16),
                ),
              );
            },
            child: Text('Save Reminder'),
          ),
        ],
      ),
    );
  }

  void _deleteReminder(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirm Delete'),
          ],
        ),
        content: Text('Are you sure you want to delete this reminder? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              FirebaseFirestore.instance.collection('remainder').doc(id).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder deleted'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsets.all(16),
                ),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: primaryGreen.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              isExpanded: true,
              icon: Icon(Icons.filter_list, color: primaryGreen),
              decoration: InputDecoration(
                labelText: 'Filter by Type',
                labelStyle: TextStyle(color: primaryGreen),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              items: ['All', ..._reminderTypes]
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedFilter = val!),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('remainder')
                .where('farmerUid', isEqualTo: uid)
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                );
              }

              var reminders = snapshot.data!.docs;

              if (_selectedFilter != 'All') {
                reminders = reminders
                    .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == _selectedFilter)
                    .toList();
              }

              if (reminders.isEmpty) {
                return _buildEmptyState(
                    'No reminders available\nAdd reminders from the "Add New" tab',
                    Icons.notifications_off
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(bottom: 24),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final data = reminders[index].data() as Map<String, dynamic>;
                  final reminderId = reminders[index].id;
                  final reminderDate = (data['date'] as Timestamp).toDate();
                  final isOverdue = reminderDate.isBefore(DateTime.now());
                  final daysRemaining = reminderDate.difference(DateTime.now()).inDays;

                  // Group reminders by date
                  bool showDateHeader = false;
                  if (index == 0) {
                    showDateHeader = true;
                  } else {
                    final previousData = reminders[index - 1].data() as Map<String, dynamic>;
                    final previousDate = (previousData['date'] as Timestamp).toDate();
                    showDateHeader = !DateUtils.isSameDay(previousDate, reminderDate);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateHeader)
                        Padding(
                          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? Colors.red.withOpacity(0.1)
                                  : primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isOverdue
                                  ? 'Overdue'
                                  : daysRemaining == 0
                                  ? 'Today'
                                  : daysRemaining == 1
                                  ? 'Tomorrow'
                                  : DateFormat('EEEE, MMM d').format(reminderDate),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOverdue ? Colors.red : primaryGreen,
                              ),
                            ),
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isOverdue
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                          border: isOverdue
                              ? Border.all(color: Colors.red.withOpacity(0.3), width: 1.5)
                              : null,
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: _getReminderColor(data['type']).withOpacity(0.1),
                                child: Icon(
                                  _getReminderIcon(data['type']),
                                  color: _getReminderColor(data['type']),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['cowName'] ?? 'Unnamed Cow',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getReminderColor(data['type']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      data['type'],
                                      style: TextStyle(
                                        color: _getReminderColor(data['type']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        DateFormat('HH:mm').format(reminderDate),
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (data['note'] != null && data['note'].toString().isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.note,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                data['note'],
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isOverdue)
                                    Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.warning,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  InkWell(
                                    onTap: () => _deleteReminder(reminderId),
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (data['cowImageBase64'] != null)
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  image: DecorationImage(
                                    image: MemoryImage(base64Decode(data['cowImageBase64'].split(',').last)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getReminderColor(String type) {
    switch (type) {
      case 'Milking':
        return Colors.blue[700]!;
      case 'Heat Cycle':
        return Colors.purple[700]!;
      case 'Calving':
        return Colors.amber[800]!;
      case 'Vaccination':
        return Colors.green[700]!;
      case 'Health Check':
        return Colors.red[700]!;
      default:
        return primaryGreen;
    }
  }

  IconData _getReminderIcon(String type) {
    switch (type) {
      case 'Milking':
        return Icons.water_drop;
      case 'Heat Cycle':
        return Icons.cyclone;
      case 'Calving':
        return Icons.pets;
      case 'Vaccination':
        return Icons.medical_services;
      case 'Health Check':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildCowList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .collection('cows')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          );
        }

        final cows = snapshot.data!.docs;

        if (cows.isEmpty) {
          return _buildEmptyState(
              'No cows available\nAdd cows to your herd first',
              Icons.pets
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a cow to add a new reminder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 24),
                itemCount: cows.length,
                itemBuilder: (context, index) {
                  final cow = cows[index].data() as Map<String, dynamic>;
                  cow['id'] = cows[index].id;

                  return Container(
                    margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                      border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1),
                    ),
                    child: Column(
                      children: [
                        if (cow['imageBase64'] != null)
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              image: DecorationImage(
                                image: MemoryImage(base64Decode(cow['imageBase64'].split(',').last)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (cow['imageBase64'] == null)
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: primaryGreen.withOpacity(0.1),
                                  child: Icon(
                                    Icons.pets,
                                    size: 30,
                                    color: primaryGreen,
                                  ),
                                ),
                              SizedBox(width: cow['imageBase64'] == null ? 16 : 0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cow['name'] ?? 'Unnamed Cow',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Breed: ${cow['breed'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (cow['age'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Age: ${cow['age']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: Icon(Icons.add_alert),
                                label: Text('Add Reminder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: () => _addReminderDialog(cow),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'Alerts & Reminders',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, secondaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                icon: Icon(Icons.notifications_active),
                text: 'Reminders',
              ),
              Tab(
                icon: Icon(Icons.add_circle_outline),
                text: 'Add New',
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
          ),
          child: TabBarView(
            children: [
              _buildReminderList(),
              _buildCowList(),
            ],
          ),
        ),
      ),
    );
  }
}