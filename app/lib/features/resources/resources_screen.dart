import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  late Future<List<dynamic>> _resources;

  @override
  void initState() {
    super.initState();
    _resources = ApiClient.instance.get('/resources').then((d) => d as List<dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recursos')),
      body: FutureBuilder<List<dynamic>>(
        future: _resources,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('No se pudo cargar: ${snap.error}'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final r in snap.data!)
                Card(
                  child: ListTile(
                    title: Text(r['title'] as String),
                    subtitle: Text(r['category'] as String),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
