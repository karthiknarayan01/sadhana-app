import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/breathing/presentation/breathing_home_screen.dart';
import 'features/meditation/presentation/meditation_home_screen.dart';
import 'features/progress/presentation/progress_screen.dart';
import 'features/search/presentation/search_screen.dart';

class SadhanaApp extends StatelessWidget {
  const SadhanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sadhana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const RootShell(),
    );
  }
}

/// Bottom-nav shell across the app's four sections. Each tab's screen owns
/// its own feature (meditation/breathing/progress/search) — this widget is
/// deliberately just navigation, no feature logic.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    MeditationHomeScreen(),
    BreathingHomeScreen(),
    ProgressScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.self_improvement),
            label: 'Meditate',
          ),
          NavigationDestination(icon: Icon(Icons.air), label: 'Breathe'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Shlokas'),
        ],
      ),
    );
  }
}
