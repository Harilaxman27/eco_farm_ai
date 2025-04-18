import 'package:flutter/material.dart';

class FinancialsTracker extends StatelessWidget {
  const FinancialsTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financials')),
      body: const Center(child: Text('📈 Welcome to Financial Tracker')),
    );
  }
}
