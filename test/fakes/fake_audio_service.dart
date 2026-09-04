import 'package:sadhana/core/audio/audio_service.dart';

/// Records calls instead of touching real platform audio channels (which
/// don't exist under plain `flutter test`) — lets tests assert "the cue
/// fired at the right moment" without an integration-test device.
class FakeAudioService implements AudioService {
  int bellPlayCount = 0;
  bool? lastBellLong;
  int gongPlayCount = 0;
  bool configured = false;

  @override
  Future<void> configure() async {
    configured = true;
  }

  @override
  Future<void> playBell({required bool muted, bool long = false}) async {
    if (muted) return;
    bellPlayCount++;
    lastBellLong = long;
  }

  @override
  Future<void> playGong({required bool muted}) async {
    if (!muted) gongPlayCount++;
  }

  @override
  Future<void> dispose() async {}
}
