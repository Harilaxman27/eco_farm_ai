import 'package:flutter/material.dart';
import 'package:eco_farm_ai/screens/broiler_models.dart';
import 'package:eco_farm_ai/screens/db_helper2.dart';

class HenDetailsPage extends StatefulWidget {
  final Broiler hen;

  HenDetailsPage({required this.hen});

  @override
  _HenDetailsPageState createState() => _HenDetailsPageState();
}

class _HenDetailsPageState extends State<HenDetailsPage> {
  late TextEditingController _weightController;
  late TextEditingController _feedController;
  late TextEditingController _healthController;
  late TextEditingController _medicationController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.hen.currentWeight.toString());
    _feedController = TextEditingController(text: widget.hen.feedConsumed.toString());
    _healthController = TextEditingController(text: widget.hen.healthStatus);
    _medicationController = TextEditingController(text: widget.hen.medication);
  }

  void _updateHen() async {
    final updatedHen = Broiler(
      id: widget.hen.id,
      name: widget.hen.name,
      numberOfHens: widget.hen.numberOfHens,
      breed: widget.hen.breed,
      initialWeight: widget.hen.initialWeight,
      currentWeight: double.parse(_weightController.text),
      feedConsumed: double.parse(_feedController.text),
      healthStatus: _healthController.text,
      medication: _medicationController.text,
      status: widget.hen.status,
      date: widget.hen.date,
    );

    await DBHelper2().updateBroiler(updatedHen);
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hen information updated')));
  }

  void _markAsDead() async {
    widget.hen.status = 'dead';
    await DBHelper2().updateBroiler(widget.hen);
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hen marked as dead')));
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hen Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Current Weight (kg)'),
            ),
            TextFormField(
              controller: _feedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Feed Consumed (kg)'),
            ),
            TextFormField(
              controller: _healthController,
              decoration: InputDecoration(labelText: 'Health Status'),
            ),
            TextFormField(
              controller: _medicationController,
              decoration: InputDecoration(labelText: 'Medication'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _updateHen,
                  child: Text('Update'),
                ),
                ElevatedButton(
                  onPressed: _cancel,
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _markAsDead,
                  child: Text('Mark as Dead'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
