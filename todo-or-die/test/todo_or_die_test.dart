import 'package:test/test.dart';
import 'package:todo_or_die/todo_or_die.dart';

void main() {
  final tomorrow = DateTime.now().add(Duration(days: 1));
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  bool isTrue() => true;
  bool isFalse() => false;

  group('basics', () {
    test('doesNothingIfTimeNotPassed', () {
      expect(() => todoOrDie('Test', by: tomorrow), returnsNormally);
    });

    test('doesNothingIfGivenIsFalse', () {
      expect(() => todoOrDie('Test', given: isFalse), returnsNormally);
    });

    test('doesNothingIfGivenIsTrueButTimeNotPassed', () {
      expect(
        () => todoOrDie('Test', by: tomorrow, given: isTrue),
        returnsNormally,
      );
    });

    test('doesNothingIfTimePassedButGivenIsFalse', () {
      expect(
        () => todoOrDie('Test', given: isFalse, by: yesterday),
        returnsNormally,
      );
    });

    test('throwsIfTimePassed', () {
      expect(
        () => todoOrDie('Test', by: yesterday),
        throwsA(
          predicate(
            (e) =>
                e is TodoIsDueError &&
                e.message == 'Test' &&
                e.by == yesterday &&
                e.given == null,
          ),
        ),
      );
    });

    test('throwsIfGivenIsTrue', () {
      expect(
        () => todoOrDie('Test', given: isTrue),
        throwsA(
          predicate(
            (e) =>
                e is TodoIsDueError &&
                e.message == 'Test' &&
                e.by == null &&
                e.given == isTrue,
          ),
        ),
      );
    });

    test('throwsIfTimePassedAndGivenIsTrue', () {
      expect(
        () => todoOrDie('Test', by: yesterday, given: isTrue),
        throwsA(
          predicate(
            (e) =>
                e is TodoIsDueError &&
                e.message == 'Test' &&
                e.by == yesterday &&
                e.given == isTrue,
          ),
        ),
      );
    });
  });

  group('customAlerter', () {
    final alerts = <String>[];
    setUpAll(() => TodoOrDie.configure(alerter: (m, b, g) => alerts.add(m)));
    setUp(() => alerts.clear());

    tearDownAll(() => TodoOrDie.configure());

    test('isUsedInsteadOfDefaultThrow', () {
      expect(
        () => todoOrDie('Test', by: yesterday, given: isTrue),
        returnsNormally,
      );
      expect(alerts, equals(['Test']));
    });
  });
}
