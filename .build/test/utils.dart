import 'dart:io';

Future<void> create(Directory directory, Map<String, String> files) async {
  for (final MapEntry(key: path, value: content) in files.entries) {
    final file = File(directory.path + '/' + path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }
}

Future<void> delete(Directory directory, {int attempts = 3}) async {
  var attempt = 0;
  while (attempt < attempts) {
    try {
      await directory.delete(recursive: true);
      break;
    } catch (_) {
      await Future.delayed(Duration(milliseconds: 250));
      attempt++;
    }
  }
}
