/// Convenient and simple cross-platform isolate runners.
///
/// Use [Aside.run] to run a function in an isolate and get a single return
/// value, [Aside.stream] to receive a stream of values, or [Aside.biStream]
/// for full two-way communication.
///
/// On native platforms the code runs in a true isolate via `dart:isolate`.
/// On web, where isolates are not available, the code runs in the main thread
/// (no service worker or web worker is used). The API is identical across all
/// platforms.
library;
export 'src/aside_base.dart';
export 'src/isolates/isolates.dart';