import 'package:todo_or_die/src/todo_or_die_base.dart';
import 'dart:io';

void main() {
  dynamic logger;

  // Set an alerter that throws in development but logs in production
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

  todoOrDie('Clean up after next release', by: DateTime(2026, 07, 31));
}

bool get isProduction => Platform.environment['APP_ENV'] == 'production';
