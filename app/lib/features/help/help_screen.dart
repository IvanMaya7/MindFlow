import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aquí irán las líneas de emergencia, el botón SOS y el mapa de profesionales.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
