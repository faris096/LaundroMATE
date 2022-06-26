// ignore_for_file: avoid_function_literals_in_foreach_calls, unused_import

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'settings.dart';
import 'main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'globals.dart' as globals;

String _start = '';
String _end = '';

class BookingDetails extends StatelessWidget {
  const BookingDetails({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromRGBO(0, 74, 173, 2),
        body: Center(
            child: Column(children: <Widget>[
          // ignore: avoid_unnecessary_containers
          Container(child: const Image(image: AssetImage('assets/logo.png'))),
          const SizedBox(width: 280.0, height: 50.0),
        ])));
  }
}

//get appts from the database
class LoadDataFromFireBase extends StatelessWidget {
  const LoadDataFromFireBase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      //debugShowCheckedModeBanner: false,
      //title: 'FireBase',
      body: LoadDataFromFireStore(),
    );
  }
}

class LoadDataFromFireStore extends StatefulWidget {
  const LoadDataFromFireStore({Key? key}) : super(key: key);

  @override
  LoadDataFromFireStoreState createState() => LoadDataFromFireStoreState();
}

class LoadDataFromFireStoreState extends State<LoadDataFromFireStore> {
  final List<Color> _colorCollection = <Color>[];
  MeetingDataSource? events;
  //final List<String> options = <String>['Add', 'Delete', 'Update'];
  final fireStoreReference = FirebaseFirestore.instance;
  bool isInitialLoaded = false;

  final CalendarController _controller = CalendarController();

