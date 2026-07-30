## 1.1.0

- Added `givenDesription` parameter to `todoOrDie()` for describing the condition.
- Updated `given` field in `TodoIsDueError` to expose the condition description if a condition was provided.
- Updated `TodoAlerter` typedef to include a `String? given` parameter instead of the condition function.

## 1.0.0

- Added `TodoOrDie.configure`
- Added `todoOrDie(message, by, given)`
- Added `TodoIsDueError`
