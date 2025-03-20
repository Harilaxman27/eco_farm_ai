import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FarmerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Farmer Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Farmer Menu',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: Icon(Icons.eco),
              title: Text("Crop Recommendation"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.sick),
              title: Text("Disease Detection"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text("Marketplace"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text("Multi-Language Support"),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeatherCard(),
            SizedBox(height: 10),
            _buildQuickCropSuggestion(),
            SizedBox(height: 10),
            _buildFarmerStats(),
            SizedBox(height: 10),
            _buildAnnouncements(),
            SizedBox(height: 10),
            _buildTodaysTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.wb_sunny, color: Colors.orange),
        title: Text("Today's Weather"),
        subtitle: Text("🌤️ 28°C, Sunny"),
      ),
    );
  }

  Widget _buildQuickCropSuggestion() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.agriculture, color: Colors.green),
        title: Text("Quick Crop Suggestion"),
        subtitle: Text("🌱 Best crop to plant now: Wheat"),
      ),
    );
  }

  Widget _buildFarmerStats() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.bar_chart, color: Colors.blue),
        title: Text("Farmer Statistics"),
        subtitle: Text("🌾 Crops Sold: 120  | 📦 Pending Orders: 5"),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.campaign, color: Colors.red),
        title: Text("Announcements"),
        subtitle: Text("📢 New government scheme available for farmers."),
      ),
    );
  }

  Widget _buildTodaysTasks() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text("Today's Tasks"),
          ),
          CheckboxListTile(
            title: Text("Water the crops"),
            value: false,
            onChanged: (bool? value) {},
          ),
          CheckboxListTile(
            title: Text("Check soil condition"),
            value: true,
            onChanged: (bool? value) {},
          ),
          CheckboxListTile(
            title: Text("Sell crops in marketplace"),
            value: false,
            onChanged: (bool? value) {},
          ),
        ],
      ),
    );
  }
}
