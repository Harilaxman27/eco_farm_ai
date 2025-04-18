import 'package:flutter/material.dart';

class CowMilkingTracker extends StatelessWidget {
  const CowMilkingTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Milking Tracker')),
      body: const Center(child: Text('🥛 Welcome to Cow Milking Tracker')),
    );
  }
}
