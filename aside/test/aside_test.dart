import 'dart:async';

import 'package:aside/aside.dart';
import 'package:test/test.dart';

// Top-level functions (required by dart:isolate).
int doubleIt(int x) => x * 2;

int throwError(int x) => throw ArgumentError('boom');

void streamValues(int x, MessageChannel<String> channel) {
  for (int i = 0; i < x; i++) {
    channel.data('item $i');
  }
}

void biStreamValues(void v, MessageChannel<String> channel, Stream<Object> stream) async {
  final endSignal = Completer<void>();
  channel.data('waiting');

  stream.listen(
    (data) {
      if (data is List) {
        if (data[0] == 'run') {
          streamValues(data[1] as int, channel);
        }
      } else if (data == 'done') {
        endSignal.complete();
      }
    },
    onError: (error) {
      channel.error('Received error: $error');
    },
  );

  await endSignal.future;
}

void streamError(int x, MessageChannel<String> channel) {
  channel.error(ArgumentError('stream boom'), StackTrace.current);
}

void main() {
  group('Aside', () {
    group('run', () {
      test('completeResult returnsExpected', () async {
        final result = await Aside.run(doubleIt, 21);
        expect(result, equals(42));
      });

      test('errorResult throwsAsideRemoteException', () async {
        expect(() => Aside.run(throwError, 1), throwsA(isA<AsideRemoteException>()));
      });
    });

    group('stream', () {
      test('completeResult yieldsAllValues', () async {
        final stream = Aside.stream(streamValues, 3);
        final values = await stream.toList();
        expect(values, equals(['item 0', 'item 1', 'item 2']));
      });

      test('errorResult addsErrorToStream', () async {
        final stream = Aside.stream(streamError, 0);
        late Object actualError;
        try {
          await for (final _ in stream) {
            // no data expected
          }
        } catch (e) {
          actualError = e;
        }
        expect(actualError, isA<AsideRemoteException>());
      });
    });

    group('biStream', () {
      test('completeResult listensAndSendsValues', () async {
        final (stream, channel) = await Aside.biStream(biStreamValues, null);
        final iterator = StreamIterator(stream);

        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, equals('waiting'));

        channel.data(['run', 3]);
        channel.data('done');
        final values = <String>[];
        while (await iterator.moveNext()) {
          values.add(iterator.current);
        }
        expect(values, equals(['item 0', 'item 1', 'item 2']));
      });

      test('errorMessageAndResult', () async {
        final (stream, channel) = await Aside.biStream(biStreamValues, null);

        channel.data(['run', 1]);
        channel.error('<error>');

        try {
          await stream.toList();
        } catch (e) {
          expect(e, isA<AsideRemoteException>());
          expect((e as AsideRemoteException).error, equals('Received error: <error>'));
        }
      });
    });
  });
}
