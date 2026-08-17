# Sadhana

A Flutter app (Android + iOS, one codebase) with three features:

- **Meditation** — a simple, Insight Timer–style practice timer. Pick a
  duration (2 min–1 hour), a bell every minute, a closing gong, mute if you
  want. No login — practice history lives entirely on-device.
- **Pranayama (breathing)** — box breathing and alternate nostril breathing,
  with a paced animated guide.
- **Shloka search** — search shlokas/sutras/stotras by name or content,
  view results in multiple languages. Calls the companion
  [sadhana-backend](https://github.com/karthiknarayan01/sadhana-backend)
  service; every other feature works fully offline.

A cross-cutting goal across all three: surface each practice's benefits and
the user's own progress in a way that keeps them motivated to come back —
this isn't cosmetic, it's a core design pillar.

## Stack

Riverpod for state management, `drift` (sqlite) for local session history
(streaks/charts need per-session detail, not just a counter),
`shared_preferences` for simple settings.

```
lib/
  core/         # theme, persistence (drift + shared_preferences), providers
  features/
    meditation/
    breathing/
    progress/    # streaks, heatmap, milestones, charts
    benefits/     # "why this practice" content
    search/        # calls sadhana-backend
  shared/widgets/
```

## Development

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

`dev` is the default/live branch; `main` only ever advances via a dev → main
promotion PR (see `.github/workflows/enforce-dev-to-main.yml`).

## Privacy

Meditation and breathing are 100% local — no account, no data collection; if
you uninstall the app, that history is gone. Shloka search sends the typed
query to the backend to run the search; nothing else about you is sent.
