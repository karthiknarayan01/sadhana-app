import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/breathing/presentation/breathing_home_screen.dart';
import 'features/meditation/presentation/meditation_home_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
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
      home: const _AppRoot(),
    );
  }
}

/// Gates the very first screen a fresh install ever sees — the onboarding
/// message (see OnboardingScreen) — behind AppPrefs.hasSeenOnboarding, then
/// always goes straight to RootShell after that. `_dismissed` is local
/// state rather than re-reading prefsProvider after "Begin" is tapped, so
/// the transition is instant instead of waiting on another SharedPreferences
/// round trip.
class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(prefsProvider);

    return prefsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const RootShell(),
      data: (prefs) {
        if (_dismissed || prefs.hasSeenOnboarding) {
          return const RootShell();
        }
        return OnboardingScreen(
          onFinished: () {
            prefs.setHasSeenOnboarding(true);
            setState(() => _dismissed = true);
          },
        );
      },
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
          NavigationDestination(icon: Icon(Icons.search), label: 'Prayers'),
        ],
      ),
    );
  }
}
