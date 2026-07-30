# todo_or_die

Write TODOs in code that ensure you actually do them.

Inspired by [searls/todo_or_die](https://github.com/searls/todo_or_die).

## Features

- Mark a TODO with a **due date** — it throws once the date passes.
- Mark a TODO with a **condition** — it throws when the condition evaluates to `true`.
- Combine both a due date and a condition — it throws only when both are met.
- **Custom alerters** — replace the default throw behavior with logging or any other action.

## Getting started

Add `todo_or_die` to your `pubspec.yaml`:

```yaml
dependencies:
  todo_or_die:
    git:
      url: https://github.com/komposten/dart-library.git
      path: todo_or_die
```

## Usage

Import the library:

```dart
import 'package:todo_or_die/todo_or_die.dart';
```

### With a due date

```dart
todoOrDie('Remove this function when new frontend is out', by: DateTime(2026, 07, 31));
```

A `TodoIsDueError` is thrown once the current date is past the given date.

### With a condition

```dart
todoOrDie('Rewrite this to scale better', given: () => userCount() >= 1000);
```

A `TodoIsDueError` is thrown when the condition evaluates to `true`.

You can provide a description of the condition using `givenDesription`:

```dart
todoOrDie(
  'Rewrite this to scale better',
  given: () => userCount() >= 1000,
  givenDesription: 'we have reached 1000 users',
);
```

When provided, the description is included in the error message and is accessible via `TodoIsDueError.given`.

### With both a date and a condition

```dart
todoOrDie('Migrate to new API', by: DateTime(2026, 08, 15), given: () => apiVersion() >= 2);
```

The error is thrown only when **both** the due date has passed **and** the condition is `true`.

You can also add a `givenDesription` here to describe the condition.

### Custom alerter

By default `todoOrDie` throws a `TodoIsDueError`. You can override this by configuring a custom alerter:

```dart
TodoOrDie.configure(
  alerter: (message, by, given) {
    final error = TodoIsDueError(message, by, given);
    if (isProduction) {
      logger.error(error);
    } else {
      throw error;
    }
  },
);
```

Reset to the default throw behavior by calling `TodoOrDie.configure()` with no arguments.

### The `TodoIsDueError` object

The error has three properties:
- `message` — the TODO message.
- `by` — the due date, or `null` if not set.
- `given` — the condition description (the value of `givenDesription`), or `null` if no condition was set.
