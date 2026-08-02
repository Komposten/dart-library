@OnPlatform({'browser': Skip('This code is only run in CI, never on browser')})
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/list_libraries.dart' as script;
import 'utils.dart';

void main() {
  final testDir = Directory('local/tests');

  setUp(() async => await testDir.create(recursive: true));
  tearDown(() async => delete(testDir));

  test('lists folders with versions', () async {
    await create(testDir, {
      'libraryA/pubspec.yaml': _pubspec('3.12.0'),
      'nested/libraryB/pubspec.yaml': _pubspec('3.12.1-SNAPSHOT'),
      'ignored/src/pubspec.yaml': _pubspec('3.12.2'),
    });

    final actual = script.execute([testDir.path]);
    final map = jsonDecode(actual);
    expect(
      map,
      equals({
        'include': [
          {'package': 'libraryA', 'sdk': '3.12.0'},
          {'package': 'libraryA', 'sdk': 'stable'},
          {
            'package': 'nested${Platform.pathSeparator}libraryB',
            'sdk': '3.12.1-SNAPSHOT',
          },
          {
            'package': 'nested${Platform.pathSeparator}libraryB',
            'sdk': 'stable',
          },
        ],
      }),
    );
  });
}

String _pubspec(String sdk) {
  return '''
name: test
description: Test library
version: 1.0.0

environment:
  sdk: ^$sdk

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
  ''';
}
