import 'package:flutter/material.dart';

class AlertsReminders extends StatelessWidget {
  const AlertsReminders({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: const Center(child: Text('⏰ Welcome to Alerts & Reminders')),
    );
  }
}
