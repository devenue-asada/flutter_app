import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/todo_list.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('ja').then((_) => runApp(const MyTodoApp()));
}

class MyTodoApp extends StatelessWidget {
  const MyTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListPage(),
    );
  }
}
