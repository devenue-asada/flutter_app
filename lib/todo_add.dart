import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TodoAddPage extends StatefulWidget {
  @override
  _TodoAddPageState createState() => _TodoAddPageState();
}

class _TodoAddPageState extends State<TodoAddPage> {
  String _task = '';
  bool isValid = false;

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
                  isValid = value.isNotEmpty;
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
                  onPressed: isValid
                      ? () {
                          debugPrint(_task);
                          Navigator.of(context).pop(_task);
                        }
                      : null,
                  child:
                      const Text('追加', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 100,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
