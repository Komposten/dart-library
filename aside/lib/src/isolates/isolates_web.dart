import 'dart:async';

import 'package:aside/src/isolates/isolates.dart' as i;

class _WebIsolate<T> implements i.Isolate {
  final void Function(T) _entryPoint;
  final T _message;
  final i.SendPort? _onError;

  _WebIsolate(void Function(T) entryPoint, T message, {i.SendPort? onError})
    : _entryPoint = entryPoint,
      _message = message,
      _onError = onError;

  Future<void> _start() => Future.delayed(Duration.zero, () async {
    await runZonedGuarded(
      () async => _entryPoint(_message),
      (e, st) => _onError?.send([e, st]),
    );
  });

  @override
  void kill({required bool immediate}) {}
}

class _WebReceivePort implements i.ReceivePort {
  final _WebSendPort _sendPort;

  _WebReceivePort() : _sendPort = _WebSendPort();

  @override
  i.SendPort get sendPort => _sendPort;

  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _sendPort.streamController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void close() {
    // TODO: implement close
  }
}

class _WebSendPort implements i.SendPort {
  final StreamController<dynamic> streamController = StreamController();

  _WebSendPort();

  @override
  void send(Object? message) {
    streamController.add(message);
  }
}

class Isolates {
  static String get currentName => 'main';

  static Object? get rootIsolateToken => null;

  static i.ReceivePort receivePort() => _WebReceivePort();

  static Future<i.Isolate> spawn<T>(
    void Function(T) entryPoint,
    T message, {
    bool paused = false,
    bool errorsAreFatal = true,
    i.SendPort? onExit,
    i.SendPort? onError,
    String? debugName,
  }) async => _WebIsolate<T>(entryPoint, message, onError: onError).._start();
}
