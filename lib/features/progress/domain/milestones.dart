import 'package:flutter/material.dart';

class MilestoneStats {
  const MilestoneStats({
    required this.totalSessions,
    required this.currentStreak,
    required this.totalMinutes,
  });

  final int totalSessions;
  final int currentStreak;
  final int totalMinutes;
}

class MilestoneDefinition {
  const MilestoneDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isMet,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(MilestoneStats stats) isMet;
}

/// Static, evaluated fresh against current stats every time the progress
/// screen rebuilds — cheap enough (a handful of comparisons) that there's
/// no need to cache. Which of these have actually been *unlocked* (and
/// when) is tracked separately in the database (UnlockedMilestones) so an
/// unlock only ever celebrates once, even though isMet() would keep
/// returning true forever after.
final milestoneDefinitions = <MilestoneDefinition>[
  MilestoneDefinition(
    id: 'first_session',
    title: 'First Step',
    description: 'You completed your first practice.',
    icon: Icons.emoji_events,
    isMet: (s) => s.totalSessions >= 1,
  ),
  MilestoneDefinition(
    id: 'streak_3',
    title: 'Building Momentum',
    description: '3 days in a row.',
    icon: Icons.local_fire_department,
    isMet: (s) => s.currentStreak >= 3,
  ),
  MilestoneDefinition(
    id: 'streak_7',
    title: 'One Week Strong',
    description: '7 days in a row.',
    icon: Icons.local_fire_department,
    isMet: (s) => s.currentStreak >= 7,
  ),
  MilestoneDefinition(
    id: 'streak_30',
    title: 'A Month of Practice',
    description: '30 days in a row.',
    icon: Icons.local_fire_department,
    isMet: (s) => s.currentStreak >= 30,
  ),
  MilestoneDefinition(
    id: 'sessions_10',
    title: 'Ten Sessions',
    description: '10 practices, of any kind.',
    icon: Icons.star,
    isMet: (s) => s.totalSessions >= 10,
  ),
  MilestoneDefinition(
    id: 'sessions_50',
    title: 'Fifty Sessions',
    description: '50 practices, of any kind.',
    icon: Icons.star,
    isMet: (s) => s.totalSessions >= 50,
  ),
  MilestoneDefinition(
    id: 'sessions_100',
    title: 'Century',
    description: '100 practices, of any kind.',
    icon: Icons.military_tech,
    isMet: (s) => s.totalSessions >= 100,
  ),
  MilestoneDefinition(
    id: 'minutes_60',
    title: 'One Hour Practiced',
    description: '60 minutes of practice, all-time.',
    icon: Icons.timer,
    isMet: (s) => s.totalMinutes >= 60,
  ),
  MilestoneDefinition(
    id: 'minutes_600',
    title: 'Ten Hours Practiced',
    description: '600 minutes of practice, all-time.',
    icon: Icons.timer,
    isMet: (s) => s.totalMinutes >= 600,
  ),
];
