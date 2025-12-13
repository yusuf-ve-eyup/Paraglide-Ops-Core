import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

const String channelId = 'retriever_ops_location_channel';
const String channelName = 'Location Tracking';
const int notificationId = 888;

// Entry point for the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. Initialize Flutter Bindings and Firebase
  DartPluginRegistrant.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final serviceInstance = service as AndroidServiceInstance;

  // 2. Initialize Local Notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: 'This channel is used for location tracking notifications.',
    importance: Importance.low, 
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await serviceInstance.setAsForegroundService();
  
  flutterLocalNotificationsPlugin.show(
    notificationId,
    'Retrieval Ops',
    'Sharing location...',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
      ),
    ),
  );

  // 4. Retrieve User Context
  final prefs = await SharedPreferences.getInstance();
  final groupId = prefs.getString('groupId');
  final userId = prefs.getString('userId');

  if (groupId == null || userId == null) {
    service.stopSelf();
    return;
  }

  // Path: groups/$groupId/retrievers/$userId
  final dbRef = FirebaseDatabase.instance.ref('groups/$groupId/retrievers/$userId');

  // 5. Listen to Stop Command
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // CRITICAL FIXES FOR "WAITING FOR GPS":
  // A. Try to get the current position immediately once to update UI faster
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _updateLocation(service, dbRef, flutterLocalNotificationsPlugin, position);
  } catch (e) {
    // If getting current position fails (e.g. timeout), we just rely on stream
    print('Initial position failed: $e');
  }

  // B. More robust LocationSettings
  late LocationSettings locationSettings;

  if (defaultTargetPlatform == TargetPlatform.android) {
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      forceLocationManager: true, 
      intervalDuration: const Duration(seconds: 10),
    );
  } else {
    locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }

  Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) {
    _updateLocation(service, dbRef, flutterLocalNotificationsPlugin, position);
  }, onError: (e) {
    service.invoke('error', {'message': e.toString()});
  });
}

// Helper to avoid duplication
void _updateLocation(
    ServiceInstance service,
    DatabaseReference dbRef,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    Position position) {
  
  flutterLocalNotificationsPlugin.show(
    notificationId,
    'Retrieval Ops',
    'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
        onlyAlertOnce: true,
      ),
    ),
  );

  dbRef.update({
    'locationX': position.latitude,
    'locationY': position.longitude,
    'timeStamp': ServerValue.timestamp,
  });

  service.invoke(
    'update',
    {
      'lat': position.latitude,
      'lng': position.longitude,
    },
  );
}

class LocationService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'This channel is used for location tracking notifications.',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId, 
        initialNotificationTitle: 'Retrieval Ops',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onStartServiceIos,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onStartServiceIos(ServiceInstance service) async {
    return true;
  }
}
