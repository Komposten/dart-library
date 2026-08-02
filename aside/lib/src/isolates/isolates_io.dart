import 'dart:async';
import 'dart:isolate';
import 'package:aside/src/isolates/isolates.dart' as i;
import 'package:aside/src/isolates/token/isolate_token.dart' as token;

class _IOIsolate implements i.Isolate {
  final Isolate _isolate;

  _IOIsolate(this._isolate);

  @override
  void kill({required bool immediate}) => _isolate.kill(
    priority: immediate ? Isolate.immediate : Isolate.beforeNextEvent,
  );
}

class _IOReceivePort implements i.ReceivePort {
  late final ReceivePort _receivePort;

  @override
  late final _IOSendPort sendPort;

  _IOReceivePort([ReceivePort? receivePort, SendPort? sendPort]) {
    _receivePort = receivePort ?? ReceivePort();
    this.sendPort = _IOSendPort(sendPort ?? _receivePort.sendPort);
  }

  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _receivePort.listen(
      (data) {
        switch (data) {
          case ReceivePort p:
            data = _IOReceivePort(p);
            break;
          case SendPort p:
            data = _IOSendPort(p);
            break;
        }

        onData?.call(data);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void close() => _receivePort.close();
}

class _IOSendPort implements i.SendPort {
  final SendPort _sendPort;

  _IOSendPort(this._sendPort);

  @override
  void send(Object? message) {
    switch (message) {
      case _IOReceivePort p:
        message = p._receivePort;
        break;
      case _IOSendPort p:
        message = p._sendPort;
        break;
    }

    _sendPort.send(message);
  }
}

class Isolates {
  static String get currentName =>
      Isolate.current.debugName ?? '<unnamed isolate>';

  static Object? get rootIsolateToken => token.rootIsolateToken;

  static i.ReceivePort receivePort() => _IOReceivePort();

  static Future<i.Isolate> spawn<T>(
    void Function(T) entryPoint,
    T message, {
    bool paused = false,
    bool errorsAreFatal = true,
    i.SendPort? onExit,
    i.SendPort? onError,
    String? debugName,
  }) async => _IOIsolate(
    await Isolate.spawn(
      entryPoint,
      message,
      paused: paused,
      errorsAreFatal: errorsAreFatal,
      onExit: onExit != null ? (onExit as _IOSendPort)._sendPort : null,
      onError: onError != null ? (onError as _IOSendPort)._sendPort : null,
      debugName: debugName,
    ),
  );
}
