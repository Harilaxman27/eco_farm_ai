import 'package:flutter/material.dart';

class PoultryFarmerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Poultry Farmer Home"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text(
          "Welcome, Poultry Farmer!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
