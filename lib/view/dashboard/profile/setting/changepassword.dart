// =========================================================================
// ChangePasswordView (مُعدَّل)
// =========================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnessapp/view/dashboard/profile/Profile.dart';
import 'package:flutter/material.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  // controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // 📌 دالة تحديث كلمة المرور الفعلية
  void _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ المستخدم غير مسجل الدخول.')));
      return;
    }
    
    // 1. تحقق من تطابق كلمات المرور الجديدة
    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ كلمة المرور الجديدة وتأكيدها غير متطابقتين.')));
      return;
    }

    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    
    if (newPassword.length < 6) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل.')));
      return;
    }


    try {
      // 2. إعادة المصادقة باستخدام كلمة المرور الحالية (لأمان Firebase)
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: currentPassword
      );
      
      await user.reauthenticateWithCredential(credential);

      // 3. تحديث كلمة المرور
      await user.updatePassword(newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم تحديث كلمة المرور بنجاح!')));
        Navigator.pop(context); // العودة إلى صفحة الإعدادات
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ غير معروف.';
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        errorMessage = '❌ كلمة المرور الحالية غير صحيحة أو المستخدم غير موجود.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = '❌ لأسباب أمنية، يجب إعادة تسجيل الدخول لتغيير كلمة المرور.';
      }
      print("Password Update Error: ${e.code}");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      
    } catch (e) {
       print("Generic Password Update Error: $e");
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ فشل التحديث. تأكد من أنك متصل بالإنترنت.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: "Change Password",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your new password details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
          const SizedBox(height: 20),
          EditInputField(label: "Current Password", controller: _currentPasswordController, isPassword: true),
          EditInputField(label: "New Password", controller: _newPasswordController, isPassword: true),
          EditInputField(label: "Confirm New Password", controller: _confirmPasswordController, isPassword: true),
          const SizedBox(height: 30),
          RoundButton(
            title: "Update Password",
            type: RoundButtonType.primaryBG,
            onPressed: _updatePassword, // 📌 ربط الدالة الجديدة
          ),
        ],
      ),
    );
  }
}