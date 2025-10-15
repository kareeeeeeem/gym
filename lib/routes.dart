import 'package:fitnessapp/view/dashboard/activity/WorkoutLogPage.dart';
import 'package:fitnessapp/view/dashboard/Room/GymRoomsScreen.dart';
import 'package:fitnessapp/view/dashboard/home/notification/notification_screen.dart';
import 'package:fitnessapp/aus/login/login_screen.dart';
import 'package:fitnessapp/view/welcome/on_boarding/on_boarding_screen.dart';
import 'package:fitnessapp/view/welcome/on_boarding/start_screen.dart';
import 'package:fitnessapp/view/dashboard/profile/complete_profile_screen.dart';
import 'package:fitnessapp/aus/signup/signup_screen.dart' hide LoginScreen;
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';

final Map<String, WidgetBuilder> routes = {
  StartScreen.routeName: (context) => const StartScreen(),
  OnBoardingScreen.routeName: (context) => const OnBoardingScreen(),
  WelcomeScreen.routeName: (context) => const WelcomeScreen(),
  YourGoalScreen.routeName: (context) => const YourGoalScreen(),

  UserLoginScreen.routeName: (context) => const UserLoginScreen(), 
  UserSignUpScreen.routeName: (context) => const UserSignUpScreen(), 
  
  CompleteProfileScreen.routeName: (context) => const CompleteProfileScreen(),
  GymRoomsScreen.routeName: (context) => const GymRoomsScreen(),
  NotificationsPage.routeName: (context) => const NotificationsPage(),



};
