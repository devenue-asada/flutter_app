import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;

class TodoAddPage extends StatefulWidget {
  @override
  _TodoAddPageState createState() => _TodoAddPageState();
}

class _TodoAddPageState extends State<TodoAddPage> with WidgetsBindingObserver {
  final _taskController = TextEditingController();
  int maxLen = 300;

  final _flnp = FlutterLocalNotificationsPlugin();

  stt.SpeechToText speech = stt.SpeechToText();
  String lastError = '';
  String lastStatus = '';
  bool isRecording = false;

  final formatter = new DateFormat('yyyy年MM月dd日(E) HH:mm', 'ja');
  int year = DateTime.now().year;
  int month = DateTime.now().month;
  int day = DateTime.now().day;
  int hour = DateTime.now().hour;
  int minute = DateTime.now().minute;
  var _initNoticeDateTime = DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().day, DateTime.now().hour + 1, DateTime.now().minute, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FlutterAppBadger.removeBadge();
    }
  }

  //初期化メソッド
  Future<void> _init() async {
    await _configureLocalTimeZone();
    await _initializeNotification();
  }

  //タイムゾーン
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  //通知初期設定
  Future<void> _initializeNotification() async {
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flnp.initialize(initializationSettings);
  }

  //通知をID単位で削除
  Future<void> _cancelNotification(id) async {
    await _flnp.cancel(id);
  }

  //通知をすべて削除
  Future<void> _cancelAllNotification() async {
    await _flnp.cancelAll();
  }

  //アラート・バッチ設定
  Future<void> _requestPermissions() async {
    await _flnp
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  //通知登録
  Future<void> _registerMessage({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minutes,
    required message,
  }) async {
    //通知済リスト取得
    final List<ActiveNotification> execList =
        await _flnp.getActiveNotifications();
    //通知済のIDを削除
    for (var item in execList) await _cancelNotification(item.id);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      year,
      month,
      day,
      hour,
      minutes,
    );

    int setId = 0;
    //通知前リスト取得
    final List<PendingNotificationRequest> waitingList =
        await _flnp.pendingNotificationRequests();
    if (waitingList.isNotEmpty) {
      //リストの最後（最大値）+1を作成するIDにセット
      waitingList.sort(((a, b) => a.id.compareTo(b.id)));
      setId = waitingList.last.id + 1;
    }

    //通知スケジュールを設定
    await _flnp.zonedSchedule(
      setId,
      'TODO APP',
      message,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel id',
          'channel name',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          styleInformation: BigTextStyleInformation(message),
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          badgeNumber: 1,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  //音声入力開始
  Future<void> _speak() async {
    setState(() => isRecording = true);
    isRecording = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    speech.listen(onResult: resultListener);
  }

  //音声入力停止
  Future<void> _stop() async {
    setState(() => isRecording = false);
    speech.stop();
  }

  //データ取得
  void resultListener(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        _taskController.text = result.recognizedWords;
      });
    }
  }

  //エラー取得
  void errorListener(SpeechRecognitionError error) {
    if (mounted) {
      setState(() => lastError = '${error.errorMsg} - ${error.permanent}');
    }
  }

  //ステータス取得
  void statusListener(String status) {
    if (mounted) {
      setState(() => lastStatus = '$status');
    }
  }

  //文字入力数表示
  viewTextLen() {
    return "${_taskController.text.length}/${maxLen}";
  }

  //文字入力制御
  inputTextLenValid() {
    return _taskController.text.isNotEmpty &&
        _taskController.text.length <= maxLen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD TODO'),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle_notifications, color: Colors.black87),
                  TextButton(
                    onPressed: () {
                      picker.DatePicker.showDateTimePicker(context,
                          showTitleActions: true,
                          minTime: DateTime(year, month, day, hour, minute),
                          maxTime: DateTime(year + 10, 12, 31, hour, minute),
                          onChanged: (date) {}, onConfirm: (date) {
                        setState(() {
                          _initNoticeDateTime = date;
                        });
                      },
                          currentTime: _initNoticeDateTime,
                          locale: picker.LocaleType.jp);
                    },
                    child: Text(
                      formatter.format(_initNoticeDateTime),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            // SizedBox(
            //   width: double.infinity,
            //   child: Text(
            //     viewTextLen(),
            //     textAlign: TextAlign.right,
            //   ),
            // ),
            TextField(
              controller: _taskController,
              onChanged: (String value) {
                setState(() {
                  _taskController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _taskController.text.length),
                  );
                });
              },
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: _taskController.text.isEmpty
                          ? Colors.grey
                          : Colors.blue),
                ),
                hintText: 'タスクを入力してください',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: isRecording ? '音声入力中...' : null,
                labelStyle: TextStyle(
                  color:
                      _taskController.text.isEmpty ? Colors.grey : Colors.blue,
                ),
                suffixIcon: IconButton(
                  // 保存
                  onPressed: inputTextLenValid()
                      ? () async {
                          // 入力値を一覧に渡す
                          Navigator.of(context).pop(_taskController);
                          // 通知処理
                          await _requestPermissions();
                          //通知時刻セット
                          await _registerMessage(
                            year: _initNoticeDateTime.year,
                            month: _initNoticeDateTime.month,
                            day: _initNoticeDateTime.day,
                            hour: _initNoticeDateTime.hour,
                            minutes: _initNoticeDateTime.minute,
                            message: '${_taskController.text}',
                          );
                        }
                      : null,
                  icon: Icon(Icons.done,
                      color: _taskController.text.isNotEmpty
                          ? Colors.green
                          : Colors.grey),
                ),
                border: const OutlineInputBorder(),
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
          // 音声入力
          // onTap: () => {CalendarModal(context).showCalendarModal()},
          onTapDown: (details) async => await _speak(),
          onTapUp: (details) async => await _stop(),
          child: CircleAvatar(
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
