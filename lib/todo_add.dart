import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:speech_to_text/speech_to_text.dart' as stt;

class TodoAddPage extends StatefulWidget {
  @override
  _TodoAddPageState createState() => _TodoAddPageState();
}

class _TodoAddPageState extends State<TodoAddPage> {
  String _task = '';
  int maxLen = 50;

  viewTextLen() {
    return "${_task.length}/${maxLen}";
  }

  inputTextLenValid() {
    return _task.isNotEmpty && _task.length <= maxLen;
  }

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
              const SizedBox(height: 0),
              TextField(
                onChanged: (String value) => setState(() {
                  _task = value;
                }),
                decoration: const InputDecoration(
                  hintText: "タスクを入力",
                  prefixIcon: FaIcon(
                    FontAwesomeIcons.microphoneLines,
                    size: 20,
                  ),
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.microphoneLines,
                size: 20,
              ),
              Text(
                viewTextLen(),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: inputTextLenValid()
                      ? () {
                          debugPrint(_task);
                          Navigator.of(context).pop(_task);
                        }
                      : null,
                  child:
                      const Text('追加', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ));
  }
}
