import 'package:flutter/material.dart';

class DairyFarmerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dairy Farmer Home"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text(
          "Welcome, Dairy Farmer!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
