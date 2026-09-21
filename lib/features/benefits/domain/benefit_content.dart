class BenefitContent {
  const BenefitContent({
    required this.practiceType,
    required this.title,
    required this.tagline,
    required this.points,
  });

  final String practiceType;
  final String title;
  final String tagline;
  final List<String> points;
}

/// Deliberately general, non-medical wellness framing — not a substitute
/// for professional advice, just the plain-language "why bother" every
/// practice's pre-start screen and the progress tab both link to.
const benefitContent = <String, BenefitContent>{
  'meditation': BenefitContent(
    practiceType: 'meditation',
    title: 'Meditation',
    tagline: 'A few quiet minutes, on purpose.',
    points: [
      'Gives your attention somewhere steady to rest, instead of wherever the day pulls it.',
      'A regular sit tends to make everyday stress feel a little more manageable.',
      'Builds a habit of noticing your own mind — the first step in changing your relationship to it.',
      "No goal beyond sitting with yourself for the time you chose. That's the whole practice.",
    ],
  ),
  'box_breathing': BenefitContent(
    practiceType: 'box_breathing',
    title: 'Box Breathing',
    tagline: 'Four equal sides: inhale, hold, exhale, hold.',
    points: [
      'A simple pattern you can carry into a stressful moment, not just a quiet room.',
      'The equal counts give your breath something structured to follow, which tends to slow it down.',
      'Used by everyone from athletes to first responders as a fast way to steady themselves.',
      'Nothing to remember beyond one number, repeated four times.',
    ],
  ),
  'alt_nostril_breathing': BenefitContent(
    practiceType: 'alt_nostril_breathing',
    title: 'Alternate Nostril Breathing',
    tagline: 'Nadi Shodhana — a slower, more deliberate rhythm.',
    points: [
      'A traditional pranayama practice, valued for how deliberately slow and attentive it is.',
      'Alternating sides gives the practice a natural rhythm to focus on beyond just counting.',
      'A good precursor to meditation — many find it settles the mind before sitting still.',
      'Comfort matters more than any "correct" pace — the seconds are yours to adjust.',
    ],
  ),
};
