// ignore_for_file: avoid_print

import 'package:fitnessapp/routes.dart';
import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/camera/camera_screen.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/welcome/on_boarding/start_screen.dart'; 
import 'package:flutter/material.dart';
// 🚀 Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
// 🔔 الإشعارات المحلية
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
// 📸 الكاميرا
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart'; 

// =========================================================================
// 1. معالج إشعارات الخلفية (FCM)
// =========================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  await saveNotificationToFirestore(message); 
}

// =========================================================================
// 2. تهيئة الإشعارات المحلية
// =========================================================================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); 

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print("Local notification payload: ${response.payload}");
    },
  );
}

void showLocalNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', 
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: android.smallIcon,
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

// =========================================================================
// 3. حفظ الإشعار في Firestore
// =========================================================================
Future<void> saveNotificationToFirestore(RemoteMessage message) async {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final String userId = currentUser?.uid ?? 'guest_user';
  
  if (currentUser == null) {
    print("Cannot save notification: User not logged in. Using default path.");
    // 💡 يمكن هنا استخدام مسار 'guest_notifications' إذا كان مسموحاً في القواعد
    // وإلا، يجب الخروج من الدالة.
    return;
  }

  final db = FirebaseFirestore.instance;

  try {
    // 🔥 التأكد من أن مسار حفظ الإشعارات لا يحتاج المسار الطويل
    // (بافتراض أن قواعد الأمان تسمح بمسار notifications/{userId}/**)
    await db.collection('notifications')
        .doc(userId)
        .collection('user_notifications') 
        .add({
          'title': message.notification?.title ?? 'إشعار جديد',
          'body': message.notification?.body ?? '',
          'image_path': message.data['image_path'] ?? 'assets/icons/default.png', 
          'time': FieldValue.serverTimestamp(), 
          'isRead': false, 
          'data': message.data, 
        });
    print("✅ Notification saved to Firestore for user: $userId");
  } catch (e) {
    print("❌ ERROR saving notification to Firestore: $e");
  }
}

// =========================================================================
// 4. تهيئة FCM
// =========================================================================
Future<void> initializeFCM() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true, announcement: false, badge: true, sound: true,
  );
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission for notifications.');
    
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
    
    // 🔥 يتم تحديث التوكن في Firestore عند تسجيل الدخول أو عند تغيير حالة المصادقة
    // (هنا لا نغير الكود، فقط للتأكيد على ضرورة حفظه في DB)

    setupFCMListeners();
  } else {
    print('User declined or has not yet granted permission.');
  }
}

void setupFCMListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    
    showLocalNotification(message);
    saveNotificationToFirestore(message); 
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from a background notification: ${message.data}');
  });

  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('App terminated message clicked: ${message.data}');
    }
  });
}

// =========================================================================
// 5. دالة main()
// =========================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final List<CameraDescription> cameras = await availableCameras();
  await initializeDateFormatting('ar', null); // أضف هذا السطر

  await Firebase.initializeApp();
  await initializeLocalNotifications();
  await initializeFCM();

  runApp(MyRootApp(cameras: cameras));
}

// =========================================================================
// 6. RootApp مع متابعة حالة تسجيل الدخول
// =========================================================================
class MyRootApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyRootApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ أثناء تحميل حالة الـ auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // ✅ لو المستخدم مسجل دخول
        if (snapshot.hasData) {
          // 🔥 هنا نضمن أن حالة المصادقة جاهزة قبل تحميل أي شاشة
          return MyApp(
            initialScreen: DashboardScreen(cameras: cameras),
            cameras: cameras,
          );
        }

        // ❌ لو مش مسجل
        return MyApp(
          initialScreen: const StartScreen(),
          cameras: cameras,
        );
      },
    );
  }
}

// =========================================================================
// 7. MyApp مع Routes والكاميرات
// =========================================================================
class MyApp extends StatelessWidget {
  final Widget initialScreen;
  final List<CameraDescription> cameras;

  const MyApp({
    super.key,
    required this.initialScreen,
    required this.cameras,
  });

  Map<String, WidgetBuilder> get _routesWithCamera => {
        ...routes,
        DashboardScreen.routeName: (context) =>
            DashboardScreen(cameras: cameras),
        CameraScreen.routeName: (context) => CameraScreen(cameras: cameras),
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness',
      debugShowCheckedModeBanner: false,
      routes: _routesWithCamera,
      theme: ThemeData(
        // تم افتراض أن AppColors.primaryColor1 متاح
        primaryColor: const Color(0xFF92A3FD), 
        useMaterial3: true,
        fontFamily: "Poppins",
      ),
      home: initialScreen,
    );
  }
}