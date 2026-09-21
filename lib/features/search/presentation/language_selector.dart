import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.languages,
    required this.selected,
    required this.onSelected,
  });

  final List<String> languages;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: languages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final language = languages[index];
          return ChoiceChip(
            label: Text(_label(language)),
            selected: language == selected,
            onSelected: (_) => onSelected(language),
          );
        },
      ),
    );
  }

  String _label(String language) => language.isEmpty
      ? language
      : language[0].toUpperCase() + language.substring(1);
}
