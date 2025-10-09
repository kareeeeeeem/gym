// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// 🧩 شاشات وتنسيقات المشروع
import 'package:fitnessapp/const/const.dart';
import 'package:fitnessapp/routes.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/dashboard/camera/camera_screen.dart';
import 'package:fitnessapp/view/welcome/on_boarding/start_screen.dart';

const OneSignalAppId = 'e17ceb1e-09d4-41d4-aee4-91cdee1b1d6b';

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
// ===========================================================================
Future<void> _initializeOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(OneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
  OneSignal.User.pushSubscription.optIn();

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print("📩 Notification received: ${event.notification.jsonRepresentation()}");
    event.notification.display();
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

  // 🔍 نتحقق من المستخدم الحالي بعد تشغيل التطبيق
  Future<User?> _checkUser() async {
    await Future.delayed(const Duration(seconds: 1)); // ندي Firebase وقت يحمّل الجلسة
    return FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _checkUser(),
      builder: (context, snapshot) {
        // ⏳ أثناء تحميل الحالة
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
            ),
          );
        }

        // ✅ المستخدم مسجل دخول
        if (snapshot.hasData) {
          return MyApp(
            initialScreen: DashboardScreen(cameras: cameras),
            cameras: cameras,
          );
        }

        // ❌ المستخدم مش مسجل
        return MyApp(
          initialScreen: const StartScreen(),
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
