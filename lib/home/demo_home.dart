import 'package:flutter/material.dart';

import '../3d_model/scroll_3d_model_screen.dart';
import 'home_page.dart';
import 'home_page2.dart';

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _index = 0;

  static const _pages = [
    HomePage(title: 'home1'),
    HomePage2(title: 'home2'),
    Scroll3DModelPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: 'flutter_3d_controller',
          ),
          NavigationDestination(
            icon: Icon(Icons.threed_rotation_outlined),
            selectedIcon: Icon(Icons.threed_rotation),
            label: 'o3d',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: '3D Model',
          ),
        ],
      ),
    );
  }
}
