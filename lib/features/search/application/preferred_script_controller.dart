import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Which language key (matching the backend's per-document language maps —
/// e.g. "devanagari"/"english") results and the detail screen display.
/// Global rather than per-result: the spec calls for a single
/// user-selectable display language, not a per-card setting.
class PreferredScriptController extends Notifier<String> {
  @override
  String build() {
    final prefsAsync = ref.watch(prefsProvider);
    return prefsAsync.valueOrNull?.preferredScript ?? 'devanagari';
  }

  Future<void> select(String script) async {
    state = script;
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setPreferredScript(script);
  }
}

final preferredScriptControllerProvider =
    NotifierProvider<PreferredScriptController, String>(
      PreferredScriptController.new,
    );
