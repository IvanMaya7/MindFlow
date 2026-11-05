import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Future<List<dynamic>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = ApiClient.instance.get('/journal').then((d) => d as List<dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diario')),
      body: FutureBuilder<List<dynamic>>(
        future: _entries,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('No se pudo cargar: ${snap.error}'));
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Aún no hay entradas.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final e = items[i] as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(e['primaryEmotion'] as String),
                  subtitle: Text((e['textNotes'] ?? '') as String,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text((e['date'] as String).substring(0, 10)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
