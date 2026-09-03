import 'package:sadhana/core/analytics/analytics_service.dart';

class FakeAnalyticsService implements AnalyticsService {
  final List<(String feature, Duration duration)> featureTimesRecorded = [];
  int searchesRecorded = 0;

  @override
  void recordFeatureTime(String feature, Duration duration) {
    featureTimesRecorded.add((feature, duration));
  }

  @override
  void recordSearchPerformed() {
    searchesRecorded++;
  }
}
