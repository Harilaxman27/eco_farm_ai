import 'package:flutter/material.dart';
import 'package:eco_farm_ai/screens/broiler_models.dart';
import 'package:eco_farm_ai/screens/db_helper2.dart';

class DiedHensPage extends StatefulWidget {
  @override
  _DiedHensPageState createState() => _DiedHensPageState();
}

class _DiedHensPageState extends State<DiedHensPage> {
  late Future<List<Broiler>> _diedHensFuture;

  @override
  void initState() {
    super.initState();
    _loadDiedHens();
  }

  void _loadDiedHens() {
    _diedHensFuture = DBHelper2().getBroilers(status: 'dead');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Broiler>>(
      future: _diedHensFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return Center(child: Text('No died hens found'));

        final diedHens = snapshot.data!;
        return ListView.builder(
          itemCount: diedHens.length,
          itemBuilder: (context, index) {
            final hen = diedHens[index];
            return Card(
              child: ListTile(
                title: Text(hen.name),
                subtitle: Text('Breed: ${hen.breed}, Count: ${hen.numberOfHens}'),
                trailing: Icon(Icons.info),
                onTap: () {
                  // Optionally, navigate to a detailed view for the dead hen.
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(hen.name),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Breed: ${hen.breed}'),
                          Text('Number of Hens: ${hen.numberOfHens}'),
                          Text('Final Weight: ${hen.currentWeight} kg'),
                          Text('Health Status: ${hen.healthStatus}'),
                          Text('Medication: ${hen.medication}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
