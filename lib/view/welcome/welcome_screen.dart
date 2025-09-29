import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/aus/signup/signup_screen.dart' hide AppColors;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // استيراد Firebase Auth

import '../../const/common_widgets/round_gradient_button.dart';

class WelcomeScreen extends StatefulWidget {
  static String routeName = "/WelcomeScreen";

  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // متغير لتخزين اسم المستخدم
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // دالة لجلب اسم المستخدم من Firebase
  void _loadUserName() {
    // الحصول على المستخدم الحالي من Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // تحقق مما إذا كان الاسم المعروض (displayName) موجودًا
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        // إذا كان الاسم كاملاً (اسم أول واسم أخير)، نأخذ الاسم الأول فقط للترحيب
        final parts = user.displayName!.split(' ');
        final firstName = parts.isNotEmpty ? parts[0] : user.displayName;

        setState(() {
          userName = firstName ?? "User";
        });
      } else if (user.email != null) {
        // في حالة عدم وجود اسم معروض، نستخدم جزءًا من البريد الإلكتروني
        setState(() {
          userName = user.email!.split('@')[0];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset("assets/images/welcome_promo.png",
                  width: media.width * 0.75, fit: BoxFit.fitWidth),
              SizedBox(height: media.width * 0.05),
              // استخدام متغير userName بدلاً من الاسم الثابت
              Text(
                "Welcome, $userName",
                style: const TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: media.width * 0.01),
              const Text(
                "You are all set now, let’s reach your\ngoals together with us",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grayColor,
                  fontSize: 12,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              RoundGradientButton(
                title: "Go To Home",
                onPressed: () {
                  // بعد شاشة الترحيب، يتم التوجيه إلى لوحة التحكم (Dashboard)
                  Navigator.pushNamed(context, DashboardScreen.routeName);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGETS (RoundGradientButton) - Assuming its definition is in its own file
// =========================================================================

/*
// ملاحظة: لكي يعمل هذا الملف بشكل مستقل، يجب أن يكون لديك ملف
// `round_gradient_button.dart` يحتوي على تعريف RoundGradientButton
// أو قم بنقل تعريف الويدجت إلى هذا الملف (إذا لم يكن موجودًا في الملف الأصلي، يُرجى إضافته).
// المثال التالي يوضح كيفية استيراده، مع افتراض أن الويدجت RoundGradientButton
// موجودة في ملف منفصل:
// import '../../common_widgets/round_gradient_button.dart';
*/
