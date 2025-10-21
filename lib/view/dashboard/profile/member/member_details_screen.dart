// member_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

// تعريف الألوان (لضمان التناسق)
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); 
  static const Color darkGrayColor = Color(0xFFC0C0C0); 
  static const Color primaryColor1 = Color(0xFF92A3FD); // أزرق/بنفسجي
  static const Color accentColor = Color(0xFF00C4CC); // تركواز (للتأكيد)
  static const Color cardBackgroundColor = Color(0xFF2E2E2E); // رمادي غامق جديد
  static const Color redColor = Color(0xFFEA4E79); // أحمر للحالات الحرجة
  static const Color highlightColor = Color(0xFF00BFFF); // لون إبراز جديد
}

// -------------------------------------------------------------------------

class MemberDetailsScreen extends StatelessWidget {
  static const String routeName = "/MemberDetailsScreen";
  
  // 🔥 البيانات يتم تمريرها كـ Map إلى Constructor
  final Map<String, dynamic> memberData;
  
  const MemberDetailsScreen({Key? key, required this.memberData}) : super(key: key);
  
  // دالة مساعدة لتحديد لون مؤشر كتلة الجسم (BMI)
  Color _getBmiColor(String bmiString) {
    final bmi = double.tryParse(bmiString) ?? 0.0;
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi >= 18.5 && bmi <= 24.9) return Colors.greenAccent;
    if (bmi >= 25.0 && bmi <= 29.9) return Colors.orangeAccent;
    return AppColors.redColor;
  }
  
  // دالة بناء صف التفاصيل
  Widget _buildDetailRow(IconData icon, String label, String value, {Color valueColor = AppColors.whiteColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor1, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.darkGrayColor,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = memberData['name'] ?? 'Unknown Member';
    final String bmiValue = memberData['bmi'] ?? '--';
    final Color bmiColor = _getBmiColor(bmiValue);
    
    // تنسيق التاريخ
    Timestamp? regTimestamp = memberData['registration_date'] as Timestamp?;
    String regDate = 'N/A';
    if (regTimestamp != null) {
        regDate = DateFormat('MMM d, yyyy HH:mm').format(regTimestamp.toDate());
    }

    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        backgroundColor: AppColors.blackColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        title: Text(
          "$name's Profile",
          style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📝 بطاقة الملخص الرئيسية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor1.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.fitness_center, size: 60, color: AppColors.accentColor),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Registration Date: $regDate",
                    style: const TextStyle(color: AppColors.darkGrayColor, fontSize: 12),
                  ),
                  const Divider(height: 30, color: AppColors.darkGrayColor),

                  // 🔥 تفاصيل الجسم الحيوية
                  _buildDetailRow(Icons.male, "Gender", memberData['gender'] ?? 'N/A'),
                  _buildDetailRow(Icons.cake, "Age", "${memberData['age'] ?? '--'} years"),
                  _buildDetailRow(Icons.height, "Height", "${memberData['height'] ?? '--'} cm"),
                  _buildDetailRow(Icons.monitor_weight, "Weight", "${memberData['weight'] ?? '--'} kg"),
                  
                  // 🔥 BMI مع التمييز
                  _buildDetailRow(
                    Icons.trending_up, 
                    "BMI", 
                    bmiValue, 
                    valueColor: bmiColor
                  ),
                ],
              ),
            ),
            
            // 📞 قسم الإجراءات (يمكن تطويره لزر تعديل)
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // يمكنك إضافة منطق التعديل هنا (Navigate to Edit Screen)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Future Feature: Edit Profile"))
                );
              },
              icon: const Icon(Icons.edit, color: AppColors.blackColor),
              label: const Text(
                "Edit Profile Data", 
                style: TextStyle(color: AppColors.blackColor, fontSize: 16)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlightColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // ⚠️ ملاحظة: يمكنك إضافة قسم جديد هنا لتاريخ التدريبات
          ],
        ),
      ),
    );
  }
}