import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:service_provider/secrets.dart'; // Your service account JSON

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  BuildContext? _context;

  // Initialize the notification service for foreground use
  Future<void> initialize(BuildContext context) async {
    _context = context;

    // Request notification permission
    await _firebaseMessaging.requestPermission();

    // Configure foreground notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated notifications when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Local notification initialization for foreground
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);
    await _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _navigateToScreen(response.payload!);
        }
      },
    );
  }

  // Register FCM token for a user/provider/admin
  Future<void> registerFCMToken(String userId, String role) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection(role == 'user'
            ? 'users'
            : role == 'provider'
            ? 'providers'
            : 'admins')
            .doc(userId)
            .set({'fcmToken': token}, SetOptions(merge: true));
        print('$role FCM Token registered: $token');

        // Handle token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          await FirebaseFirestore.instance
              .collection(role == 'user'
              ? 'users'
              : role == 'provider'
              ? 'providers'
              : 'admins')
              .doc(userId)
              .set({'fcmToken': newToken}, SetOptions(merge: true));
          print('$role FCM Token refreshed: $newToken');
        });
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  // Send notification dynamically based on role and type
  Future<void> sendNotification({
    required String toUserId,
    required String toRole, // 'user', 'provider', 'admin'
    required String title,
    required String body,
    required String type, // e.g., 'chat', 'booking', 'service_request'
    Map<String, String>? data,
  }) async {
    try {
      // Fetch recipient's FCM token
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(toRole == 'user'
          ? 'users'
          : toRole == 'provider'
          ? 'providers'
          : 'admins')
          .doc(toUserId)
          .get();
      String? fcmToken = doc['fcmToken'];

      if (fcmToken == null) {
        print('No FCM token found for $toRole: $toUserId');
        return;
      }

      // Get OAuth 2.0 access token
      final serviceAccount = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final client = await clientViaServiceAccount(
        serviceAccount,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );
      final accessToken = client.credentials.accessToken.data;
      client.close();

      // FCM V1 API endpoint
      final Uri url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/service-provider-7bf81/messages:send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'type': type,
              ...?data, // Additional data (e.g., bookingId, chatId)
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent to $toRole ($toUserId): $title');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Handle foreground notifications
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground notification: ${message.notification?.title}');
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          // Background color is set by ProviderTheme.snackBarTheme (Primary #060644)
          content: Text(
            '${message.notification?.title}: ${message.notification?.body}',
            // Text color is set by ProviderTheme.snackBarTheme.contentTextStyle (On Primary Text #FFFFFF)
          ),
          action: SnackBarAction(
            label: 'View',
            // Text color is set by ProviderTheme.snackBarTheme.actionTextColor (Accent #FFD700)
            onPressed: () => _handleMessage(message),
          ),
        ),
      );
    }
    _showLocalNotification(message); // Also show as local notification
  }

  // Handle message when app is opened from notification
  void _handleMessageOpened(RemoteMessage message) {
    _handleMessage(message);
  }

  // Handle message routing based on type
  void _handleMessage(RemoteMessage message) {
    String? type = message.data['type'];
    String? payload = message.data['bookingId'] ?? message.data['chatId'];
    if (type != null && payload != null) {
      _navigateToScreen('$type|$payload');
    }
  }

  // Show local notification for foreground use (instance method)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'For important notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'You have a new message',
      details,
      payload: '${message.data['type']}|${message.data['bookingId'] ?? message.data['chatId']}',
    );
  }

  // Static method for background notifications
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    // Initialize for background use
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);
    await localNotificationsPlugin.initialize(settings);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'For important notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await localNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'You have a new message',
      details,
      payload: '${message.data['type']}|${message.data['bookingId'] ?? message.data['chatId']}',
    );
  }

  // Navigate to appropriate screen based on notification type
  void _navigateToScreen(String payload) {
    if (_context == null) return;
    final parts = payload.split('|');
    final type = parts[0];
    final id = parts.length > 1 ? parts[1] : null;

    switch (type) {
      case 'booking':
        Navigator.pushNamed(_context!, '/providerBooking', arguments: id);
        break;
      case 'chat':
        Navigator.pushNamed(_context!, '/chat', arguments: id);
        break;
      case 'service_request':
        Navigator.pushNamed(_context!, '/serviceRequests', arguments: id);
        break;
    // Add more cases as needed
    }
  }
}