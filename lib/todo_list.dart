import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/todo_add.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

// リスト一覧画面
class _TodoListPageState extends State<TodoListPage> {
  List<String> todoList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('TODO LIST'),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: todoList.length,
        itemBuilder: (context, index) {
          return Dismissible(
              key: UniqueKey(),
              child: Card(
                child: ListTile(
                  title: Text(todoList[index]),
                ),
              ),
              onDismissed: (direction) {
                setState(() => todoList.removeAt(index));
              });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => TodoAddPage()),
          );
          if (newTask == null) return;
          todoList.add(newTask.text);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
