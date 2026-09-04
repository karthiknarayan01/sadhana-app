# Audio assets

Six cues, referenced by fixed path from `lib/core/audio/audio_service.dart`.
**Drop replacements in at these exact names — no code changes needed.**

| File | Sound | Used for |
| --- | --- | --- |
| `kangse_bell.mp3` | the long Kangse bell (~10 s, high at the strike, fading gradually to silence) | meditation: opens the session and marks every minute |
| `kangse_short.mp3` | a short Kangse strike (~2 s) | box breathing: opens the session and marks every phase change |
| `hanchi_gong.mp3` | a deep closing gong | the end of every practice — meditation completes, or breathing finishes its cycles / is stopped |
| `cue_inhale.mp3` | a warm tone **gliding up** (~0.75 s) | alternate nostril: "breathe in" (also opens the practice) |
| `cue_hold.mp3` | two soft steady pulses (~0.5 s) | alternate nostril: "hold" |
| `cue_exhale.mp3` | a warm tone **gliding down**, easing off (~0.9 s) | alternate nostril: "breathe out" |

The up / steady / down pitch contour of the three alternate-nostril cues is
what lets the practice be followed with the eyes closed — keep that shape if
you replace them.

### Current state

`kangse_bell.mp3` and `kangse_short.mp3` are trimmed/level-matched from the
provided Kangse recording. `hanchi_gong.mp3` is the provided gong recording
(an 8 kHz source — dull by nature; swap for a fuller recording if you have
one). `cue_inhale/hold/exhale.mp3` are short synthesized arpeggios — replace
with real instrument tones if desired, keeping the up / flat / down shape.

Keep everything mono, 44.1 kHz, MP3; bells 1–10 s, gong 3–5 s, breath cues
under ~0.8 s.
