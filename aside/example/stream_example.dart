import 'package:aside/aside.dart';

/// Emits a [count] number of values back to the original isolate.
void emitWorkItems(int count, MessageChannel<String> channel) {
  for (var i = 0; i < count; i++) {
    channel.data('Completed work item $i');
  }
}

Future<void> main() async {
  final stream = Aside.stream(emitWorkItems, 5);
  await for (final message in stream) {
    print(message);
  }
}
