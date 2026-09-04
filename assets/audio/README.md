# Audio assets

Three cues, referenced by fixed path from `lib/core/audio/audio_service.dart`.
**Drop real recordings in at these exact names — no code changes needed:**

| File | Sound | Used for |
| --- | --- | --- |
| `kangse_bell.mp3` | a clear, bright bell ("Kangse") | meditation: start + every minute · box breathing: start + every phase change · alternate nostril: start only |
| `hanchi_gong.mp3` | a deep closing gong ("gong hanchi") | the end of every practice (meditation completes, or box / alternate-nostril breathing is stopped) |
| `phase_cue.mp3` | a short, soft tone — quiet enough that two or three in quick succession don't clash | alternate nostril: every phase change (inhale / hold / exhale), where holds can be very short |

The files currently checked in are **placeholders** (`kangse_bell` / `hanchi_gong`
are plain decaying sine waves synthesized with ffmpeg; `phase_cue` is a soft
low sine). They exist so the app builds and the timing is testable — replace
all three with real recordings before the store build. Keep them short
(bell ~1–1.5 s, gong ~3–4 s, phase cue ~100–150 ms), mono, 44.1 kHz, MP3.
