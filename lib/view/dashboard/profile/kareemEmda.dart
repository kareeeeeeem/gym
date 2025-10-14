// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ⚠️ تأكد أن هذه المسارات صحيحة في مشروعك
// import 'package:fitnessapp/const/common_widgets/round_button.dart';
// import 'package:fitnessapp/const/utils/app_colors.dart'; 

// =========================================================================
// 0. تعريفات افتراضية (AppColors و RoundButton)
// =========================================================================

// تعريف افتراضي للألوان (بافتراض نفس الألوان التي استخدمتها سابقاً)
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color darkGrayColor = Color(0xFFC0C0C0);
  static const Color primaryColor = Color(0xFF8B0000); // Dark Maroon/Deep Red
  static const Color accentColor = Color(0xFFFFA500); // Electric Gold/Amber
  static const Color lightGrayColor = Color(0xFF555555);

  static List<Color> primaryG = [const Color(0xFF8B0000), const Color(0xFFCC0000)]; // تدرج أساسي
  static List<Color> secondaryG = [const Color(0xFFFFA500), const Color(0xFFFFCC00)]; // تدرج ثانوي (ذهبي)
}

// تعريف افتراضي لزر دائري (RoundButton)
enum RoundButtonType { primaryBG, secondaryBG }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback? onPressed;

  const RoundButton({super.key, required this.title, required this.type, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: type == RoundButtonType.primaryBG ? AppColors.primaryG : AppColors.secondaryG,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: MaterialButton(
        onPressed: onPressed,
        minWidth: double.maxFinite,
        height: 50,
        child: Text(
          title,
          style: const TextStyle(color: AppColors.whiteColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =========================================================================
// 7. HowUsView - التصميم الجديد المبهر (مُحدَّث)
// =========================================================================
class HowUsView extends StatefulWidget {
  const HowUsView({super.key});

  @override
  State<HowUsView> createState() => _HowUsViewState();
}

class _HowUsViewState extends State<HowUsView> with SingleTickerProviderStateMixin {
  
  // بيانات المطور (Constants)
  static const String developerName = "Kareem Emad";
  static const String developerTitle = "Mobile & Web Developer";
  static const String devEmail = "kareememad852@gmail.com"; 
  static const String devPhone = "01554327428"; 
  static const String devLinkedIn = "linkedin.com/in/kareememad651893219"; 
  static const String devGitHub = "github.com/karecccceem"; 
  
  // 🆕 تم إضافة حسابات التواصل الجديدة
  static const String devFacebook = "web.facebook.com/kareem.emad.586899"; 
  static const String devInstagram = "instagram.com/kareemmemad"; 
  // تم حذف devBehance
  
  // 🔥 لإنشاء تأثير الظهور والانزلاق للأزرار
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;

  // تعريف الأزرار وبياناتها (مُحدَّث)
  final List<Map<String, String>> _contactItems = [
        {"label": "Phone", "icon": "📱", "value": devPhone, "link": "tel:$devPhone"},

    {"label": "Facebook", "icon": "💙", "value": "Open Profile", "link": "https://$devFacebook"},
    // 🆕 تم إضافة انستجرام
    {"label": "Instagram", "icon": "📸", "value": "@kareemmemad", "link": "https://$devInstagram"},
 
    {"label": "Email", "icon": "✉️", "value": devEmail, "link": "mailto:$devEmail"},
    {"label": "LinkedIn", "icon": "🔗", "value": "Open Profile", "link": "https://$devLinkedIn"},
    {"label": "GitHub", "icon": "⚙️", "value": "View Repos", "link": "https://$devGitHub"},
    // 🆕 تم إضافة فيسبوك
     ];

  @override
  void initState() {
    super.initState();
    // 💡 تهيئة الـ Controller لمدة ثانيتين (لأن لدينا 6 أزرار الآن)
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    
    _slideAnimations = List.generate(
      _contactItems.length,
      (index) => Tween<Offset>(
        // يبدأ من الأسفل وينزلق للأعلى
        begin: const Offset(0, 0.5), 
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          // تحديد تأخير بسيط لكل زر
          curve: Interval(
            (index) / _contactItems.length, // يبدأ كل زر متأخراً قليلاً
            1.0, 
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    
    // بدء الأنيميشن مباشرة عند تحميل الصفحة
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // =========================================================================
  // الدوال المساعدة - لم تتغير
  // =========================================================================
  
  void _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // 💡 ويدجت صف الاتصال (لم يتغير الهيكل)
  Widget _buildContactRow(int index, Map<String, String> item) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _animationController,
        child: InkWell(
          onTap: () => _launchURL(item['link']!, context),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.lightGrayColor.withOpacity(0.2), // خلفية شبه شفافة
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.lightGrayColor, width: 0.5),
            ),
            child: Row(
              children: [
                Text(item['icon']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w600, 
                          color: AppColors.darkGrayColor
                        ),
                      ),
                      Text(
                        item['value']!,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: AppColors.accentColor
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // =========================================================================
  // 🔨 البناء الرئيسي (CustomScrollView) - تم تصحيح الـ padding
  // =========================================================================
  
  @override
  Widget build(BuildContext context) {
    // ✅ التصحيح: الحصول على بيانات الشاشة الكاملة
    final mediaQueryData = MediaQuery.of(context);
    final mediaSize = mediaQueryData.size;
    
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: CustomScrollView(
        slivers: [
          // ------------------------------------------------------------------
          // 1. Sliver AppBar (الـ Header المبهر مع تأثير Parallax)
          // ------------------------------------------------------------------
          SliverAppBar(
            expandedHeight: mediaSize.height * 0.4, // استخدام mediaSize.height
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryColor, 
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryG, // تدرج أحمر قوي
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                     // ✅ التصحيح: استخدام mediaQueryData.padding.top للوصول للمنطقة الآمنة
                     padding: EdgeInsets.only(top: mediaQueryData.padding.top + 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // صورة المطور (تم تصحيح لون الخلفية ليكون ذهبي مبهر)
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.whiteColor, // تم تغيير اللون هنا
                        child: Text(
                          'KE', 
                          style: TextStyle(
                            fontSize: 40, 
                            color: AppColors.blackColor, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        developerName,
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.w900, 
                          color: AppColors.whiteColor
                        ),
                      ),
                      Text(
                        developerTitle,
                        style: TextStyle(
                          fontSize: 18, 
                          color: AppColors.accentColor.withOpacity(0.8) // اللون الذهبي
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // ------------------------------------------------------------------
          // 2. Sliver List (المحتوى والتفاصيل)
          // ------------------------------------------------------------------
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // نبذة تعريفية (تم إلغاء التعليق عنها)
                      // const Text(
                      //   'Professional Summary:', 
                      //   style: TextStyle(
                      //     fontSize: 20, 
                      //     fontWeight: FontWeight.w700, 
                      //     color: AppColors.accentColor
                      //   ),
                      // ),
                      // const SizedBox(height: 10),
                      // const Text(
                      //   'مطور تطبيقات موبايل وويب متخصص في بناء حلول قوية وفعالة باستخدام Flutter و Dart. ملتزم بتقديم تجربة مستخدم سلسة وواجهات مبهرة تتناسب مع أعلى معايير الجودة والاحترافية.',
                      //   style: TextStyle(
                      //     fontSize: 15, 
                      //     color: AppColors.darkGrayColor,
                      //     height: 1.5
                      //   ),
                      // ),
                      
                      const Divider(color: AppColors.lightGrayColor, height: 40),

                      // قسم التواصل (مع أنيميشن الظهور)
                      const Text(
                        'Contact & Portfolio:', 
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w700, 
                          color: AppColors.accentColor
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // 💡 عرض صفوف التواصل مع الأنيميشن (مُحدَّث ليشمل 6 عناصر)
                      ...List.generate(_contactItems.length, (index) {
                        return _buildContactRow(index, _contactItems[index]);
                      }),

                      const SizedBox(height: 40),
                      
                      // زر الـ CTA (تم إلغاء التعليق عنه)
                      // RoundButton(
                      //   title: "Hire for Mobile/Web Development",
                      //   type: RoundButtonType.secondaryBG,
                      //   onPressed: () => _launchURL("mailto:$devEmail", context),
                      // ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}