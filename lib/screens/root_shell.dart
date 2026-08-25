import 'package:flutter/material.dart';

import 'placeholder_screen.dart';
import 'today/today_screen.dart';

/// Hauptgerüst der App mit den 4 Tabs unten: Heute, Assistent, Dokumente, Kontakte.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    TodayScreen(),
    PlaceholderScreen(title: 'Assistent', icon: Icons.smart_toy_outlined),
    PlaceholderScreen(title: 'Dokumente', icon: Icons.description_outlined),
    PlaceholderScreen(title: 'Kontakte', icon: Icons.people_outline),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.today_outlined),
      activeIcon: Icon(Icons.today),
      label: 'Heute',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.smart_toy_outlined),
      activeIcon: Icon(Icons.smart_toy),
      label: 'Assistent',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      activeIcon: Icon(Icons.description),
      label: 'Dokumente',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Kontakte',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
      ),
    );
  }
}
