# Audio assets

`basu_bell.mp3` and `hanchi_gong.mp3` are **placeholder tones**, synthesized
locally with `ffmpeg` (plain decaying sine waves — 528Hz for the bell, 110Hz
for the gong), not real bell/gong recordings. They exist so the timer feature
is genuinely testable end-to-end. Swap them for real recordings before any
store submission — same filenames, so no code changes needed elsewhere.
