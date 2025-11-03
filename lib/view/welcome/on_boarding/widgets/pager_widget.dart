// File: lib/view/welcome/on_boarding/widgets/pager_widget.dart

import 'package:flutter/material.dart';
// يجب التأكد من مسار AppColors الصحيح في تطبيقك
// import 'package:fitnessapp/aus/signup/signup_screen.dart'; // افترض وجود AppColors

// تعريف AppColors لضمان عمل PagerWidget بشكل منفصل
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color primaryColor1 = Color(0xFF92A3FD); 
}

class PagerWidget extends StatelessWidget {
  final Map obj;
  const PagerWidget({Key? key, required this.obj}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🌟 الجزء العلوي للصورة
        Expanded(
          // 🛑 تقليل Flex هنا إلى 3.5 لترك مجال أكبر للصورة مع الـ Alignment.topCenter
          flex: 1, 
          child: Container(
             color: AppColors.blackColor, 
             width: double.infinity, 
             child: Image.asset(
               obj["image"].toString(), 
               fit: BoxFit.fitWidth, 
               alignment: Alignment.topCenter, 
             ),
          ),
        ),
        // 🌟 الجزء السفلي للنص (تم تقليل Flex لتقليل المساحة)
        Expanded(
          // 🛑 تقليل Flex هنا إلى 1 لتقليل الفراغ الأسود غير المستخدم
          flex: 1, 
          child: Container(
            color: AppColors.blackColor, 
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.start هو الصحيح
              mainAxisAlignment: MainAxisAlignment.start, 
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  obj["title"].toString(),
                  style: const TextStyle(
                    color: AppColors.whiteColor, 
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 15),
                Text(
                  obj["subtitle"].toString(),
                  style: TextStyle(
                    color: AppColors.whiteColor.withOpacity(0.7), 
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}