# dart-library

A collection of small Dart snippets and scripts provided as reusable packages.

All code in this library is cross-platform and works on both the Dart VM and on web.

## Packages

| Package | Description |
|---------|-------------|
| [todo_or_die](todo_or_die) | Write TODOs in code that ensure you actually do them, with deadlines or other conditions as triggers. |
| [aside](aside) | Convenient and simple cross-platform isolate runners, like Flutter's `compute`.<br>- `Aside.run` for a simple task with a single return value<br>- `Aside.stream` for tasks that stream values<br>- `Aside.biStream` for full two-way communication |

## Usage

Add a package to your `pubspec.yaml` by referencing the repository path. For example:

```yaml
dependencies:
  aside:
    git:
      url: https://github.com/komposten/dart-library.git
      path: aside
      ref: <commit hash>
```
