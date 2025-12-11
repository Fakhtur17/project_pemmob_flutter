import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlacesPage extends StatefulWidget {
  @override
  _PlacesPageState createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  late Future<List<dynamic>> places;

  @override
  void initState() {
    super.initState();
    places = ApiService.getPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daftar Tempat")),
      body: FutureBuilder(
        future: places,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final place = data[index];
              return ListTile(
                title: Text(place['name']),
                subtitle: Text(place['address'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
