import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Hola 👋', style: text.headlineMedium),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Aquí aparecerá tu insight diario.'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: abrir pantalla de registro diario (CU01)
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar mi día de hoy'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
