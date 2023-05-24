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
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_app/modules/custom_modal.dart';

//カレンダー
class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _forcusedDay = DateTime.now();
  DateTime? _selectedDay;
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  int year = 0;
  int month = 0;
  int day = 0;
  int hour = 0;

  @override
  void initState() {
    super.initState();
    year = now.year;
    month = now.month;
    day = now.day;
    hour = now.hour;
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'ja_JP',
      firstDay: now,
      lastDay: DateTime.utc(year + 10, 12, 31),
      focusedDay: now,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, forcusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _forcusedDay = forcusedDay;
          });
        }
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          // Call `setState()` when updating calendar format
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (forcusedDay) {
        _forcusedDay = forcusedDay;
      },
    );
  }
}

class CalendarModal {
  BuildContext context;
  CalendarModal(this.context) : super();

  void showCalendarModal() {
    Navigator.push(
        context,
        CustomModal(Column(children: [
          Calendar(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () => hideModal(),
              ),
              TextButton(
                child: const Text('選択'),
                onPressed: () {},
              ),
            ],
          )
        ])));
  }

  void hideModal() {
    Navigator.of(context).pop();
  }
}

class TodoAddPage extends StatefulWidget {
  @override
  _TodoAddPageState createState() => _TodoAddPageState();
}

class _TodoAddPageState extends State<TodoAddPage> with WidgetsBindingObserver {
  stt.SpeechToText speech = stt.SpeechToText();
  final _taskController = TextEditingController();
  String time = '';
  int maxLen = 300;
  String lastError = '';
  String lastStatus = '';
  bool isRecording = false;
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  int year = 0;
  int month = 0;
  int day = 0;
  int hour = 0;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _forcusedDay = DateTime.now();
  DateTime? _selectedDay;

  final _flnp = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    year = now.year;
    month = now.month;
    day = now.day;
    hour = now.hour;
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
    print("cancelAll");
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
            SizedBox(
              width: double.infinity,
              child: Text(
                viewTextLen(),
                textAlign: TextAlign.right,
              ),
            ),
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
                          final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
                          //通知時刻セット
                          print(year);
                          await _registerMessage(
                            year: now.year,
                            month: now.month,
                            day: now.day,
                            hour: now.hour,
                            minutes: now.minute + 1,
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
