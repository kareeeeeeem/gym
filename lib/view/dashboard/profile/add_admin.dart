// =========================================================================
// AddAdminsView (الكود المُعدَّل لاستدعاء Firebase Cloud Function)
// =========================================================================
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fitnessapp/const/common_widgets/round_button.dart';
import 'package:fitnessapp/view/dashboard/profile/user_profile.dart' hide RoundButton, RoundButtonType;
import 'package:flutter/material.dart';

// ⚠️ ملاحظة: لا يزال يتعين عليك التأكد من أن كلاسات (RoundButton, PlaceholderPage, EditInputField, AppColors) متاحة ومستوردة بشكل صحيح.

class AddAdminsView extends StatelessWidget {
  const AddAdminsView({super.key});

  // 🚀 (2) دالة لاستدعاء Cloud Function وتعيين دور المدير
  void _setAdminRole(BuildContext context, String email) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final emailTrimmed = email.trim();

    if (emailTrimmed.isEmpty || !emailTrimmed.contains('@')) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('❌ يرجى إدخال بريد إلكتروني صالح.')),
      );
      return;
    }

    // إظهار رسالة "قيد التنفيذ"
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('⏳ جاري تعيين ${emailTrimmed} كمدير...'), duration: const Duration(seconds: 5)),
    );
    
    try {
        // استدعاء دالة Firebase Cloud Function
        final HttpsCallable callable = 
            FirebaseFunctions.instance.httpsCallable('setUserAdminRole');
            
        final result = await callable.call(<String, dynamic>{
            'email': emailTrimmed, 
            'admin': true
        });

        // 🥳 النجاح
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('✅ تم تعيين ${emailTrimmed} كمدير بنجاح!'))
        );
        // العودة إلى الشاشة السابقة بعد النجاح
        if (context.mounted) {
            Navigator.pop(context); 
        }
        
    } on FirebaseFunctionsException catch (e) {
        // 💔 فشل (يتم التقاط الأخطاء من Node.js)
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('❌ فشل تعيين المدير: ${e.message}'))
        );
    } catch (e) {
        // خطأ عام
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('❌ حدث خطأ غير متوقع. جرب مجدداً.'))
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    
    return PlaceholderPage(
      title: "Add Admins",
      content: Padding(
        padding: const EdgeInsets.all(20.0), // إضافة مساحة حول المحتوى
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // لجعل الزر يأخذ عرض الشاشة
          children: [
            const Text(
              'قم بإدخال البريد الإلكتروني للمستخدم الذي تريد تعيينه كـ "مدير" (Admin):', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
            ),
            const SizedBox(height: 20),
            EditInputField(
              label: "User Email", 
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            RoundButton(
              title: "Grant Admin Access",
              type: RoundButtonType.secondaryBG,
              onPressed: () {
                _setAdminRole(context, emailController.text.trim());
              },
            ),
          ],
        ),
      ),
    );
  }
}