import 'dart:io';

import 'package:fitnessapp/const/utils/app_colors.dart';
// تم إزالة الاستيراد الغير مستخدم أو غير المتاح مؤقتا
// import 'package:fitnessapp/view/activity/activity_screen.dart'; 
import 'package:fitnessapp/view/camera/camera_screen.dart';
import 'package:fitnessapp/view/dashboard/Room/GymRoomsScreen.dart';
import 'package:fitnessapp/view/dashboard/store_and_subscriptions_screen.dart';
import 'package:fitnessapp/view/profile/user_profile.dart'; // تم إزالة hide AppColors
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; 

import '../home/home_screen.dart';
import 'package:fitnessapp/view/activity/activity_screen.dart'; // ✅ تم إضافة الاستيراد المفقود

class DashboardScreen extends StatefulWidget {
  static String routeName = "/DashboardScreen";

  final List<CameraDescription> cameras;

  const DashboardScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectTab = 0;

  // 1. إعادة ترتيب الشاشات لدمج المتجر في الوسط (Index 2)
  late final List<Widget> _widgetOptions;
  
  final String _storeIcon = "assets/icons/shop_icon.png"; 
  final String _storeSelectIcon = "assets/icons/shop_select_icon.png";

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
       const  GymRoomsScreen(),          // Index 4: المستخدم في النهاية
//      const HomeScreen(),               // Index 0
      const ActivityScreen(),           // Index 1: تم تعديل هذا ليصبح ActivityScreen
      const StoreAndSubscriptionsScreen(), // Index 2: المتجر الآن في المنتصف
      CameraScreen(cameras: widget.cameras), // Index 3
      const UserProfile(),
    ];

    if (selectTab >= _widgetOptions.length || selectTab < 0) {
      selectTab = 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    final secondaryG = [const Color(0xFFC58BF2), const Color(0xFF92A3FD)];
    
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: IndexedStack(
        index: selectTab,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomAppBar(
        height: Platform.isIOS ? 70 : 65,
        color: Colors.transparent,
        padding: const EdgeInsets.all(0),
        child: Container(
          height: Platform.isIOS ? 70 : 65,
          decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, -2))
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // زر 1: الرئيسية (Index 0)
              TabButton(
                  icon: "assets/icons/home_icon.png",
                  selectIcon: "assets/icons/home_select_icon.png",
                  isActive: selectTab == 0,
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        selectTab = 0;
                      });
                    }
                  }),
              // زر 2: الغرف (GymRoomsScreen) - تم تغيير الـ Index من 1 إلى 2 لـ Activity Screen
              TabButton(
                  icon: "assets/icons/activity_icon.png",
                  selectIcon: "assets/icons/activity_select_icon.png",
                  isActive: selectTab == 1,
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        selectTab = 1;
                      });
                    }
                  }),
              // 3. زر 3: المتجر (Index 2)
              TabButton(
                  icon: _storeIcon, 
                  selectIcon: _storeSelectIcon,
                  isActive: selectTab == 2,
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        selectTab = 2; 
                      });
                    }
                  }),
              // زر 4: الكاميرا (Index 3)
              TabButton(
                  icon: "assets/icons/camera_icon.png",
                  selectIcon: "assets/icons/camera_select_icon.png",
                  isActive: selectTab == 3,
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        selectTab = 3;
                      });
                    }
                  }),
              // 4. زر 5: المستخدم (Index 4)
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
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class TabButton extends StatelessWidget {
  final String icon;
  final String selectIcon;
  final bool isActive;
  final VoidCallback onTap;

  const TabButton(
      {Key? key,
      required this.icon,
      required this.selectIcon,
      required this.isActive,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final secondaryG = [const Color(0xFFC58BF2), const Color(0xFF92A3FD)];
    
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            isActive ? selectIcon : icon,
            width: 25,
            height: 25,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) {
              IconData iconData = Icons.person; 
              if (icon.contains("shop") || icon.contains("store")) {
                  iconData = Icons.shopping_bag_outlined;
              } else if (icon.contains("home")) {
                  iconData = Icons.home;
              } else if (icon.contains("activity")) {
                  iconData = Icons.directions_run;
              } else if (icon.contains("camera")) {
                  iconData = Icons.camera_alt;
              }
              return Icon(
                iconData,
                color: isActive ? secondaryG.first : Colors.grey,
                size: 25,
              );
            },
          ),
          SizedBox(height: isActive ? 8 : 12),
          Visibility(
            visible: isActive,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: secondaryG),
                  borderRadius: BorderRadius.circular(2)),
            ),
          )
        ],
      ),
    );
  }
}