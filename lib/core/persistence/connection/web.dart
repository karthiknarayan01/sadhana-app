import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

// web/sqlite3.wasm and web/drift_worker.js (compiled from
// web/drift_worker.dart via `dart compile js`) must exist for this to work —
// see the app README's "Running on web" section.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'sadhana',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
