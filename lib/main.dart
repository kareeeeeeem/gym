// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:fitnessapp/view/dashboard/home/notification/notification_screen.dart';
import 'package:fitnessapp/const/complete_profile_screen.dart' hide DashboardScreen;
import 'package:fitnessapp/view/dashboard/profile/Profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🧩 شاشات وتنسيقات المشروع
import 'package:fitnessapp/routes.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/dashboard/camera/camera_screen.dart';
import 'package:fitnessapp/view/welcome/on_boarding/start_screen.dart';

const OneSignalAppId = 'e17ceb1e-09d4-41d4-aee4-91cdee1b1d6b';

// 👀 notifier مشترك
final notificationsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase
  await Firebase.initializeApp();

  // ⏱️ إعدادات اللغة
  await initializeDateFormatting('ar', null);

  // 🎥 الكاميرا
  final cameras = await availableCameras();

  // 🔔 تهيئة OneSignal
  await _initializeOneSignal();

  // 🚀 شغّل التطبيق
  runApp(MyRootApp(cameras: cameras));
}

// ===========================================================================
// 🔔 OneSignal
// ===========================================================================// main.dart (التعديلات في دالة _initializeOneSignal)
// main.dart (التعديل النهائي في دالة _initializeOneSignal)
// main.dart (التعديل النهائي والكامل في دالة _initializeOneSignal)

Future<void> _initializeOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(OneSignalAppId);
  await OneSignal.Notifications.requestPermission(true);
  OneSignal.User.pushSubscription.optIn();

  final prefs = await SharedPreferences.getInstance();
  final String? savedString = prefs.getString('saved_notifications');

  // 🔥🔥 الحل النهائي لضمان حالة القراءة (isRead) أثناء التحميل 🔥🔥
  if (savedString != null) {
    List<dynamic> loadedList = jsonDecode(savedString);
    List<Map<String, dynamic>> finalLoadedList = loadedList.map((notif) {
      if (notif is Map<String, dynamic>) {
        return {
          "title": notif["title"] ?? "No title",
          "body": notif["body"] ?? "No message",
          "time": notif["time"] ?? DateTime.now().toIso8601String(),
          // 💡 التحقق الصارم: إذا لم يكن isRead موجوداً أو كان null، نعتبره TRUE (مقروء)
          "isRead": (notif.containsKey("isRead") && notif["isRead"] is bool) ? notif["isRead"] : true,
        };
      }
      return null; // تجاهل العناصر غير السليمة
    }).where((n) => n != null).cast<Map<String, dynamic>>().toList();
    
    // تحديث القائمة العامة بحالة القراءة الصحيحة
    notificationsNotifier.value = finalLoadedList;
    
    // تحديث العداد بناءً على القائمة المحملة
    await prefs.setInt('unread_count', finalLoadedList.where((n) => n["isRead"] == false).length);
  }
  // 🔥🔥 نهاية قسم التحميل 🔥🔥
  
  // عند استقبال إشعار أثناء عمل التطبيق (نحتفظ بالتعديل الذي يمنع التضارب)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) async {
    final notif = event.notification;
    final newNotif = {
      "title": notif.title ?? "No title",
      "body": notif.body ?? "No message",
      "time": DateTime.now().toIso8601String(),
      "isRead": false, // الإشعار الجديد دائماً غير مقروء
    };

    // نأخذ نسخة ثابتة من القائمة الحالية التي تحمل isRead الصحيح
    final currentNotifications = notificationsNotifier.value;
    
    // تحديث الـ ValueNotifier أولاً
    notificationsNotifier.value = [newNotif, ...currentNotifications]; 

    // حفظ القائمة المحدثة بالكامل بعد التعديل
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notifications', jsonEncode(notificationsNotifier.value));
    
    // عد الإشعارات التي isRead فيها false
    await prefs.setInt('unread_count', notificationsNotifier.value.where((n) => n["isRead"] == false).length);

    event.notification.display();
    print("📩 Notification received: $newNotif");
  });

  OneSignal.Notifications.addClickListener((event) {
    print("🔔 Notification clicked: ${event.notification.jsonRepresentation()}");
  });

  print("✅ OneSignal initialized successfully!");
}
// ===========================================================================
// 🏁 Root App
// ===========================================================================
class MyRootApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyRootApp({super.key, required this.cameras});

  Future<User?> _checkUser() async {
    await Future.delayed(const Duration(seconds: 1));
    return FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _checkUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
            ),
          );
        }

        final initialScreen = snapshot.hasData
            ? DashboardScreen(cameras: cameras)
            : const StartScreen();


       // final initialScreen = const UserProfile();




        return MyApp(
          initialScreen: initialScreen,
          cameras: cameras,
        );
      },
    );
  }
}

// ===========================================================================
// 🎨 App
// ===========================================================================
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
        DashboardScreen.routeName: (context) => DashboardScreen(cameras: cameras),
        CameraScreen.routeName: (context) => CameraScreen(cameras: cameras),
        NotificationsPage.routeName: (context) => const NotificationsPage(),
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      routes: _routesWithCamera,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF92A3FD),
        useMaterial3: true,
        fontFamily: "Poppins",
      ),
      home: initialScreen,
    );
  }
}
