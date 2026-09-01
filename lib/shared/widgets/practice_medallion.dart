import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A circular icon-in-a-wash — the small visual anchor used at the top of
/// setup/finished/countdown screens (see OnboardingScreen's _BreathingIcon,
/// which this generalizes) so every practice screen shares one identity
/// instead of each inventing its own icon treatment.
class PracticeMedallion extends StatelessWidget {
  const PracticeMedallion({
    super.key,
    required this.icon,
    required this.color,
    this.size = 88,
    this.pulse = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final medallion = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
    if (!pulse) return medallion;
    return medallion
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.08,
          duration: 2200.ms,
          curve: Curves.easeInOut,
        );
  }
}
