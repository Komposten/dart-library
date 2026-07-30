typedef TodoAlerter =
    void Function(String message, DateTime? by, bool Function()? given);

class TodoIsDueError extends Error {
  final String message;
  final DateTime? by;
  final bool Function()? given;

  TodoIsDueError(this.message, this.by, this.given);

  @override
  String toString() {
    var string = 'TODO: "$message"';
    if (by != null) {
      string += ' came due on $by';
    }
    if (given != null) {
      string += ' after additional conditions were met';
    }
    return string;
  }
}

void _defaultAlerter(String message, DateTime? by, bool Function()? given) {
  throw TodoIsDueError(message, by, given);
}

TodoAlerter _alerter = _defaultAlerter;

class TodoOrDie {
  TodoOrDie._();

  static void configure({TodoAlerter alerter = _defaultAlerter}) {
    _alerter = alerter;
  }
}

void todoOrDie(String message, {DateTime? by, bool Function()? given}) {
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
    _alerter(message, by, given);
  }
}
