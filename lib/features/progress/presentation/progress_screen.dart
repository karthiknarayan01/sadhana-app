import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/progress_providers.dart';
import 'heatmap_grid.dart';
import 'milestone_grid.dart';
import 'weekly_chart.dart';
import 'wellbeing_chart.dart';

/// The app's motivation hub — leads with today's streak (the daily-return
/// hook), then a heatmap, a weekly-minutes chart, milestones, and quick
/// links into each practice's benefits copy. This is the explicitly
/// non-negotiable "keep the user motivated" pillar, not a minor tab.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(progressStatsProvider, (previous, next) {
      final stats = next.valueOrNull;
      if (stats != null && stats.newlyUnlockedMilestoneIds.isNotEmpty) {
        _confetti.play();
      }
    });

    final statsAsync = ref.watch(progressStatsProvider);

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Couldn\'t load your progress: $error')),
              data: (stats) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  _StreakHeader(
                        currentStreak: stats.currentStreak,
                        longestStreak: stats.longestStreak,
                      )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 28),
                  Text(
                    'Wellbeing trend',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  WellbeingChart(currentStreak: stats.currentStreak),
                  const SizedBox(height: 8),
                  Text(
                    'An illustrative curve based on general research on '
                    'consistent practice — not a personal measurement. This '
                    'app doesn\'t track mood; it tracks that you showed up.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'This week',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  WeeklyChart(minutes: stats.weeklyMinutes),
                  const SizedBox(height: 28),
                  Text(
                    'Last 12 weeks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  HeatmapGrid(counts: stats.heatmapCounts),
                  const SizedBox(height: 28),
                  Text(
                    'Milestones',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  MilestoneGrid(unlockedIds: stats.unlockedMilestoneIds),
                  const SizedBox(height: 28),
                  Text(
                    'Total: ${stats.totalSessions} session${stats.totalSessions == 1 ? '' : 's'} · '
                    '${stats.totalMinutes} minute${stats.totalMinutes == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            shouldLoop: false,
          ),
        ],
      ),
    );
  }
}

class _StreakHeader extends StatelessWidget {
  const _StreakHeader({
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StreakStat(
            icon: Icons.local_fire_department,
            value: '$currentStreak',
            label: currentStreak == 1 ? 'day streak' : 'days streak',
            glow: currentStreak > 0,
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.onPrimary.withValues(alpha: 0.25),
          ),
          _StreakStat(
            icon: Icons.emoji_events,
            value: '$longestStreak',
            label: 'best streak',
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.icon,
    required this.value,
    required this.label,
    this.glow = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget iconWidget = Icon(icon, color: scheme.onPrimary);
    if (glow) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.15,
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }
    return Column(
      children: [
        iconWidget,
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'Merriweather',
            color: scheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onPrimary),
        ),
      ],
    );
  }
}
