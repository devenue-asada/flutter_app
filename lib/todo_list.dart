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
  final FlutterLocalNotificationsPlugin _noticePlug =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FlutterAppBadger.removeBadge();
    }
  }

  Future<void> _init() async {
    await _configureLocalTimeZone();
    await _initializeNotification();
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

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
    await _noticePlug.initialize(initializationSettings);
  }

  Future<void> _cancelNotification() async {
    print("can");
    // await _noticePlug.cancelAll();
  }

  Future<void> _requestPermissions() async {
    await _noticePlug
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _registerMessage({
    required int hour,
    required int minutes,
    required message,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minutes,
    );
    print(scheduledDate);

    await _noticePlug.zonedSchedule(
      0,
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
      // body: ListView.builder(
      //   itemCount: todoList.length,
      //   itemBuilder: (context, index) {
      //     return Dismissible(
      //         key: UniqueKey(),
      //         child: Card(
      //           child: ListTile(
      //             title: Text(todoList[index]),
      //           ),
      //         ),
      //         onDismissed: (direction) {
      //           setState(() => todoList.removeAt(index));
      //         });
      //   },
      // ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>");
            await _cancelNotification();
            await _requestPermissions();

            final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
            await _registerMessage(
              hour: now.hour,
              minutes: now.minute + 1,
              message: 'Hello, world!',
            );
          },
          child: const Text('Show Notification'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => TodoAddPage()),
          );
          if (newTask == null) return;
          setState(() => todoList.insert(0, newTask.text));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
