import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyTodoApp());
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
        title: const Text('TODO一覧'),
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
          return Card(
            child: ListTile(
              title: Text(todoList[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return TodoAddPage();
            }),
          );
          if (newTask != null) todoList.add(newTask);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodoAddPage extends StatefulWidget {
  @override
  _TodoAddPageState createState() => _TodoAddPageState();
}

class _TodoAddPageState extends State<TodoAddPage> {
  String _task = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('TODO追加'),
        ),
        body: Container(
          padding: const EdgeInsets.all(70),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 8),
              TextField(
                onChanged: (String value) => setState(() {
                  debugPrint(value);
                  _task = value;
                }),
                decoration: const InputDecoration(
                  hintText: "タスクを入力",
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint(_task);
                    Navigator.of(context).pop(_task);
                  },
                  child:
                      const Text('追加', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 100,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '取り消す',
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