  @override
  void initState() {
    _initializeEventColor();
    getDataFromFireStore().then((results) {
      SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
        setState(() {});
      });
    });
    fireStoreReference.collection('RC4').snapshots().listen((event) {
      event.docChanges.forEach((element) {
        if (element.type == DocumentChangeType.added) {
          if (!isInitialLoaded) {
            return;
          }

          final Random random = Random();
          Meeting app = Meeting.fromFireBaseSnapShotData(
              element, _colorCollection[random.nextInt(9)]);
          setState(() {
            events!.appointments!.add(app);
            events!.notifyListeners(CalendarDataSourceAction.add, [app]);
          });
        } else if (element.type == DocumentChangeType.modified) {
          if (!isInitialLoaded) {
            return;
          }

          final Random random = Random();
          Meeting app = Meeting.fromFireBaseSnapShotData(
              element, _colorCollection[random.nextInt(9)]);
          setState(() {
            int index = events!.appointments!
                .indexWhere((app) => app.key == element.doc.id);

            Meeting meeting = events!.appointments![index];

            events!.appointments!.remove(meeting);
            events!.notifyListeners(CalendarDataSourceAction.remove, [meeting]);
            events!.appointments!.add(app);
            events!.notifyListeners(CalendarDataSourceAction.add, [app]);
          });
        } else if (element.type == DocumentChangeType.removed) {
          if (!isInitialLoaded) {
            return;
          }

          setState(() {
            int index = events!.appointments!
                .indexWhere((app) => app.key == element.doc.id);

            Meeting meeting = events!.appointments![index];
            events!.appointments!.remove(meeting);
            events!.notifyListeners(CalendarDataSourceAction.remove, [meeting]);
          });
        }
      });
    });
    super.initState();
  }

  Future<void> getDataFromFireStore() async {
    var snapShotsValue = await fireStoreReference.collection('RC4').get();

    final Random random = Random();
    List<Meeting> list = snapShotsValue.docs
        .map((e) => Meeting(
            eventName: e.data()['Subject'],
            from:
                DateFormat('dd/MM/yyyy HH:mm:ss').parse(e.data()['StartTime']),
            to: DateFormat('dd/MM/yyyy HH:mm:ss').parse(e.data()['EndTime']),
            background: _colorCollection[random.nextInt(9)],
            isAllDay: false,
            key: e.id))
        .toList();
    setState(() {
      events = MeetingDataSource(list);
    });
  }

  _goBack(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    //isInitialLoaded = true;
    DateTime now = DateTime.now();
    String _text = DateFormat('dd/MM/yyyy HH:m:00').format(now);

    void selectionChanged(CalendarSelectionDetails details) {
      //DateTime dt;
      if (_controller.view == CalendarView.month ||
          _controller.view == CalendarView.timelineMonth) {
        _text = DateFormat('dd/MM/yyyy HH:mm:00').format(details.date!);
      } else {
        _text = DateFormat('dd/MM/yyyy HH:mm:00').format(details.date!);
      }
      DateTime later = details.date!.add(const Duration(hours: 1));
      _start = DateFormat('dd/MM/yyyy HH:mm:00').format(details.date!);
      _end = DateFormat('dd/MM/yyyy HH:mm:00').format(later);
    }

    //DateTime now1 = DateTime.parse('_text');

    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 20.0,
              onPressed: () {
                _goBack(context);
              },
            ),
            title: const Text('B O O K I N G'),
            backgroundColor: const Color.fromRGBO(0, 74, 173, 2)),
        body: SfCalendar(
            view: CalendarView.week,
            dataSource: events,
            onSelectionChanged: selectionChanged,
            allowedViews: const [
              CalendarView.week,
              CalendarView.day,
              CalendarView.month,
            ],
            viewNavigationMode: ViewNavigationMode.snap,
            showDatePickerButton: true,
            showNavigationArrow: true,
            allowViewNavigation: true,
            headerStyle: const CalendarHeaderStyle(textAlign: TextAlign.center),
            viewHeaderStyle: const ViewHeaderStyle(
                backgroundColor: Color.fromARGB(253, 255, 255, 255)),
            controller: _controller,
            onTap: calendarTapped),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              const SizedBox(
                height: 550,
              ),

              //Refresh Calendar Button
              FloatingActionButton(
                backgroundColor: const Color.fromRGBO(0, 74, 173, 2),
                onPressed: () {
                  getDataFromFireStore();
                },
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(
                height: 10,
              ),

              //Add Appointment Button
              FloatingActionButton(
                  backgroundColor: const Color.fromRGBO(0, 74, 173, 2),
                  onPressed: () {
                    fireStoreReference.collection('RC4').doc(telegram).set(
                        {'Subject': name, 'StartTime': _text, 'EndTime': _end});

                    getDataFromFireStore();
                  },
                  child: const Icon(Icons.add)),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ));
  }

  void delete(String name, String telegram) {
    fireStoreReference.collection('RC4').doc(telegram).delete();
  }

  void deleteStatus(String name, String telegram) {
    fireStoreReference.collection('LaundryRC4').doc('status').delete();
  }

  checkIfDocExists() async {
    DocumentSnapshot ds =
        await fireStoreReference.collection('LaundryRC4').doc('status').get();
    globals.status = ds.get('status');
    if (globals.status == 1) {
      fireStoreReference
          .collection('LaundryRC4')
          .doc('status')
          .set({'status': 0});
      globals.wmPath = 'assets/wm_green.png';
      globals.dPath = 'assets/dryer_red.png';
    }
    if (globals.status == 0) {
      fireStoreReference
          .collection('LaundryRC4')
          .doc('status')
          .set({'status': 1});
      globals.wmPath = 'assets/wm_red.png';
      globals.dPath = 'assets/dryer_green.png';
    }
    // var data = ds.data();
    // if (data['status'] == 1) {
    //   return true;
    // }
    // if (ds.exists == false) {
    //   return false;
    // }
  }

  //CALENDAR TAPPED FOR CONTACT
  void calendarTapped(CalendarTapDetails details) async {
    if (details.targetElement == CalendarElement.appointment ||
        details.targetElement == CalendarElement.agenda) {
      //check if the appointment is yours
      if (true) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: const Text('Options:'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      launchUrl(Uri.parse("https://t.me/$telegram"));

                      Navigator.of(context).pop();
                    },
                    child: Text('Message $name'),
                  ),
                  TextButton(
                    onPressed: () {
                      delete(name, telegram);
                      Navigator.of(context).pop();
                      getDataFromFireStore();
                    },
                    child: const Text('Delete Appointment'),
                  ),
                  TextButton(
                    onPressed: () {
                      checkIfDocExists();
                      Navigator.of(context).pop();
                      getDataFromFireStore();
                    },
                    child: const Text('Started/Finished'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            });
      }
    }
  }

  void _initializeEventColor() {
    _colorCollection.add(const Color(0xFF0F8644));
    _colorCollection.add(const Color(0xFF8B1FA9));
    _colorCollection.add(const Color(0xFFD20100));
    _colorCollection.add(const Color(0xFFFC571D));
    _colorCollection.add(const Color(0xFF36B37B));
    _colorCollection.add(const Color(0xFF01A1EF));
    _colorCollection.add(const Color(0xFF3D4FB5));
    _colorCollection.add(const Color(0xFFE47C73));
    _colorCollection.add(const Color(0xFF636363));
    _colorCollection.add(const Color(0xFF0A8043));
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }
}

class Meeting {
  String? eventName;
  DateTime? from;
  DateTime? to;
  Color? background;
  bool? isAllDay;
  String? key;

  Meeting(
      {this.eventName,
      this.from,
      this.to,
      this.background,
      this.isAllDay,
      this.key});

  static Meeting fromFireBaseSnapShotData(dynamic element, Color color) {
    return Meeting(
        eventName: element.doc.data()!['Subject'],
        from: DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(element.doc.data()!['StartTime']),
        to: DateFormat('dd/MM/yyyy HH:mm:ss')
            .parse(element.doc.data()!['EndTime']),
        background: color,
        isAllDay: false,
        key: element.doc.id);
  }
}
