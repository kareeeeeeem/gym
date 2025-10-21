// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// 💡 استيراد Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================================
// 0. تعريفات افتراضية (AppColors و RoundButton)
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
// 1. ContactUsView - شاشة التواصل الديناميكية
// =========================================================================
class ContactUsView extends StatefulWidget {
  static const String routeName = "/contact_us_view";
  
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<ContactUsView> with SingleTickerProviderStateMixin {
  
  // 🔥 لإنشاء تأثير الظهور والانزلاق لصفوف التواصل
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    );
    // سيتم بدء الأنيميشن بعد جلب البيانات أو فوراً إذا كان هناك بيانات سابقة
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // =========================================================================
  // الدوال المساعدة
  // =========================================================================
  
  void _launchURL(String url, BuildContext context, String label) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // 💡 عرض SnackBar بدلاً من Throw Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $label')),
      );
    }
  }

  // 💡 ويدجت صف الاتصال (مع الأنيميشن)
  Widget _buildContactRow(
    int index, 
    Map<String, String> item, 
    List<Animation<Offset>> slideAnimations, // تمرير قائمة الأنيميشن
  ) {
    // 💡 استخدام AnimatedBuilder لضمان تشغيل الأنيميشن بشكل صحيح
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // التأكد من أن الـ index لا يتجاوز حدود قائمة الأنيميشن
        if (index >= slideAnimations.length) return child!;
        
        return SlideTransition(
          position: slideAnimations[index],
          child: FadeTransition(
            opacity: _animationController,
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
            // تنظيف رقم الواتساب قبل إرساله للرابط
            final link = item['link']!.contains('whatsapp') 
                ? item['link']!.replaceAll(RegExp(r'\s+'), '').replaceAll('+', '') // إزالة المسافات وعلامة +
                : item['link']!;
            _launchURL(link, context, item['label']!);
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
    );
  }
  
  // =========================================================================
  // 🔨 البناء الرئيسي (Scaffold) مع StreamBuilder
  // =========================================================================
  
  @override
  Widget build(BuildContext context) {
    // ⚠️ ملاحظة: المسار هنا هو مثال. في تطبيق حقيقي، يجب استخدام المسار العام
    // /artifacts/{__app_id}/public/data/contact_info/gym_details
    const String firestorePath = 'gym_data/contact_info';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Ego Gym", style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryColor, 
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      backgroundColor: AppColors.blackColor,
      
      // 💡 استخدام StreamBuilder لجلب البيانات وتحديثها آلياً
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.doc(firestorePath).snapshots(),
        builder: (context, snapshot) {
          
          // ------------------------------------
          // 1. حالة التحميل
          // ------------------------------------
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentColor),
            );
          }
          
          // ------------------------------------
          // 2. حالة الخطأ أو عدم وجود بيانات
          // ------------------------------------
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            );
          }
          
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          
          if (!snapshot.hasData || data == null || data.isEmpty) {
            return const Center(
              child: Text("No contact information found.", style: TextStyle(color: AppColors.darkGrayColor)),
            );
          }
          
          // ------------------------------------
          // 3. البيانات جاهزة (Success)
          // ------------------------------------
          
          // 💡 استخراج البيانات مع قيم افتراضية (Fallbacks)
          final String gymSlogan = data['gymSlogan'] ?? "Contact us to start your journey!";
          final String gymWhatsApp = data['gymWhatsApp'] ?? "N/A";
          final String gymPhone = data['gymPhone'] ?? "N/A";
          final String gymEmail = data['gymEmail'] ?? "N/A";
          final String gymFacebook = data['gymFacebook'] ?? "N/A";
          final String gymFacebookLink = data['gymFacebookLink'] ?? "https://facebook.com";
          final String gymLocationAddress = data['gymLocationAddress'] ?? "Location unknown";
          final String gymLocationLink = data['gymLocationLink'] ?? "https://maps.google.com";
          
          // 💡 إعادة بناء قائمة التواصل بالبيانات الجديدة
          final List<Map<String, String>> contactItems = [
            {"label": "WhatsApp", "icon": "💬", "value": gymWhatsApp, "link": "whatsapp://send?phone=2$gymWhatsApp"},
            {"label": "Phone", "icon": "📞", "value": gymPhone, "link": "tel:$gymPhone"},
            {"label": "Email", "icon": "📧", "value": gymEmail, "link": "mailto:$gymEmail"},
            {"label": "Facebook", "icon": "📘", "value": gymFacebook, "link": gymFacebookLink},
          ];

          // 💡 إعداد أنيميشن انزلاق متسلسل لكل صف
          final List<Animation<Offset>> slideAnimations = List.generate(
            contactItems.length,
            (index) => Tween<Offset>(
              begin: const Offset(0, 0.5), 
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index) / contactItems.length, 
                  1.0, 
                  curve: Curves.easeOut,
                ),
              ),
            ),
          );
          
          // بدء الأنيميشن
          _animationController.forward(from: 0.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------------------------
                // 1. سلوجان الجيم (Gym Slogan) - ديناميكي
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
                        gymSlogan, // 💡 قيمة ديناميكية
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
                // 2. تفاصيل التواصل (مع الأنيميشن) - ديناميكي
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
                
                // 💡 عرض صفوف التواصل مع الأنيميشن باستخدام البيانات الجديدة
                ...List.generate(contactItems.length, (index) {
                  return _buildContactRow(index, contactItems[index], slideAnimations);
                }),

                const Divider(color: AppColors.lightGrayColor, height: 40),

                // ------------------------------------------------------------------
                // 3. بطاقة الموقع البارزة (The Golden Card) - ديناميكية
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
                  onTap: () => _launchURL(gymLocationLink, context, 'Google Maps'),
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
                          gymLocationAddress, // 💡 قيمة ديناميكية
                          style: TextStyle(fontSize: 14, color: AppColors.blackColor.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 15),
                        const Text('Tap to open Google Maps 🗺️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryColor)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // 4. زر الـ CTA النهائي - ديناميكي
                RoundButton(
                  title: "Visit Gym Location Now",
                  type: RoundButtonType.primaryBG,
                  onPressed: () => _launchURL(gymLocationLink, context, 'Google Maps'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
