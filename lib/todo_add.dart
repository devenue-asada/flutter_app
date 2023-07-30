import 'package:flutter/foundation.dart';
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
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:convert';

import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart';

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
  var tagValue = '';

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
    _init();
  }

  ValueNotifier<dynamic> result = ValueNotifier(null);

  //NFC読み取り
  void _tagRead() {
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      alertMessage: "NFCタグを近づけてください",
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          await NfcManager.instance.stopSession(errorMessage: 'error');
          return;
        } else {
          final readTag = await ndef.read();
          final uint8List = readTag.records.first.payload;
          setState(() {
            //日本語が含まれると文字化けするのでutf8でdecode、不要な開始文字を削除
            _taskController.text = utf8.decode(uint8List).substring(3);
          });
          await NfcManager.instance.stopSession();
        }
      },
      onError: (dynamic e) async {
        debugPrint('NFC error: $e');
        await NfcManager.instance.stopSession(errorMessage: 'error');
      },
    );
  }

  void _ndefWrite() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not ndef writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      NdefMessage message =
          NdefMessage([NdefRecord.createText('Hello World!')]);

      try {
        await ndef.write(message);
        result.value = 'Success to "Ndef Write"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }

  void _ndefWriteLock() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null) {
        result.value = 'Tag is not ndef';
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }

      try {
        await ndef.writeLock();
        result.value = 'Success to "Ndef Write Lock"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
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

  ScanResult? scanResult;

  final _flashOnController = TextEditingController(text: 'フラッシュ ON');
  final _flashOffController = TextEditingController(text: 'フラッシュ OFF');
  final _cancelController = TextEditingController(text: 'キャンセル');

  String readData = "";

  Future scan() async {
    // try {
    var scan = await BarcodeScanner.scan(
      options: ScanOptions(
        strings: {
          'cancel': _cancelController.text,
          'flash_on': _flashOnController.text,
          'flash_off': _flashOffController.text,
        },
      ),
    );

    // var scan = await BarcodeScanner.scan();
    print(scan.type); // The scan type (barcode, cancelled, failed)
    print(scan.rawContent); // The barcode content
    print(scan.format); // The barcode format (as enum)
    print(scan.formatNote);
    // } on PlatformException catch (e) {
    //   if (e.code == BarcodeScanner.cameraAccessDenied) {
    //     setState(() {
    //       readData = 'Camera permissions are not valid.';
    //     });
    //   } else {
    //     debugPrint(readData);
    //     setState(() => {readData = 'Unexplained error : $e'});
    //   }
    // } on FormatException {
    //   setState(() => readData =
    //       'Failed to read (I used the back button before starting the scan).');
    // } catch (e) {
    //   setState(() => readData = 'Unknown error : $e');
    // }
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
            Flexible(
              flex: 3,
              child: GridView.count(
                padding: EdgeInsets.all(4),
                crossAxisCount: 2,
                childAspectRatio: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                children: [
                  ElevatedButton(child: Text('NFC読み取り'), onPressed: _tagRead),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scan,
        tooltip: 'QR SCAN',
        child: Icon(Icons.add),
      ),
      // floatingActionButtonLocation:
      //     FloatingActionButtonLocation.miniCenterFloat,
      // floatingActionButton: AvatarGlow(
      //   endRadius: 75.0,
      //   animate: isRecording,
      //   duration: const Duration(milliseconds: 2000),
      //   glowColor: Colors.blue,
      //   repeatPauseDuration: const Duration(milliseconds: 100),
      //   showTwoGlows: true,
      //   child: GestureDetector(
      //     // 音声入力
      //     // onTap: () => {CalendarModal(context).showCalendarModal()},
      //     onTapDown: (details) async => await _speak(),
      //     onTapUp: (details) async => await _stop(),
      //     child: CircleAvatar(
      //       radius: 35,
      //       child: Icon(
      //         isRecording ? Icons.mic : Icons.mic_none,
      //         color: Colors.white,
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}
