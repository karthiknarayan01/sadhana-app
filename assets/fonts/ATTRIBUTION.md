# Bundled fonts

All bundled here — instead of fetched at runtime from Google's CDN, which
is what both the `google_fonts` package and Flutter web's own default
(Roboto, when not bundled) otherwise do — so no screen's first paint waits
on a network round-trip. Licensed under the SIL Open Font License 1.1 —
full text in the matching `OFL-*.txt` file alongside each.

- **Noto Sans Devanagari** — Copyright 2022 The Noto Project Authors
  (https://github.com/notofonts/devanagari)
- **Merriweather** — Copyright 2020 The Merriweather Project Authors
  (https://github.com/EbenSorkin/Merriweather4), Reserved Font Name
  "Merriweather"
- **Roboto** — Copyright 2011 The Roboto Project Authors
  (https://github.com/googlefonts/roboto-classic) — Material's default
  typeface, used app-wide via ThemeData.fontFamily (see
  lib/core/theme/app_theme.dart), not reader-specific like the two above.

Unmodified, downloaded from Google Fonts (fonts.google.com).
