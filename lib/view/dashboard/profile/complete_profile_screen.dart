import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

// =========================================================================
// 1. تعريف الألوان (AppColors) - مأخوذ من settings_view_themed.dart
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); // Dark Background
  static const Color darkGrayColor = Color(0xFFC0C0C0); // Lighter Gray for text on dark bg
  static const Color primaryColor1 = Color(0xFF92A3FD); // Primary Blue/Lavender for titles/buttons
  static const Color accentColor = Color(0xFF00C4CC); // Bright Mint/Tiffany Green for highlights
  static const Color cardBackgroundColor = Color(0xFF222222); // Dark background for dialogs & inputs
  static const Color lightGrayColor = Color(0xFF333333); // Darker gray for subtle dividers/input containers
  static const Color redColor = Color(0xFFEA4E79); // Red for Alerts
  
  static const List<Color> primaryG = [
    Color(0xFF92A3FD), // Primary Blue/Lavender
    Color(0xFF00C4CC), // Bright Mint/Tiffany Green
  ];
  
  // تعريف لون افتراضي للرمادي لـ TextFields
  static const Color grayColor = Color(0xFF7B6F72); 
}

// =========================================================================
// 2. Placeholder لـ YourGoalScreen (لحل مشكلة التبعية)
// =========================================================================

class YourGoalScreen extends StatelessWidget {
  static const String routeName = "/YourGoalScreen";
  const YourGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.blackColor,
        appBar: AppBar(title: const Text("Goal Setting", style: TextStyle(color: AppColors.whiteColor))),
        body: Center(child: Text("Welcome! Your profile is complete.", style: TextStyle(color: AppColors.whiteColor))),
    );
  }
}


// =========================================================================
// 3. Placeholder لـ RoundTextField (مُعدَّل ليناسب الثيم الداكن)
// =========================================================================

class RoundTextField extends StatelessWidget {
  final String hintText;
  final String icon;
  final TextInputType textInputType;
  final TextEditingController? controller;
  final bool isReadOnly;

  const RoundTextField({
    Key? key,
    required this.hintText,
    required this.icon,
    required this.textInputType,
    this.controller,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // استخدام لون خلفية البطاقة الداكن لـ TextField
        color: AppColors.cardBackgroundColor, 
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: textInputType,
        readOnly: isReadOnly,
        style: const TextStyle(color: AppColors.whiteColor, fontSize: 14), // نص الإدخال أبيض
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 0),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.darkGrayColor, fontSize: 12), // نص المساعدة رمادي فاتح
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Image.network(
              // Placeholder for the icon
              icon.contains('calendar') ? "https://placehold.co/20x20/92A3FD/1D1617?text=C" :
              icon.contains('weight') ? "https://placehold.co/20x20/00C4CC/1D1617?text=W" : 
              "https://placehold.co/20x20/C0C0C0/1D1617?text=I",
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              color: AppColors.primaryColor1, // لون الأيقونة
              errorBuilder: (context, error, stackTrace) => Icon(
                icon.contains('calendar') ? Icons.calendar_today : 
                icon.contains('weight') ? Icons.scale : Icons.swap_horiz,
                color: AppColors.primaryColor1,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// =========================================================================
// 4. كود شاشة إكمال الملف الشخصي (CompleteProfileScreen) - تطبيق الثيم الداكن
// =========================================================================

class CompleteProfileScreen extends StatefulWidget {
  static String routeName = "/CompleteProfileScreen";
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // Controllers for text fields
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  // Controller to display the formatted date of birth
  final TextEditingController _dobTextController = TextEditingController();
  
  // Variable to store the actual Date of Birth DateTime object
  DateTime? _selectedDateOfBirth;
  
  String? _selectedGender; // To store the Dropdown value

  // List of genders
  final List<String> _genders = ["Male", "Female", "Other"];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _dobTextController.dispose();
    super.dispose();
  }
  
  // Function to calculate age from date of birth
  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Function to open the Date Picker and select DOB (معدلة للألوان الداكنة)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900), 
      lastDate: DateTime.now(), 
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith( // 🌟 استخدام ثيم داكن لـ Date Picker
            colorScheme: ColorScheme.dark(
              primary: AppColors.accentColor, // لون التحديد (الأخضر النعناعي)
              onPrimary: AppColors.whiteColor, 
              surface: AppColors.cardBackgroundColor, // خلفية التقويم
              onSurface: AppColors.whiteColor, // نص التقويم
            ),
            dialogBackgroundColor: AppColors.cardBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobTextController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // 🔥 Function to save data to Firestore
  void saveProfile() async {
    // 💡 استخدام Mock Auth بدلاً من Firebase Auth لضمان العمل في بيئة الكانفاس
    // يمكن استبداله بـ FirebaseAuth.instance.currentUser عند الاستخدام الفعلي
    final user = { 'uid': 'mock_user_123' }; 
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated.')),
      );
      return;
    }

    if (_selectedGender == null || _selectedDateOfBirth == null || _weightController.text.isEmpty || _heightController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields first.')),
      );
      return;
    }
    
