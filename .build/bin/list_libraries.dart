import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  try {
    print(execute(args));
  } catch (e) {
    stderr.writeln(e);
    exit(1);
  }
}

String execute(List<String> args) {
  if (args.length < 1) {
    throw 'Please specify a path!';
  }

  final root = args[0];

  final rootDir = Directory(root);
  if (rootDir.existsSync()) {
    final pubspecs = _search(rootDir);

    if (pubspecs.isEmpty) {
      throw 'No packages (pubspec.yaml files) were found in ${rootDir.absolute.path}';
    }

    final packagesWithVersion = pubspecs.map((file) {
      final package = _relativize(file.parent, rootDir);
      final version = _sdkVersion(file);
      return (package, version);
    }).toList();

    packagesWithVersion.sort((a, b) => a.$1.compareTo(b.$1));

    final outputMap = {
      'include': packagesWithVersion
          .expand(
            (e) => [
              {'package': e.$1, 'sdk': e.$2.toString()},
              {'package': e.$1, 'sdk': 'stable'},
            ],
          )
          .toList(),
    };

    stderr.writeln('Discovered packages:\n${packagesWithVersion.join('\n')}');
    return jsonEncode(outputMap);
  }

  throw 'Specified directory does not exist';
}

List<File> _search(Directory directory) {
  final pubspecs = <File>[];
  for (final entity in directory.listSync()) {
    final type = entity.statSync().type;

    if (type == FileSystemEntityType.file &&
        entity.path.endsWith('pubspec.yaml')) {
      pubspecs.add(entity as File);
    } else if (type == FileSystemEntityType.directory &&
        _include(_relativize(entity, directory))) {
      pubspecs.addAll(_search(entity as Directory));
    }
  }

  return pubspecs;
}

bool _include(String name) {
  final excluded = ['lib', 'bin', 'src', RegExp(r'^[.]\w+$')];
  final included = ['.build'];
  if (!included.contains(name)) {
    for (final exclude in excluded) {
      if (exclude is String && name == exclude) {
        return false;
      } else if (exclude is RegExp && exclude.hasMatch(name)) {
        return false;
      }
    }
  }

  return true;
}

String _relativize(FileSystemEntity entity, Directory parent) {
  return entity.path.substring(parent.path.length + 1);
}

_Version? _sdkVersion(File pubspec) {
  final content = pubspec.readAsStringSync();
  final pattern = RegExp(r'sdk: [^\d]*(\d+)[.](\d+)[.](\d+)(.*)?');
  final version = pattern.firstMatch(content);
  if (version != null) {
    return _Version(
      int.parse(version.group(1)!),
      int.parse(version.group(2)!),
      int.parse(version.group(3)!),
      version.group(4) ?? '',
    );
  }

  throw 'pubspec is missing SDK constraint: ${pubspec.path}';
}

class _Version {
  final int major;
  final int minor;
  final int patch;
  final String extra;

  _Version(this.major, this.minor, this.patch, this.extra);

  bool operator <(_Version other) =>
      major < other.major ||
      (major == other.major && minor < other.minor) ||
      (major == other.major && minor == other.minor && patch < other.patch) ||
      (major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          extra.compareTo(other.extra) < 0);

  @override
  String toString() => '$major.$minor.$patch$extra';
}
