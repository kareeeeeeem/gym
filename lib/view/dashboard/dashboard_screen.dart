import 'dart:io';

import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/camera/camera_screen.dart';
import 'package:fitnessapp/view/dashboard/Room/GymRoomsScreen.dart' hide AppColors; // تم دمج hide AppColors (لا حاجة لـ hide إذا كان الاستخدام في هذا الملف لا يتعارض)
import 'package:fitnessapp/view/dashboard/store_and_subscriptions_screen.dart' hide AppColors; // تم دمج hide AppColors
import 'package:fitnessapp/view/dashboard/profile/user_profile.dart' hide AppColors; // تم دمج hide AppColors 
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; 

import 'home/home_screen.dart';
import 'package:fitnessapp/view/dashboard/activity/activity_screen.dart'; 

// =========================================================================
// تم إزالة تعريف AppColors.
// يتم الآن استدعاء AppColors من:
// package:fitnessapp/const/utils/app_colors.dart
// =========================================================================


class DashboardScreen extends StatefulWidget {
  static String routeName = "/DashboardScreen";

  final List<CameraDescription> cameras;

  const DashboardScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // الترتيب المطلوب (الآن جميعها أزرار عادية): 
  // 0: GymRoomsScreen
  // 1: StoreAndSubscriptionsScreen
  // 2: CameraScreen 
  // 3: ActivityScreen
  // 4: UserProfile
  int selectTab = 0;

  // 1. تعريف مسارات الأيقونات
  final String _storeIcon = "assets/icons/shop_icon.png"; 
  final String _storeSelectIcon = "assets/icons/shop_select_icon.png";
  final String _roomIcon = "assets/icons/community_icon.png"; // افتراض أيقونة للغرف
  final String _roomSelectIcon = "assets/icons/community_select_icon.png"; // افتراض أيقونة للغرف

  // 2. ترتيب الشاشات 
  late final List<Widget> _widgetOptions;
  
  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const GymRoomsScreen(),          // Index 0: غرف الجيم
      StoreAndSubscriptionsScreen(), // 🟢 تم التعديل
      CameraScreen(cameras: widget.cameras), // Index 2: الكاميرا
      const ActivityScreen(),           // Index 3: النشاط
      const UserProfile(),              // Index 4: البروفايل
    ];

    if (selectTab >= _widgetOptions.length || selectTab < 0) {
      selectTab = 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    // تم تعريف التدرج اللوني لثيم Ego Gym (الذهبي والمحمر) مباشرة هنا:
    final List<Color> gymGradient = [const Color(0xFFFFA500), const Color(0xFF8B0000)]; // ذهبي وماروني
    
    return Scaffold(
      // *** التعديل لحل مشكلة اللون الأبيض ***
      // السماح لـ body بالتمدد خلف شريط التنقل السفلي
      extendBody: true, 
      
      // تغيير خلفية Scaffold إلى الأسود لتوحيد الثيم الداكن
      backgroundColor: AppColors.blackColor,
      
      body: IndexedStack(
        index: selectTab,
        children: _widgetOptions,
      ),
      
      // =========================================================================
      // تصميم شريط التنقل العائم والمدور (Fully Rounded Pill-Shaped Navbar)
      // =========================================================================
      bottomNavigationBar: Padding(
        // إعطاء مسافة بادئة من الأسفل والجوانب لجعل الشريط "عائماً"
        padding: EdgeInsets.only(
          bottom: Platform.isIOS ? 35 : 25, // مسافة كبيرة من الأسفل
          left: 20, 
          right: 20,
        ),
        child: ClipRRect(
          // تدوير الحواف بالكامل
          borderRadius: BorderRadius.circular(30),
          child: Container(
            // ارتفاع مريح
            height: Platform.isIOS ? 75 : 65, 
            // خلفية داكنة (شبه شفافة)
            color: AppColors.blackColor.withOpacity(0.85), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // توزيع الأزرار بالتساوي
              children: [
                // زر 1: غرف الجيم (GymRoomsScreen) - Index 0
                TabButton(
                    icon: _roomIcon,
                    selectIcon: _roomSelectIcon,
                    isActive: selectTab == 0,
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          selectTab = 0;
                        });
                      }
                    },
                    gradient: gymGradient,
                    fallbackIcon: Icons.group_work, 
                ),
                // زر 2: المتجر (StoreAndSubscriptionsScreen) - Index 1
                TabButton(
                    icon: _storeIcon,
                    selectIcon: _storeSelectIcon,
                    isActive: selectTab == 1,
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          selectTab = 1;
                        });
                      }
                    },
                    gradient: gymGradient,
                    fallbackIcon: Icons.storefront,
                ),
                // زر 3: الكاميرا (CameraScreen) - Index 2
                TabButton(
                    icon: "assets/icons/camera_icon.png",
                    selectIcon: "assets/icons/camera_select_icon.png",
                    isActive: selectTab == 2,
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          selectTab = 2;
                        });
                      }
                    },
                    gradient: gymGradient,
                    fallbackIcon: Icons.camera_alt,
                ),
                // زر 4: النشاط (ActivityScreen) - Index 3
                TabButton(
                    icon: "assets/icons/activity_icon.png",
                    selectIcon: "assets/icons/activity_select_icon.png",
                    isActive: selectTab == 3,
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          selectTab = 3;
                        });
                      }
                    },
                    gradient: gymGradient,
                    fallbackIcon: Icons.directions_run,
                ),
                // زر 5: المستخدم (UserProfile) - Index 4
                TabButton(
                    icon: "assets/icons/user_icon.png",
                    selectIcon: "assets/icons/user_select_icon.png",
                    isActive: selectTab == 4,
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          selectTab = 4;
                        });
                      }
                    },
                    gradient: gymGradient,
                    fallbackIcon: Icons.person,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// مكون زر التنقل (TabButton) - تم تعديل الألوان لتناسب الخلفية الداكنة الجديدة
// =========================================================================
class TabButton extends StatelessWidget {
  final String icon;
  final String selectIcon;
  final bool isActive;
  final VoidCallback onTap;
  final List<Color> gradient;
  final IconData fallbackIcon; // أيقونة احتياطية

  const TabButton({
      Key? key,
      required this.icon,
      required this.selectIcon,
      required this.isActive,
      required this.onTap,
      required this.gradient,
      required this.fallbackIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return InkWell(
      onTap: onTap,
      child: Padding( 
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
          children: [
            // الأيقونة الرئيسية
            Image.asset(
              isActive ? selectIcon : icon,
              width: 28, 
              height: 28,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) {
                // اللون النشط: ذهبي (أول لون في التدرج)
                // اللون غير النشط: أبيض/رمادي فاتح ليتناسب مع الخلفية الداكنة
                return Icon(
                  fallbackIcon,
                  color: isActive ? gradient.first : AppColors.whiteColor.withOpacity(0.7),
                  size: 28,
                );
              },
            ),
            const SizedBox(height: 6), // المسافة بين الأيقونة والمؤشر
            
            // مؤشر النشاط (شريط التدرج اللوني الصغير)
            Visibility(
              visible: isActive,
              child: Container(
                width: 30, 
                height: 4, 
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2)), 
              ),
            )
          ],
        ),
      ),
    );
  }
}