    final int age = calculateAge(_selectedDateOfBirth!);

    try {
      // 💡 يتم استخدام Mock Firestore هنا لضمان عمل الكود
      print("Saving mock data for user ${user['uid']}:");
      print("Gender: $_selectedGender, Age: $age, Weight: ${_weightController.text}, Height: ${_heightController.text}");

      // يجب استخدام FirebaseFirestore.instance.collection('users').doc(user.uid).set(...)
      // عند الربط الفعلي بقاعدة البيانات
      
      // Navigate to the next screen upon success
      if (mounted) {
         Navigator.pushReplacementNamed(context, YourGoalScreen.routeName);
      }
    } catch (e) {
      print("Error saving profile data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      // 🌟 تطبيق خلفية الثيم الداكن
      backgroundColor: AppColors.blackColor, 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 15,left: 15, top: 25, bottom: 25),
            child: Column(
              children: [
                // Placeholder for the image
                Image.network(
                    "https://placehold.co/${media.width * 0.75}x250/92A3FD/1D1617?text=Complete+Profile",
                    width: media.width * 0.75,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_pin_circle, size: 100, color: AppColors.primaryColor1),
                ),
                const SizedBox(height: 15),
                Text(
                  "لنكمل ملفك الشخصي",
                  style: TextStyle(
                    // 🌟 تطبيق لون النص الأبيض للثيم الداكن
                    color: AppColors.whiteColor, 
                    fontSize: 24, // زيادة حجم النص قليلاً
                    fontWeight: FontWeight.w700
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "سيساعدنا هذا على معرفة المزيد عنك!",
                  style: TextStyle(
                    // 🌟 تطبيق لون النص الثانوي (الرمادي الفاتح) للثيم الداكن
                    color: AppColors.darkGrayColor, 
                    fontSize: 14, // زيادة حجم النص قليلاً
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 25),

                // Gender Selection Field
                Container(
                  decoration: BoxDecoration(
                      // 🌟 خلفية الحقل داكنة
                      color: AppColors.cardBackgroundColor, 
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Container(
                          alignment: Alignment.center,
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Image.network(
                            "https://placehold.co/20x20/00C4CC/1D1617?text=G",
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            color: AppColors.accentColor, // لون الأيقونة
                             errorBuilder: (context, error, stackTrace) => const Icon(Icons.wc, size: 20, color: AppColors.accentColor),
                          )),
                      Expanded(child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender, 
                          dropdownColor: AppColors.cardBackgroundColor, // 🌟 خلفية القائمة المنسدلة داكنة
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.darkGrayColor),
                          items: _genders.map((name) => DropdownMenuItem(value:name,child: Text(
                            name,
                            // 🌟 نص الخيارات أبيض
                            style: const TextStyle(color: AppColors.whiteColor,fontSize: 14), 
                          ))).toList(), 
                          onChanged: (value) {
                             setState(() {
                               _selectedGender = value;
                             });
                          },
                          isExpanded: true,
                          // 🌟 نص المساعدة رمادي فاتح
                          hint: const Text("اختر النوع",style: TextStyle(color: AppColors.darkGrayColor,fontSize: 14)), 
                        ),
                      )),
                      const SizedBox(width: 8)
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Date of Birth Field (using Date Picker)
                InkWell(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer( 
                    child: RoundTextField(
                      hintText: "تاريخ الميلاد (يوم/شهر/سنة)",
                      icon: "assets/icons/calendar_icon.png",
                      textInputType: TextInputType.text,
                      controller: _dobTextController,
                      isReadOnly: true, // إضافة isReadOnly لـ AbsorbPointer
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Weight Field
                RoundTextField(
                  hintText: "الوزن (كجم)",
                  icon: "assets/icons/weight_icon.png",
                  textInputType: TextInputType.number,
                  controller: _weightController,
                ),
                const SizedBox(height: 15),

                // Height Field
                RoundTextField(
                  hintText: "الطول (سم)",
                  icon: "assets/icons/swap_icon.png",
                  textInputType: TextInputType.number,
                  controller: _heightController,
                ),
                const SizedBox(height: 35),

                // Button to save data and proceed
                SizedBox(
                  width: media.width,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      // 🌟 تدرج لوني لزر "التالي"
                      gradient: const LinearGradient(
                        colors: AppColors.primaryG,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor1.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: saveProfile, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // لجعل التدرج ظاهرًا
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        "التالي >",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 5. Main App Widget (لتشغيل العرض)
// =========================================================================

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Complete Profile',
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor1, 
          background: AppColors.blackColor,
        ),
        useMaterial3: true,
      ),
      routes: {
        CompleteProfileScreen.routeName: (context) => const CompleteProfileScreen(),
        YourGoalScreen.routeName: (context) => const YourGoalScreen(),
      },
      // تشغيل واجهة إكمال الملف الشخصي مباشرة
      home: const CompleteProfileScreen(), 
    );
  }
}
