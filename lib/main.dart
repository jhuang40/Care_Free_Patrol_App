import 'package:flutter/material.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'dart:async';

import 'package:pedometer/pedometer.dart';

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TwilioFlutter _twilioFlutter;
  Stream<StepCount> _stepCountStream;
  Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '0';
  int goal = 5000;
  String phoneNumber = 'Phone number not yet set';
  final myGoalController = TextEditingController();
  final myPhoneNumberController = TextEditingController();
  final oneDayCountDown = const Duration(hours:10);
  int total = 0;
  int display = 0;

  @override
  void initState() {
    super.initState();
    _twilioFlutter = TwilioFlutter(
        accountSid: '*****************************',
        authToken: '******************************',
        twilioNumber: '***********');
    initPlatformState();
  }

  void sendSmsExceeded() async {
    _twilioFlutter.sendSMS(
        toNumber: phoneNumber, messageBody: 'Steps has been exceeded');
  }

  void sendSmsNotExceeded() async {
    _twilioFlutter.sendSMS(
        toNumber: phoneNumber, messageBody: 'Steps has not been exceeded');
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _steps = event.steps.toString();
      display = int.parse(_steps) - total;;
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void checkSteps() {
    if (display >= goal) {
      sendSmsExceeded();
      setState(() {
        new Timer(oneDayCountDown, () => checkSteps());
        total = int.parse(_steps);
      });
    } else {
      sendSmsNotExceeded();
      setState(() {
        new Timer(oneDayCountDown, () => checkSteps());
        total = int.parse(_steps);
      });
    }
  }


  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Steps taken:',
                style: TextStyle(fontSize: 25),
              ),
              Text(
                display.toString(),
                style: TextStyle(fontSize: 40),
              ),
              Text(
                'Steps goal:',
                style: TextStyle(fontSize: 25),
              ),
              Text(
                goal.toString(),
                style: TextStyle(fontSize: 40),
              ),
              Text(
                'Current contact',
                style: TextStyle(fontSize: 25),
              ),
              Text(
                phoneNumber,
                style: TextStyle(fontSize: 15),
              ),
              TextField(
                controller: myGoalController,
                decoration: InputDecoration(
                  labelText: 'Step Goal',
                ),
              ),
              TextField(
                controller: myPhoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                ),
              ),
            ],
          ),
        ),
          floatingActionButton: FloatingActionButton.extended(
          // When the user presses the button, show an alert dialog containing
          // the text that the user has entered into the text field.
          onPressed: () {
            setState(() {
              goal = int.parse(myGoalController.text);
              phoneNumber = myPhoneNumberController.text;
              new Timer(oneDayCountDown, () => checkSteps());
              total = int.parse(_steps);
              display = int.parse(_steps) - total;
            });
    },
    label: Text('Save'),
          )
      ),
    );
  }
}