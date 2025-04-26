import 'package:flutter/material.dart';
import 'remainder_page.dart';
import 'reminder_db.dart';
import 'package:intl/intl.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Reminder> reminders = [];
  bool isAddingReminder = false;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final data = await ReminderDB.instance.getAllReminders();
    setState(() {
      reminders = data;
    });
  }

  void _toggleAddReminderForm() {
    setState(() {
      isAddingReminder = !isAddingReminder;
      if (!isAddingReminder) {
        titleController.clear();
        descriptionController.clear();
        selectedTime = TimeOfDay.now();
      }
    });
  }

  Future<void> _addReminder() async {
    if (titleController.text.isNotEmpty) {
      final newReminder = Reminder(
        title: titleController.text,
        description: descriptionController.text,
        time: selectedTime,
      );
      await ReminderDB.instance.insertReminder(newReminder);
      titleController.clear();
      descriptionController.clear();
      selectedTime = TimeOfDay.now();
      _loadReminders();
      _toggleAddReminderForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Reminder added successfully"),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a title for the reminder"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markReminderDone(int index) async {
    final reminder = reminders[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark as Complete"),
        content: Text("Has '${reminder.title}' been completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            onPressed: () async {
              if (reminder.id != null) {
                await ReminderDB.instance.deleteReminder(reminder.id!);
                _loadReminders();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Farm task completed!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Complete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farm Tasks & Reminders"),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Keep track of all your farm tasks",
                  style: TextStyle(
                    color: Colors.green.shade50,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add reminder form with scroll to fix overflow
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isAddingReminder ? null : 0,
            child: isAddingReminder
                ? SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "New Farm Task",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Details (optional)',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 10),
                            Text(
                              "Time: ${selectedTime.format(context)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _toggleAddReminderForm,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addReminder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Add Task', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: reminders.isEmpty && !isAddingReminder
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No farm tasks yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add a new task to get started",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_note,
                        color: Colors.green.shade700,
                      ),
                    ),
                    title: Text(
                      reminder.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reminder.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(reminder.description),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reminder.time.format(context),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      onPressed: () => _markReminderDone(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAddReminderForm,
        backgroundColor: Colors.green.shade700,
        child: Icon(isAddingReminder ? Icons.close : Icons.add),
      ),
    );
  }
}
