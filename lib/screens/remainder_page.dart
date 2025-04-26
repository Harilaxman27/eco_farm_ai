import 'package:flutter/material.dart';

class Reminder {
  final int? id; // optional for db
  final String title;
  final String description;
  final TimeOfDay time;

  Reminder({
    this.id,
    required this.title,
    required this.description,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
    );
  }
}
