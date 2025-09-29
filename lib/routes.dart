import 'package:fitnessapp/view/activity/activity_tracker/activity_tracker_screen.dart';
import 'package:fitnessapp/view/dashboard/Room/GymRoomsScreen.dart';
import 'package:fitnessapp/view/finish_workout/finish_workout_screen.dart';
import 'package:fitnessapp/view/home/notification/notification_screen.dart';
import 'package:fitnessapp/view/login/login_screen.dart';
import 'package:fitnessapp/view/on_boarding/on_boarding_screen.dart';
import 'package:fitnessapp/view/on_boarding/start_screen.dart';
import 'package:fitnessapp/view/profile/complete_profile_screen.dart';
import 'package:fitnessapp/aus/signup/signup_screen.dart' hide LoginScreen;
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:fitnessapp/view/workout_schedule_view/workout_schedule_view.dart';
import 'package:fitnessapp/view/welcome/your_goal/your_goal_screen.dart' hide YourGoalScreen;
import 'package:flutter/material.dart';

// ملاحظة مهمة: تم إزالة مسارات DashboardScreen و CameraScreen من هنا.
// يتم التعامل معهما في MyApp في ملف main.dart لضمان تمرير قائمة الكاميرات (cameras).
final Map<String, WidgetBuilder> routes = {
  // شاشات التهيئة والمقدمة
  StartScreen.routeName: (context) => const StartScreen(),
  OnBoardingScreen.routeName: (context) => const OnBoardingScreen(),
  WelcomeScreen.routeName: (context) => const WelcomeScreen(),
  YourGoalScreen.routeName: (context) => const YourGoalScreen(),

  // شاشات المصادقة (يجب التأكد من أسماء الفئات المستخدمة)
  // افتراض أن UserLoginScreen هي الفئة الصحيحة:
  UserLoginScreen.routeName: (context) => const UserLoginScreen(), 
  // افتراض أن UserSignUpScreen هي الفئة الصحيحة:
  UserSignUpScreen.routeName: (context) => const UserSignUpScreen(), 
  
  // شاشات الملف الشخصي والأنشطة
  CompleteProfileScreen.routeName: (context) => const CompleteProfileScreen(),
  NotificationScreen.routeName: (context) => const NotificationScreen(),
  ActivityTrackerScreen.routeName: (context) => const ActivityTrackerScreen(),
  WorkoutScheduleView.routeName: (context) => const WorkoutScheduleView(),
  FinishWorkoutScreen.routeName: (context) => const FinishWorkoutScreen(),
  GymRoomsScreen.routeName: (context) => const GymRoomsScreen(),

};
