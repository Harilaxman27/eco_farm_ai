import 'package:flutter/material.dart';
import 'package:eco_farm_ai/screens/broiler_models.dart';
import 'package:eco_farm_ai/screens/db_helper2.dart';
import 'hen_details_page.dart';

class MyHensPage extends StatefulWidget {
  @override
  _MyHensPageState createState() => _MyHensPageState();
}

class _MyHensPageState extends State<MyHensPage> {
  late Future<List<Broiler>> _hensFuture;

  @override
  void initState() {
    super.initState();
    _loadHens();
  }

  void _loadHens() {
    _hensFuture = DBHelper2().getBroilers(status: 'alive');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Broiler>>(
      future: _hensFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No hens found'));

        final hens = snapshot.data!;
        return ListView.builder(
          itemCount: hens.length,
          itemBuilder: (context, index) {
            final hen = hens[index];
            return Card(
              child: ListTile(
                title: Text(hen.name),
                subtitle: Text('Breed: ${hen.breed}, Count: ${hen.numberOfHens}'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HenDetailsPage(hen: hen),
                    ),
                  );
                  if (result == true) _loadHens();
                  setState(() {});
                },
              ),
            );
          },
        );
      },
    );
  }
}
