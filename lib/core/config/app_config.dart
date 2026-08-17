/// Set at build time: `flutter run --dart-define=SEARCH_API_BASE_URL=http://10.0.2.2:8080`
/// (Android emulator's alias for the host machine) or the real load
/// balancer IP once infra/terraform has been applied — see the backend
/// repo's infra/terraform/README.md. Defaults to nothing so a forgotten
/// `--dart-define` fails loudly (a connection error) instead of silently
/// hitting a placeholder that looks like a real backend.
const String searchApiBaseUrl = String.fromEnvironment('SEARCH_API_BASE_URL');
