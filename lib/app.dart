import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analytics/analytics_service.dart';
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

const _featureNames = ['meditate', 'breathe', 'progress', 'prayers'];

/// Bottom-nav shell across the app's four sections. Each tab's screen owns
/// its own feature (meditation/breathing/progress/search) — this widget is
/// deliberately just navigation, no feature logic — plus tracking how long
/// each tab stays visible, for AnalyticsService's feature_time event.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with WidgetsBindingObserver {
  int _index = 0;
  final Stopwatch _tabStopwatch = Stopwatch()..start();
  // Cached rather than ref.read() at flush time: dispose() runs after
  // Riverpod considers this element's ref unusable (it asserts against
  // exactly that), but reading a plain Provider's already-constructed value
  // in initState() and reusing it later is fine — it's a singleton for the
  // app's lifetime anyway (see core/providers.dart).
  late final AnalyticsService _analytics;

  static const _screens = [
    MeditationHomeScreen(),
    BreathingHomeScreen(),
    ProgressScreen(),
    SearchScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _analytics = ref.read(analyticsServiceProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushTabTime();
    super.dispose();
  }

  // Backgrounding/closing the app doesn't tear down this State, so without
  // this a user leaving the app open (in another app, or overnight) would
  // silently keep accruing "time in feature" the whole time it's not even
  // visible. Flushing on pause and restarting the stopwatch on resume keeps
  // the recorded time honest — screen-visible time, not wall-clock time.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flushTabTime();
    } else if (state == AppLifecycleState.resumed) {
      _tabStopwatch.start();
    }
  }

  // Stops, sends, and resets to zero in one step — so a second flush before
  // the stopwatch is ever restarted (e.g. `paused` immediately followed by
  // `detached`, or dispose() right after a pause) safely sends nothing the
  // second time instead of re-sending the same elapsed span twice.
  void _flushTabTime() {
    _tabStopwatch.stop();
    final elapsed = _tabStopwatch.elapsed;
    _tabStopwatch.reset();
    _analytics.recordFeatureTime(_featureNames[_index], elapsed);
  }

  void _onDestinationSelected(int newIndex) {
    if (newIndex == _index) return;
    _flushTabTime();
    setState(() => _index = newIndex);
    _tabStopwatch.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
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
