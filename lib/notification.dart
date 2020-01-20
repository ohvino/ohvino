import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MyNotification {

  MyNotification() {
    _flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  }

  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  init() async {
    var initializationSettingsAndroid = new AndroidInitializationSettings('ic_stat_name');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings( initializationSettingsAndroid, initializationSettingsIOS);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: _onSelectNotification);
  }

  Future _onSelectNotification(String payload) async {
  }

  sendTargetReached() async {
//    _flutterLocalNotificationsPlugin.cancelAll();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails( '2', 'OhVino', 'OhVino flutter snippets',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(  androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    String str = "И обязательно выключите термометр!";
    await _flutterLocalNotificationsPlugin.show(0, 'Выньте вино из холодильника.', str, platformChannelSpecifics,
        payload: 'item x');
  }

}