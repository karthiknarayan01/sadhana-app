import 'package:sadhana/core/audio/audio_service.dart';

/// Records calls instead of touching real platform audio channels (which
/// don't exist under plain `flutter test`) — lets tests assert "the bell
/// fired at the right moment" without needing an integration-test device.
class FakeAudioService implements AudioService {
  int bellPlayCount = 0;
  int gongPlayCount = 0;
  int phaseCuePlayCount = 0;
  bool configured = false;

  @override
  Future<void> configure() async {
    configured = true;
  }

  @override
  Future<void> playBell({required bool muted}) async {
    if (!muted) bellPlayCount++;
  }

  @override
  Future<void> playGong({required bool muted}) async {
    if (!muted) gongPlayCount++;
  }

  @override
  Future<void> playPhaseCue({required bool muted}) async {
    if (!muted) phaseCuePlayCount++;
  }

  @override
  Future<void> dispose() async {}
}
