// Compiled to web/drift_worker.js (committed — see lib/core/persistence/
// connection/web.dart) via:
//   dart compile js -o web/drift_worker.js web/drift_worker.dart
// Re-run that after bumping the drift package version.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
