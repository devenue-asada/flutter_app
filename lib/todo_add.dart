import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TodoAddPage extends StatefulWidget {
  @override
  _TodoAddPageState createState() => _TodoAddPageState();
}

class _TodoAddPageState extends State<TodoAddPage> {
  stt.SpeechToText speech = stt.SpeechToText();
  final _task = TextEditingController();
  String time = '';
  int maxLen = 100;
  String lastError = '';
  String lastStatus = '';
  bool isRecording = false;

  viewTextLen() {
    return "${_task.text.length}/${maxLen}";
  }

  inputTextLenValid() {
    return _task.text.isNotEmpty && _task.text.length <= maxLen;
  }

  Future<void> _speak() async {
    setState(() => isRecording = true);
    isRecording = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    speech.listen(onResult: resultListener);
  }

  Future<void> _stop() async {
    setState(() => isRecording = false);
    speech.stop();
  }

  void resultListener(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() => _task.text = result.recognizedWords);
    }
  }

  void errorListener(SpeechRecognitionError error) {
    if (mounted) {
      setState(() => lastError = '${error.errorMsg} - ${error.permanent}');
    }
  }

  void statusListener(String status) {
    if (mounted) {
      setState(() => lastStatus = '$status');
    }
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
                controller: _task,
                onChanged: (String value) => setState(() => _task.text = value),
                decoration: InputDecoration(
                  hintText: 'タスクを入力',
                  prefixIcon: IconButton(
                      onPressed: () => isRecording ? _stop() : _speak(),
                      icon: Icon(isRecording ? Icons.mic : Icons.mic_none,
                          size: isRecording ? 26 : 24,
                          color: isRecording ? Colors.blue : Colors.blue)),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _task.clear();
                      setState(() {
                        _task.text = "";
                        isRecording = false;
                      });
                    },
                    icon: Icon(Icons.clear,
                        color:
                            _task.text.isNotEmpty ? Colors.blue : Colors.grey),
                  ),
                  border: const OutlineInputBorder(),
                ),
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
                      ? () => Navigator.of(context).pop(_task)
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
