# Audio assets

Three cues, referenced by fixed path from `lib/core/audio/audio_service.dart`.
**Drop replacements in at these exact names — no code changes needed.**

| File | Sound | Used for |
| --- | --- | --- |
| `kangse_bell.mp3` | the long Kangse bell (~10 s, high at the strike, fading gradually to silence) | meditation: opens the session and marks every minute |
| `kangse_short.mp3` | a short Kangse strike (~2 s) | box breathing **and** alternate nostril: opens the session and marks every phase (inhale / hold / exhale) |
| `hanchi_gong.mp3` | a deep closing gong | the end of every practice — meditation completes, or breathing finishes its cycles / is stopped |

### Current state

`kangse_bell.mp3` and `kangse_short.mp3` are trimmed/level-matched from the
provided Kangse recording (`kangse_bell` uses `dynaudnorm` to hold a steady
loudness for ~8 s before a 2 s fade, so it reads as a full-length ring).
`hanchi_gong.mp3` is the provided gong recording — an 8 kHz source, dull by
nature; swap for a fuller recording if you have one.

Keep everything mono, 44.1 kHz, MP3; the long bell 8–10 s, short bell 1–2 s,
gong 3–5 s.
