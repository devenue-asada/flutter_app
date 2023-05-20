import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';

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
      setState(() {
        _task.text = result.recognizedWords;
      });
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
        title: const Text('ADD TODO'),
      ),
      body: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _task,
              onChanged: (String value) => setState(() => _task.text = value),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color:
                          _task.text.length == 0 ? Colors.grey : Colors.blue),
                ),
                hintText: 'タスクを入力してください',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: isRecording ? '音声入力中...' : null,
                suffixIcon: IconButton(
                  onPressed: inputTextLenValid()
                      ? () => Navigator.of(context).pop(_task)
                      : null,
                  icon: Icon(Icons.done,
                      color:
                          _task.text.isNotEmpty ? Colors.green : Colors.grey),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Text(
                viewTextLen(),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: AvatarGlow(
        endRadius: 75.0,
        animate: isRecording,
        duration: const Duration(milliseconds: 2000),
        glowColor: Colors.blue,
        repeatPauseDuration: const Duration(milliseconds: 100),
        showTwoGlows: true,
        child: GestureDetector(
          onTapDown: (details) async => await _speak(),
          onTapUp: (details) async => await _stop(),
          child: CircleAvatar(
            // backgroundColor: Colors.blue,
            radius: 35,
            child: Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
