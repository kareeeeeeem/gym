import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =========================================================================
// 1. تعريف الألوان (AppColors)
// =========================================================================

class AppColors {
  // ألوان الثيم الجديد: الخلفية داكنة، والألوان الزاهية للحيوية
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); // Dark Background
  static const Color darkGrayColor = Color(0xFFC0C0C0); // Lighter Gray for text on dark bg
  static const Color primaryColor1 = Color(0xFF92A3FD); // Primary Blue/Lavender for titles
  static const Color accentColor = Color(0xFF00C4CC); // Bright Mint/Tiffany Green for actions/highlights
  static const Color cardBackgroundColor = Color(0xFF222222); // Dark background for dialogs
  static const Color lightGrayColor = Color(0xFF333333); // Darker gray for subtle dividers
  static const Color redColor = Color(0xFFEA4E79); // Red for Logout/Alerts
}

// =========================================================================
// 2. كود SettingRow (مُحدَّث ليناسب الخلفية الداكنة)
// =========================================================================

class SettingRow extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onPressed;
  final bool isLogout; // خاصية جديدة لتمييز زر تسجيل الخروج

  const SettingRow({
    Key? key, 
    required this.icon, 
    required this.title, 
    required this.onPressed,
    this.isLogout = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // تحديد لون الأيقونة والنص بناءً على ما إذا كانت صف تسجيل خروج
    final color = isLogout ? AppColors.redColor : AppColors.darkGrayColor;
    final iconPlaceholderUrl = icon; // استخدام المتغير كـ URL بدلاً من اسم asset

    return InkWell(
      onTap: onPressed,
      // خلفية عند الضغط بلون الثيم الأساسي الشفاف
      splashColor: AppColors.primaryColor1.withOpacity(0.3), 
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 25.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // استخدام Image.network كـ placeholder بدلاً من Image.asset
            Image.network(
                iconPlaceholderUrl,
                height: 20, 
                width: 20, 
                fit: BoxFit.contain, 
                color: color, // تطبيق لون الثيم
                errorBuilder: (context, error, stackTrace) => Icon(
                    isLogout ? Icons.logout : Icons.settings, // أيقونة احتياطية
                    color: color,
                    size: 20,
                ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color, // تطبيق لون النص للثيم الداكن
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Placeholder for p_next.png (سهم الانتقال)
            Image.network(
                "https://placehold.co/12x12/C0C0C0/1D1617?text=>", 
                height: 12, 
                width: 12, 
                fit: BoxFit.contain,
                color: AppColors.darkGrayColor.withOpacity(0.5), // لون باهت للسهم
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.darkGrayColor,
                    size: 14,
                ),
            )
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 3. كود الصفحة الرئيسية (SettingsView) - تطبيق الثيم الداكن
// =========================================================================

class SettingsView extends StatelessWidget {
  static const String routeName = "/SettingsView";
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌟 الخلفية الداكنة
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        title: const Text(
            "الإعدادات", 
            style: TextStyle(
                color: AppColors.whiteColor, // نص أبيض
                fontWeight: FontWeight.bold
            )
        ),
        // 🌟 شريط التطبيق الداكن
        backgroundColor: AppColors.blackColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.whiteColor), // أيقونة العودة بيضاء
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // لمحاذاة العنوان
          children: [
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Text(
                "الإعدادات العامة", 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor1, // 🌟 استخدام لون الثيم الأساسي للعنوان
                )
              ),
            ),
            
            // 🌟🌟 المثال 1: فتح صفحة جديدة (Account)
            SettingRow(
              // Placeholder URL for profile_icon.png
              icon: "https://placehold.co/20x20/92A3FD/1D1617?text=P", 
              title: "إعدادات الحساب",
              onPressed: () {
                print("Action: Navigate to Account Settings");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text("الذهاب إلى إعدادات الحساب...", textDirection: TextDirection.rtl),
                        backgroundColor: AppColors.accentColor // لون الإبراز الأخضر النعناعي
                    ));
              },
            ),

            // 🌟 خط فاصل داكن
            Divider(height: 1, color: AppColors.lightGrayColor),

            // 🌟🌟 المثال 2: تشغيل دالة (Notification)
            SettingRow(
              // Placeholder URL for notification_icon.png
              icon: "https://placehold.co/20x20/00C4CC/1D1617?text=N", 
              title: "الإشعارات",
              onPressed: () {
                print("Action: Navigate to Notifications");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text("فتح تفضيلات الإشعارات...", textDirection: TextDirection.rtl),
                        backgroundColor: AppColors.accentColor
                    ));
              },
            ),

            // 🌟 خط فاصل داكن
            Divider(height: 1, color: AppColors.lightGrayColor),

            // إضافة صف ثالث للخصوصية
             SettingRow(
              // Placeholder URL for privacy icon
              icon: "https://placehold.co/20x20/92A3FD/1D1617?text=S", 
              title: "الخصوصية والأمان",
              onPressed: () {
                print("Action: Navigate to Privacy");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text("فتح إعدادات الخصوصية...", textDirection: TextDirection.rtl),
                        backgroundColor: AppColors.accentColor
                    ));
              },
            ),

            Divider(height: 1, color: AppColors.lightGrayColor),
            
            // 🌟🌟 المثال 3: تسجيل الخروج (Logout) - بلون أحمر للإبراز
            SettingRow(
              // Placeholder URL for logout_icon.png
              icon: "https://placehold.co/20x20/EA4E79/1D1617?text=L", 
              title: "تسجيل الخروج",
              isLogout: true, // لتغيير لون النص والأيقونة للأحمر
              onPressed: () {
                print("Action: Logging out user");
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    // 🌟 خلفية الحوار داكنة
                    backgroundColor: AppColors.cardBackgroundColor,
                    title: const Text("تأكيد تسجيل الخروج", style: TextStyle(color: AppColors.whiteColor)),
                    content: const Text("هل أنت متأكد من رغبتك في تسجيل الخروج؟", style: TextStyle(color: AppColors.darkGrayColor)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: const Text("إلغاء", style: TextStyle(color: AppColors.accentColor)) // زر الإلغاء بلون الثيم
                      ),
                      TextButton(onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: const Text("تم تسجيل الخروج بنجاح", textDirection: TextDirection.rtl),
                                backgroundColor: AppColors.redColor // رسالة الخروج بلون الخطر
                            ));
                      }, child: const Text("تسجيل الخروج", style: TextStyle(color: AppColors.redColor))), // زر الخروج بلون الخطر
                    ],
                  ),
                );
              },
            ),

            // يمكن إضافة المزيد من الصفوف هنا...
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 4. Main App Widget (لتشغيل العرض)
// =========================================================================

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ocean & Energy Settings',
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor1, 
          background: AppColors.blackColor,
        ),
        useMaterial3: true,
      ),
      // تشغيل واجهة الإعدادات مباشرة
      home: const SettingsView(), 
    );
  }
}
