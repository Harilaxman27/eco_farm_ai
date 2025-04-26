import 'package:flutter/material.dart';
import 'package:eco_farm_ai/poultry/add_hen_page.dart';
import 'package:eco_farm_ai/poultry/my_hens_page.dart';
import 'package:eco_farm_ai/poultry/died_hens_page.dart';
import 'package:eco_farm_ai/poultry/statistics_page.dart';

class BroilerTrackingPage extends StatefulWidget {
  @override
  _BroilerTrackingPageState createState() => _BroilerTrackingPageState();
}

class _BroilerTrackingPageState extends State<BroilerTrackingPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AddHenPage(),
    MyHensPage(),
    DiedHensPage(),
    StatsPage(),
  ];

  final List<String> _titles = [
    'Add Hen',
    'My Hens',
    'Died Hens',
    'Stats',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Hen'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Hens'),
          BottomNavigationBarItem(icon: Icon(Icons.cancel), label: 'Died Hens'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}
