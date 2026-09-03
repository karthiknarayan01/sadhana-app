import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Sends anonymous, aggregate-only usage events to the backend's /events
/// endpoint — see sadhana-backend's app/analytics.py. No user or device
/// identifier of any kind is ever included, matching the app's existing
/// "100% local, no data collection" stance for meditation/breathing (see
/// README's Privacy section) as closely as an aggregate-usage feature can:
/// this can only ever say *that* a feature was used and for how long, never
/// *by whom*.
///
/// An interface (like SearchApi) rather than one concrete class so tests
/// can swap in a fake instead of exercising a real, fire-and-forget HTTP
/// call — which `flutter_test`'s strict "no pending timers" check at the
/// end of every test doesn't tolerate well, same as any other real network
/// attempt in a widget test.
abstract class AnalyticsService {
  void recordFeatureTime(String feature, Duration duration);
  void recordSearchPerformed();
}

/// Fire-and-forget, same reasoning as AudioService/WakelockPlus calls
/// elsewhere in this app: a lost event is a slightly-undercounted chart
/// nobody's watching in real time, never a user-visible error — so this
/// deliberately doesn't share the search API's Dio client (which retries
/// with backoff; analytics shouldn't burn over a second retrying a fire-
/// and-forget call) and never surfaces or retries a failure itself.
class DioAnalyticsService implements AnalyticsService {
  DioAnalyticsService(this._dio);

  final Dio _dio;

  @override
  void recordFeatureTime(String feature, Duration duration) {
    if (duration <= Duration.zero) return;
    _send([
      {
        'event': 'feature_time',
        'feature': feature,
        'seconds': duration.inSeconds,
      },
    ]);
  }

  @override
  void recordSearchPerformed() {
    _send([
      {'event': 'search_performed'},
    ]);
  }

  void _send(List<Map<String, Object?>> events) {
    unawaited(_post(events));
  }

  Future<void> _post(List<Map<String, Object?>> events) async {
    try {
      await _dio.post<void>('/events', data: {'events': events});
    } catch (error, stackTrace) {
      developer.log(
        'Failed to send usage events',
        error: error,
        stackTrace: stackTrace,
        name: 'AnalyticsService',
      );
    }
  }
}
