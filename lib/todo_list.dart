import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/todo_add.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

// リスト一覧画面
class _TodoListPageState extends State<TodoListPage>
    with WidgetsBindingObserver {
  List<String> todoList = [];

  final _flnp = FlutterLocalNotificationsPlugin();

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
                color: Colors.white,
                margin: EdgeInsets.only(top: 7, left: 5, right: 5),
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
          print(newTask);
          if (newTask == null) return;
          setState(() => todoList.insert(0, newTask.text));
          print(todoList.length);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
