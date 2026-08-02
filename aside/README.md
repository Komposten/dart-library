# aside

Convenient and simple cross-platform isolate runners.

Run heavy computations or background work in isolates with a clean API — single values, streams, or full two-way communication.

## Features

- **`Aside.run()`** — run a function in an isolate and get a single return value.
- **`Aside.stream()`** — run a function in an isolate and receive a stream of values.
- **`Aside.biStream()`** — run a function in an isolate with full two-way communication.
- **Cross-platform** — works on native (via `dart:isolate`) and web.
- **`AsideRemoteException`** — errors from the isolate are surfaced cleanly on the caller side.

> **Web platform note:** On web, `dart:isolate` is not available. Aside falls back to running the code in the main thread instead of spawning an isolate or a service worker. The API remains identical, so your code works everywhere without changes.

## Getting started

Add `aside` to your `pubspec.yaml`:

```yaml
dependencies:
  aside:
    git:
      url: https://github.com/komposten/dart-library.git
      path: aside
      ref: <commit hash>
```

## Usage

Import the library:

```dart
import 'package:aside/aside.dart';
```

### Run a function in an isolate

```dart
int heavyWork(int input) {
  // Simulate heavy computation.
  var result = 0;
  for (var i = 0; i < input; i++) {
    result += i;
  }
  return result;
}

final result = await Aside.run(heavyWork, 1000000);
print(result); // 499999500000
```

### Stream values from an isolate

```dart
void generateValues(int count, MessageChannel<String> channel) {
  for (var i = 0; i < count; i++) {
    channel.data('item $i');
  }
}

final stream = Aside.stream(generateValues, 5);
await for (final value in stream) {
  print(value); // 'item 0', 'item 1', ...
}
```

### Two-way communication

```dart
void worker(void message, MessageChannel<String> channel, Stream<Object> input) {
  channel.data('ready');
  input.listen((data) {
    if (data == 'ping') {
      channel.data('pong');
    }
  });
}

final (stream, channel) = await Aside.biStream(worker, null);

// Listen for messages from the isolate.
stream.listen(print);

// Send messages to the isolate.
channel.data('ping');
```

### Error handling

When the function inside the isolate throws, the error is wrapped in an `AsideRemoteException` and rethrown on the caller side:

```dart
try {
  final result = await Aside.run(_riskyWork, input);
} on AsideRemoteException catch (e) {
  print('Isolate error: ${e.error}');
  print('Stack trace: ${e.stackTraceString}');
}
```

### Debug labels

All three methods accept an optional `debugLabel` to help identify isolates during debugging:

```dart
final result = await Aside.run(heavyWork, input, debugLabel: 'number-cruncher');
```

## The `AsideRemoteException` object

The exception has two properties:
- `error` — the original error thrown in the isolate.
- `stackTraceString` — the stack trace as a string, or `null` if none was provided.