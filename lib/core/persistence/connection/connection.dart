// Conditional export: native.dart (dart:io, sqlite3_flutter_libs) on
// Android/iOS/desktop, web.dart (drift/wasm.dart, IndexedDB/OPFS-backed) on
// web — sqlite3_flutter_libs imports dart:ffi, which doesn't exist on web
// at all (a compile-time error, not just a runtime one), so this can't be a
// runtime platform check.
export 'native.dart' if (dart.library.js_interop) 'web.dart';
