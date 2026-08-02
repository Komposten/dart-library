import 'package:aside/aside.dart';

/// A heavy computation that sums numbers from 0 to [n].
int sumUpTo(int n) {
  var total = 0;
  for (var i = 0; i < n; i++) {
    total += i;
  }
  return total;
}

Future<void> main() async {
  final result = await Aside.run(sumUpTo, 1000000);
  print('Sum: $result');
}
