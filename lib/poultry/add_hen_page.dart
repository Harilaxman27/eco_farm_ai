import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eco_farm_ai/screens/broiler_models.dart';
import 'package:eco_farm_ai/screens/db_helper2.dart';

class AddHenPage extends StatefulWidget {
  @override
  _AddHenPageState createState() => _AddHenPageState();
}

class _AddHenPageState extends State<AddHenPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedBreed = 'White Leghorn';
  final List<String> _breeds = ['White Leghorn', 'Rhode Island Red', 'Cobb 500', 'Ross 308'];

  void _saveHen() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Dismiss keyboard

      final broiler = Broiler(
        name: _nameController.text.trim(),
        numberOfHens: int.parse(_numberController.text),
        breed: _selectedBreed,
        initialWeight: double.parse(_weightController.text),
        currentWeight: double.parse(_weightController.text),
        feedConsumed: 0,
        healthStatus: 'Healthy',
        medication: '',
        status: 'alive',
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      await DBHelper2().insertBroiler(broiler);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hen added successfully')),
      );

      _formKey.currentState?.reset();
      setState(() {
        _selectedBreed = 'White Leghorn';
      });

      _nameController.clear();
      _numberController.clear();
      _weightController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Hen Name'),
              validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            TextFormField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Number of Hens'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter quantity';
                final n = int.tryParse(value);
                if (n == null || n <= 0) return 'Enter a valid number';
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedBreed,
              decoration: InputDecoration(labelText: 'Breed'),
              items: _breeds.map((breed) {
                return DropdownMenuItem(value: breed, child: Text(breed));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBreed = value!;
                });
              },
            ),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Initial Weight (kg)'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter weight';
                final w = double.tryParse(value);
                if (w == null || w <= 0) return 'Enter a valid weight';
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveHen,
              child: Text('Save Hen'),
            ),
          ],
        ),
      ),
    );
  }
}
