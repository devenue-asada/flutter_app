import 'package:flutter/material.dart';
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
