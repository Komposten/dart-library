import 'dart:async';

import 'package:aside/src/isolates/isolates.dart';

enum _MessageType { port, data, error, exit }

enum _IsolateType { single, stream, biStream }

class MessageChannel<T> {
  late final SendPort _reply;

  MessageChannel();

  void init(SendPort reply) => _reply = reply;

  void _port(SendPort port) => _reply.send([_MessageType.port, port]);

  void data(T data) => _reply.send([_MessageType.data, data]);

  void error(dynamic error, [Object? stackTrace]) => _reply.send([_MessageType.error, error, ?stackTrace?.toString()]);

  void close() => _reply.send([_MessageType.exit]);
}

class Aside {
  /// Run [function] in an isolate and receive a single return value
  ///
  /// ```dart
  /// final result = await Aside.run(_heavyWork, input);
  /// ```
  static Future<R> run<M, R>(FutureOr<R> Function(M) function, M message, {String? debugLabel}) {
    final completer = Completer<R>();

    _run(
      function,
      message,
      (R data) => !completer.isCompleted ? completer.complete(data) : null,
      (dynamic error, String? stack) =>
          !completer.isCompleted ? completer.completeError(AsideRemoteException(error, stack)) : null,
      () => !completer.isCompleted
          ? completer.completeError(AsideRemoteException('The isolate failed to produce a value', null))
          : null,
      type: _IsolateType.single,
      debugLabel: debugLabel,
    );

    return completer.future;
  }

  /// Run [function] in an isolate and receive a stream of values
  ///
  /// ```dart
  /// final result = Aside.stream(_heavyWork, input);
  /// result.listen(onData, onError: handleError);)
  /// ```
  static Stream<R> stream<M, R>(FutureOr<void> Function(M, MessageChannel<R>) function, M message, {String? debugLabel}) {
    final streamController = StreamController<R>();
    _run(
      function,
      message,
      (R data) => !streamController.isClosed ? streamController.add(data) : null,
      (dynamic error, String? stack) =>
          !streamController.isClosed ? streamController.addError(AsideRemoteException(error, stack)) : null,
      () => streamController.close(),
      type: _IsolateType.stream,
      debugLabel: debugLabel,
    );

    return streamController.stream;
  }

  /// Run [function] in an isolate with full two-way communication
  ///
  /// ```dart
  /// final (stream, channel) = await Aside.biStream(_heavyWork, input);
  ///
  /// // Listen to messages from the isolate
  /// stream.listen(onData, onError: handleError);)
  ///
  /// // Send data to the isolate
  /// channel.data('Hi, Isolate!');
  /// ```
  static Future<(Stream<R>, MessageChannel<V>)> biStream<M, R, V>(
    FutureOr<void> Function(M, MessageChannel<R>, Stream<V>) function,
    M message, {
    String? debugLabel,
  }) async {
    final streamController = StreamController<R>();
    final sendPort = await _run<M, R, V>(
      function,
      message,
      (R data) => !streamController.isClosed ? streamController.add(data) : null,
      (dynamic error, String? stack) =>
          !streamController.isClosed ? streamController.addError(AsideRemoteException(error, stack)) : null,
      () => streamController.close(),
      type: _IsolateType.biStream,
      returnSendPort: true,
      debugLabel: debugLabel,
    )!;

    return (streamController.stream, MessageChannel<V>()..init(sendPort));
  }

  /// Start an isolate
  ///
  /// Returns a `Future<SendPort>` if [returnSendPort] is true, otherwise returns [null].
  static Future<SendPort>? _run<M, R, V>(
    Function function,
    M message,
    void Function(R) onData,
    void Function(dynamic, String?) onError,
    void Function() onExit, {
    required _IsolateType type,
    bool returnSendPort = false,
    String? debugLabel,
  }) {
    final mainReceive = Isolates.receivePort();
    final portCompleter = Completer<SendPort>();
    late final StreamSubscription<dynamic> sub;

    sub = mainReceive.listen((dynamic raw) async {
      if (raw is! List || raw.isEmpty || raw[0] is! _MessageType) {
        return;
      }

      final type = raw[0];
      if (type == _MessageType.port) {
        portCompleter.complete(raw[1] as SendPort);
      } else if (type == _MessageType.data && raw.length >= 2) {
        onData(raw[1] as R);
      } else if (type == _MessageType.error) {
        onError(raw[1], raw.length > 2 ? raw[2] : null);
      } else {
        onExit();
        await sub.cancel();
        mainReceive.close();
      }
    });

    Isolates.spawn(_isolateEntry, [
      function,
      message,
      mainReceive.sendPort,
      type,
      MessageChannel<R>(),
      if (returnSendPort) StreamController<V>(),
    ], debugName: debugLabel).catchError((Object error, StackTrace stack) {
      onError(error, stack.toString());
      mainReceive.close();
    });

    return returnSendPort ? portCompleter.future : null;
  }

  static Future<void> _isolateEntry(List<Object?> init) async {
    final fn = init[0] as dynamic;
    final message = init[1];
    final reply = init[2] as SendPort;
    final type = init[3] as _IsolateType;
    final messageChannel = (init[4] as MessageChannel)..init(reply);
    final receiveController = type == _IsolateType.biStream ? init[5] as StreamController : null;

    try {
      if (type == _IsolateType.single) {
        messageChannel.data(await fn(message));
      } else if (type == _IsolateType.stream) {
        await fn(message, messageChannel);
      } else {
        _setUpSendPort(messageChannel, receiveController!);
        await fn(message, messageChannel, receiveController.stream);
      }
    } catch (e, st) {
      messageChannel.error(e, st);
    } finally {
      messageChannel.close();
    }
  }

  static void _setUpSendPort(MessageChannel messageChannel, StreamController streamController) {
    final receivePort = Isolates.receivePort();
    messageChannel._port(receivePort.sendPort);
    receivePort.listen((raw) {
      if (raw is List && raw.isNotEmpty && raw[0] is _MessageType) {
        final type = raw[0];
        if (type == _MessageType.data && raw.length >= 2) {
          streamController.add(raw[1]);
        } else if (type == _MessageType.error) {
          streamController.addError(raw[1], raw.length > 2 ? raw[2] : null);
        }
      }
    });
  }
}

/// Surfaced on the calling isolate when the worker throws.
class AsideRemoteException implements Exception {
  const AsideRemoteException(this.error, this.stackTraceString);
  final dynamic error;
  final String? stackTraceString;

  @override
  String toString() => 'AsideRemoteException: $error${stackTraceString != null ? '\n$stackTraceString' : ''}';
}
