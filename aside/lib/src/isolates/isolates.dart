import 'dart:async';

export 'package:aside/src/isolates/isolates_io.dart'
    if (dart.library.js_interop) 'package:aside/src/isolates/isolates_web.dart';

abstract interface class Isolate {
  void kill({required bool immediate});
}

abstract interface class ReceivePort {
  SendPort get sendPort;
  StreamSubscription<dynamic> listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });
  void close();
}

abstract interface class SendPort {
  void send(Object? message);
}
