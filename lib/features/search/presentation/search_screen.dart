import 'package:flutter/material.dart';

/// Placeholder for shloka/sutra search — built out last, once the backend
/// search API exists (see the sadhana-backend repo). The one feature with
/// an external dependency, so it's sequenced after everything local.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Shloka search — coming soon')),
    );
  }
}
