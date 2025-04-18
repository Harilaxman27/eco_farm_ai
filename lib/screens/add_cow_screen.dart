import 'package:flutter/material.dart';

class AddCowScreen extends StatelessWidget {
  const AddCowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Cow')),
      body: const Center(child: Text('🐄 Welcome to Add Cow Screen')),
    );
  }
}
