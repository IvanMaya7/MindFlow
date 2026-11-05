import 'package:flutter/material.dart';

import '../help/help_screen.dart';
import '../journal/journal_screen.dart';
import '../progress/progress_screen.dart';
import '../resources/resources_screen.dart';
import 'home_screen.dart';

/// Contenedor con la Bottom Navigation Bar de 5 tabs (según el documento).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 2; // Home al centro

  static const _screens = <Widget>[
    JournalScreen(),
    ProgressScreen(),
    HomeScreen(),
    ResourcesScreen(),
    HelpScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Diario'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Progreso'),
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.spa_outlined), label: 'Recursos'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Ayuda'),
        ],
      ),
    );
  }
}
