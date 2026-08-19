# dart-library

A collection of small Dart snippets and scripts provided as reusable packages.

All code in this library is cross-platform and works on both the Dart VM and on web. It is also fully self-contained, with none of the packages defined here using any third-party dependencies (including no dependencies to other packages defined in this repo).

<sub>**AI disclaimer:** Some of these packages contain AI-generated or AI-assisted code. See the README.md files for the individual packages for more details. All AI-generated code has been audited, tested and often rewritten by me (@Komposten).</sub>

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
