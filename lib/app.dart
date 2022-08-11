import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:testnotify/home.dart';
import 'package:testnotify/main.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Push Notification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes:{
        '/': ((context) => MyHomePage(title: 'Flutter Push Notification')),
        '/second':(context) => const SencondPage(title: '',content: ''),
      } ,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<void> _sendAnalyticsEvent(String eventName, String id) async {
    if (eventName != ''){
      if (id != ''){
        await MyApp.analytics.logEvent(
          name: eventName,
          parameters: <String, dynamic>{
            'id': id, 
          },
        );        
      }
      else{
        await MyApp.analytics.logEvent(
          name: eventName,
          parameters: <String, dynamic>{
            'id': 0, 
          },
        );  
      }
    }
    else{
      await MyApp.analytics.logEvent(
        name: 'click_open',
      );  
    }
    print('log event');
  }
  
  

  @override
  void initState() async{
    super.initState();
    var initializationSettingsAndroid =
       const AndroidInitializationSettings('@mipmap/ic_launcher');
    InitializationSettings initializationSettings = InitializationSettings(
       android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification );

    await MyApp.analytics.logEvent(
      name: 'click_open',
    );   
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      print('message : ${message.messageId}');
      if (notification != null && android != null) {
        print('channel name 1: ${channel.name} ');
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ));
      }
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('terminated');
      RemoteNotification? notification = message?.notification;
      AndroidNotification? android = message?.notification?.android;
      if (notification != null && android != null) {
        Navigator.push(
          navigatorKey.currentState!.context,
          MaterialPageRoute(
            builder: (context) => const SencondPage(title: '',content: '',),
          ),
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async{
      print('A new messageopen app event was published');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      Map<String, dynamic>? data = message.data;
      print('data notify: $data');
      if (notification != null && android != null) {
        if (data.isEmpty){
          print('background null');
          _sendAnalyticsEvent('', '');
        }
        else if(!data.containsKey('id')){
          _sendAnalyticsEvent(message.data['eventName'].toString(), '');
        }
        else{
          _sendAnalyticsEvent(message.data['eventName'].toString(),message.data['id'].toString());
        }
        Navigator.push(navigatorKey.currentState!.context,MaterialPageRoute(
        builder: (context) =>
             SencondPage(title: notification.title,content: notification.body)),);
      }
    });
    getToken();
  }

  void getToken() async{
    final token= await FirebaseMessaging.instance.getToken();
    print('get token: $token');
  }

  void onSelectNotification(String? abc){
    try{
      print('navi to aaaaa');
      _sendAnalyticsEvent('','');
      Navigator.push(navigatorKey.currentContext!,MaterialPageRoute(builder: (((context) => MyHomePage(title: 'aaaa')))));
    }
    catch(e) {
      print('e');
    }
  }
  void showNotification() {
    setState(() {
      _counter++;
    });
    print('channel name 2: ${channel.name} ');
    flutterLocalNotificationsPlugin.show(
        0,
        "Testing $_counter",
        "This is an Flutter Push Notification",
        NotificationDetails(
            android: AndroidNotificationDetails(
                channel.id, channel.name, channelDescription : channel.description,
                importance: Importance.high,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher')));
  }
  void naviToSencond(){
    Navigator.pushNamed(context, '/second');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  <Widget>[
            const Text(
              'This is Flutter Push Notification Example',
            ),
            ElevatedButton(
              onPressed: () async {
                await MyApp.fiam.triggerEvent('click_open');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Triggering event: click_open'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(primary: Colors.blue),
              child: Text(
                'Programmatic Triggers'.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(onPressed: naviToSencond, 
            child: const Text('go to second page'))
            // Text(
            //   '$_counter',
            //   style: Theme.of(context).textTheme.headline4,
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showNotification,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}