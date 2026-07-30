import 'package:todo_or_die/todo_or_die.dart';

void main() {
  // with due date
  todoOrDie(
    'Remove this function when new frontend is out',
    by: DateTime(2026, 07, 31),
  );

  // with conditions
  todoOrDie(
    'Rewrite this to scale better',
    given: () => userCount() >= 1000,
    givenDesription: 'we have reached 1000 users',
  );
}

int userCount() => 0; // function to get user count
