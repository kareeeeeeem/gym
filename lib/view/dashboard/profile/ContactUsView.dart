// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ⚠️ (تعريفات AppColors و RoundButton الافتراضية هنا)
// يجب عليك التأكد من أن تعريفات AppColors و RoundButton 
// في مشروعك تتطابق مع الهيكل الذي استخدمته سابقاً.

// =========================================================================
// 0. تعريفات افتراضية (للتأكد من عمل الكود بشكل مستقل)
// =========================================================================

// تعريف افتراضي للألوان
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
// 7. ContactUsView - التصميم الجديد المبهر مع الأنيميشن
// =========================================================================
class ContactUsView extends StatefulWidget {
  static const String routeName = "/contact_us_view";
  
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<ContactUsView> with SingleTickerProviderStateMixin {
  
  // بيانات الجيم (Constants)
  static const String gymSlogan = "Get strong with us! Your journey begins now. 💪🌟";
  static const String gymWhatsApp = "01005235831"; 
  static const String gymPhone = "01005235831";
  static const String gymEmail = "egogym.banha@gmail.com";
  static const String gymFacebook = "@egoo.gym (4.4k followers)";
  static const String gymLocationAddress = "Street 2, Qism Banha, Second Banha, Before Al-Fahs Bridge in front of Othaim Ego Gym, Benha, Egypt";
  static const String gymLocationLink = "https://bit.ly/egogym-location";

  // 🔥 لإنشاء تأثير الظهور والانزلاق لصفوف التواصل
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  
  // تعريف صفوف التواصل
  final List<Map<String, String>> _contactItems = [
    {"label": "WhatsApp", "icon": "💬", "value": gymWhatsApp, "link": "whatsapp://send?phone=+2$gymWhatsApp"},
    {"label": "Phone", "icon": "📞", "value": gymPhone, "link": "tel:$gymPhone"},
    {"label": "Email", "icon": "📧", "value": gymEmail, "link": "mailto:$gymEmail"},
    {"label": "Facebook", "icon": "📘", "value": gymFacebook, "link": "https://facebook.com/egoo.gym"},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    
    // إعداد أنيميشن انزلاق متسلسل لكل صف
    _slideAnimations = List.generate(
      _contactItems.length,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5), 
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index) / _contactItems.length, 
            1.0, 
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // =========================================================================
  // الدوال المساعدة
  // =========================================================================
  
  void _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch link.')),
      );
    }
  }

  // 💡 ويدجت صف الاتصال (مع الأنيميشن)
  Widget _buildContactRow(int index, Map<String, String> item) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _animationController,
        child: InkWell(
          onTap: () {
             // إزالة المسافات من رقم الواتساب قبل إرساله للرابط
             final link = item['link']!.contains('whatsapp') 
                ? item['link']!.replaceAll(' ', '').replaceAll('+', '') 
                : item['link']!;
             _launchURL(link, context);
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.lightGrayColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.primaryColor, width: 0.5),
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
                          color: AppColors.whiteColor
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // =========================================================================
  // 🔨 البناء الرئيسي (Scaffold)
  // =========================================================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Ego Gym", style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryColor, 
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      backgroundColor: AppColors.blackColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------------
            // 1. سلوجان الجيم (Gym Slogan)
            // ------------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.primaryG),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ego Gym', 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: AppColors.whiteColor
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    gymSlogan,
                    style: TextStyle(
                      fontSize: 15, 
                      fontStyle: FontStyle.italic, 
                      color: AppColors.whiteColor.withOpacity(0.8)
                    ), 
                  ),
                ],
              ),
            ),
            
            const Divider(color: AppColors.lightGrayColor, height: 40),

            // ------------------------------------------------------------------
            // 2. تفاصيل التواصل (مع الأنيميشن)
            // ------------------------------------------------------------------
            const Text(
              'Contact Details:', 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w700, 
                color: AppColors.accentColor
              ),
            ),
            const SizedBox(height: 15),
            
            // 💡 عرض صفوف التواصل مع الأنيميشن
            ...List.generate(_contactItems.length, (index) {
              return _buildContactRow(index, _contactItems[index]);
            }),

            const Divider(color: AppColors.lightGrayColor, height: 40),

            // ------------------------------------------------------------------
            // 3. بطاقة الموقع البارزة (The Golden Card)
            // ------------------------------------------------------------------
            const Text(
              'Location & Directions:', 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w700, 
                color: AppColors.accentColor
              ),
            ),
            const SizedBox(height: 15),
            
            InkWell(
              onTap: () => _launchURL(gymLocationLink, context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.secondaryG, // تدرج ذهبي مبهر
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.blackColor, size: 28),
                        SizedBox(width: 10),
                        Text('Gym Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.blackColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gymLocationAddress, 
                      style: TextStyle(fontSize: 14, color: AppColors.blackColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 15),
                    const Text('Tap to open Google Maps 🗺️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryColor)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 4. زر الـ CTA النهائي
            RoundButton(
              title: "Visit Gym Location Now",
              type: RoundButtonType.primaryBG,
              onPressed: () => _launchURL(gymLocationLink, context),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}