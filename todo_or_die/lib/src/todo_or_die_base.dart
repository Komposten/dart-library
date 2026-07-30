typedef TodoAlerter =
    void Function(String message, DateTime? by, String? given);

class TodoIsDueError extends Error {
  final String message;
  final DateTime? by;
  final String? given;

  TodoIsDueError(this.message, this.by, this.given);

  @override
  String toString() {
    var string = 'TODO: "$message"';
    if (by != null) {
      if (given != null) {
        string += ' is due since $by has passed and $given';
      } else {
        string += ' came due on $by';
      }
    } else if (given != null) {
      string += ' is due since $given';
    }
    return string;
  }
}

void _defaultAlerter(String message, DateTime? by, String? given) {
  throw TodoIsDueError(message, by, given);
}

TodoAlerter _alerter = _defaultAlerter;

class TodoOrDie {
  TodoOrDie._();

  /// Update the global configuration for TodoOrDie
  ///
  /// Set [alerter] to add custom handling for todos that come due
  static void configure({TodoAlerter alerter = _defaultAlerter}) {
    _alerter = alerter;
  }
}

/// Triggers an alert when a TODO has come due.
///
/// If [by] is provided, the TODO is due when the current time has passed [by].
/// If [given] is provided, the TODO is due when the predicate returns `true`.
/// When both are provided, both conditions must be met.
/// When neither is provided, the TODO is immediately due.
///
/// By default, throws a [TodoIsDueError]. Use [TodoOrDie.configure] to
/// customize the alert behavior.
void todoOrDie(
  String message, {
  DateTime? by,
  bool Function()? given,
  String givenDesription = 'conditions are met',
}) {
  bool activate = false;

  if (by == null) {
    activate = given == null ? true : given();
  } else {
    activate = by.isBefore(DateTime.now());
    if (given != null) {
      activate &= given();
    }
  }

  if (activate) {
    _alerter(message, by, given != null ? givenDesription : null);
  }
}
