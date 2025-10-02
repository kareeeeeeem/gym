import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_core/firebase_core.dart'; 
import 'dart:async'; 

// =========================================================================
// 1. Color Definitions (AppColors) - Unified Dark Theme
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); // Dark Background
  static const Color darkGrayColor = Color(0xFFC0C0C0); 
  static const Color primaryColor = Color(0xFF92A3FD); 
  static const Color accentColor = Color(0xFF00C4CC); 
  static const Color cardBackgroundColor = Color(0xFF222222); 
  static const Color lightGrayColor = Color(0xFF333333); 
  static const Color redColor = Color(0xFFEA4E79); 
  
  static const List<Color> primaryG = [
    Color(0xFF92A3FD), 
    Color(0xFF9DCEFF), 
  ];
  
  static const List<Color> secondaryG = [
    Color(0xFFC58BF2), 
    Color(0xFFEEA4CE),
  ];
  
  static const Color grayColor = Color(0xFF7B6F72); 
}

// =========================================================================
// 2. Core Widgets Definitions (بدون تغيير)
// =========================================================================

enum RoundButtonType { primaryBG, secondaryBG }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback? onPressed;
  final double height;
  final double width;

  const RoundButton({
    super.key,
    required this.title,
    required this.type,
    required this.onPressed,
    this.height = 50, 
    this.width = double.maxFinite
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: type == RoundButtonType.primaryBG ? AppColors.primaryG : AppColors.secondaryG,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(999), 
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.4), 
                blurRadius: 10, 
                offset: const Offset(0, 4))
          ]),
      child: MaterialButton(
        minWidth: double.maxFinite,
        height: height,
        onPressed: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textColor: AppColors.whiteColor,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.whiteColor,
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class TitleSubtitleCell extends StatelessWidget {
  final String title;
  final String subtitle;

  const TitleSubtitleCell({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: [
          Text(
            title, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentColor) 
          ),
          Text(
            subtitle, 
            style: const TextStyle(fontSize: 12, color: AppColors.darkGrayColor) 
          ),
        ],
      ),
    );
  }
}

class EditInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;

  const EditInputField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.whiteColor), 
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.darkGrayColor), 
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            borderSide: BorderSide(color: AppColors.accentColor, width: 2), 
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          fillColor: AppColors.cardBackgroundColor, 
          filled: true,
        ),
      ),
    );
  }
}

class ContentRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const ContentRow({super.key, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: AppColors.darkGrayColor)), 
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: onTap != null ? AppColors.primaryColor : AppColors.whiteColor, 
                            decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (onTap != null) 
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryColor, )
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.lightGrayColor, height: 20), 
          ],
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onPressed;
  final Widget? trailing; 

  const SettingRow({Key? key, required this.icon, required this.title, required this.onPressed, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              title == "Add Admins" ? Icons.security : Icons.settings, 
              size: 20, 
              color: AppColors.primaryColor
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.whiteColor, 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.darkGrayColor), 
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 3. Edit and List Screens (بدون تغيير)
// =========================================================================

class PlaceholderPage extends StatelessWidget {
  final String title;
  final Widget content;
  const PlaceholderPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor, 
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: AppColors.whiteColor)), 
        backgroundColor: AppColors.blackColor, 
        iconTheme: const IconThemeData(color: AppColors.whiteColor), 
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: content,
      ),
    );
  }
}

typedef UserData = Map<String, String>;

class PersonalDataView extends StatelessWidget {
  final UserData userData;
  final Function(UserData) onDataSaved;

  const PersonalDataView({
    super.key,
    required this.userData,
    required this.onDataSaved,
  });

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: "Personal Data",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your current profile information:', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
          const SizedBox(height: 20),
          ContentRow(label: "Full Name", value: userData['fullName'] ?? "N/A"),
          ContentRow(label: "Email", value: userData['email'] ?? "N/A"),
          ContentRow(label: "Date of Birth", value: userData['dob'] ?? "N/A"),
          ContentRow(label: "Gender", value: userData['gender'] ?? "N/A"),
          ContentRow(label: "Goal", value: userData['goal'] ?? "N/A"),
          ContentRow(label: "Height (cm)", value: userData['height'] ?? "N/A"),
          ContentRow(label: "Weight (kg)", value: userData['weight'] ?? "N/A"),
          ContentRow(label: "Age (years)", value: userData['age'] ?? "N/A"),
          const SizedBox(height: 30),
          RoundButton(
            title: "Edit Personal Data",
            type: RoundButtonType.primaryBG,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditPersonalDataView(
                initialData: userData,
                onSave: onDataSaved,
              )));
            }
          ),
        ],
      ),
    );
  }
}


class EditPersonalDataView extends StatefulWidget {
  final UserData initialData;
  final Function(UserData) onSave;

  const EditPersonalDataView({super.key, required this.initialData, required this.onSave});

  @override
  State<EditPersonalDataView> createState() => _EditPersonalDataViewState();
}

class _EditPersonalDataViewState extends State<EditPersonalDataView> {
  // ... (Controllers definitions remain the same)
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _genderController;
  late TextEditingController _goalController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['fullName']);
    _emailController = TextEditingController(text: widget.initialData['email']);
    _dobController = TextEditingController(text: widget.initialData['dob']);
    _genderController = TextEditingController(text: widget.initialData['gender']);
    _goalController = TextEditingController(text: widget.initialData['goal']);
    _heightController = TextEditingController(text: widget.initialData['height']);
    _weightController = TextEditingController(text: widget.initialData['weight']);
    _ageController = TextEditingController(text: widget.initialData['age']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _goalController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final updatedData = {
      'fullName': _nameController.text,
      'email': _emailController.text,
      'dob': _dobController.text,
      'gender': _genderController.text,
      'goal': _goalController.text,
      'height': _heightController.text,
      'weight': _weightController.text,
      'age': _ageController.text,
    };

    widget.onSave(updatedData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data saved successfully.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: "Edit Personal Data",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Update your information below:', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
          const SizedBox(height: 20),
          EditInputField(label: "Full Name", controller: _nameController),
          EditInputField(label: "Email", controller: _emailController, keyboardType: TextInputType.emailAddress),
          EditInputField(label: "Date of Birth (DD/MM/YYYY)", controller: _dobController, keyboardType: TextInputType.datetime),
          EditInputField(label: "Gender", controller: _genderController),
          EditInputField(label: "Goal", controller: _goalController),
          EditInputField(label: "Height (cm)", controller: _heightController, keyboardType: TextInputType.number),
          EditInputField(label: "Weight (kg)", controller: _weightController, keyboardType: TextInputType.number),
          EditInputField(label: "Age (years)", controller: _ageController, keyboardType: TextInputType.number),
          const SizedBox(height: 30),
          RoundButton(
            title: "Save Changes",
            type: RoundButtonType.primaryBG,
            onPressed: _saveChanges,
          ),
        ],
      ),
    );
  }
}

class AchievementView extends StatelessWidget {
  const AchievementView({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: "Achievements",
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your fitness milestones:', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
        const SizedBox(height: 20),
        ContentRow(label: "Current Streak", value: "🔥 14 Days"),
        ContentRow(label: "Total Workouts", value: "115 Workouts"),
        ContentRow(label: "Best Weight Loss", value: "5 kg in 1 Month"),
        const SizedBox(height: 20),
        const Text("Badges Earned:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        const SizedBox(height: 10),
        Wrap( 
          spacing: 10,
          children: const [
            Chip(label: Text("Beginner 💪", style: TextStyle(color: AppColors.blackColor)), backgroundColor: AppColors.accentColor),
            Chip(label: Text("Consistency ⭐", style: TextStyle(color: AppColors.blackColor)), backgroundColor: AppColors.primaryColor),
            Chip(label: Text("Marathon Runner 🏃", style: TextStyle(color: AppColors.blackColor)), backgroundColor: AppColors.primaryColor),
          ],
        )
      ],
    ),
  );
}

class SettingView extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingView({super.key, required this.onLogout});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  bool _darkModeEnabled = true; 

  void _showInternalSnackbar(BuildContext context, String action) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Setting clicked: $action')),
     );
  }

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: "Settings",
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("General:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
        SettingRow(
          icon: "assets/icons/p_language.png", 
          title: "Language", 
          onPressed: () => _showInternalSnackbar(context, "Language")
        ),
        SettingRow(
          icon: "assets/icons/p_unit.png", 
          title: "Unit Preference (Kg/Lbs)", 
          onPressed: () => _showInternalSnackbar(context, "Unit Preference")
        ),
        SettingRow(
          icon: "assets/icons/p_theme.png", 
          title: "Dark Mode", 
          onPressed: () {
             setState(() {
                _darkModeEnabled = !_darkModeEnabled;
             });
             _showInternalSnackbar(context, "Dark Mode: ${_darkModeEnabled ? 'Enabled' : 'Disabled'}");
          },
          trailing: Switch(
            value: _darkModeEnabled,
            onChanged: (val) {
              setState(() {
                _darkModeEnabled = val;
              });
              _showInternalSnackbar(context, "Dark Mode: ${val ? 'Enabled' : 'Disabled'}");
            },
            activeColor: AppColors.accentColor, 
            inactiveThumbColor: AppColors.darkGrayColor,
            inactiveTrackColor: AppColors.cardBackgroundColor,
          ),
        ),
        const SizedBox(height: 30),
        const Text("Security:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
        SettingRow(
          icon: "assets/icons/p_password.png",
          title: "Change Password",
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordView()));
          }
        ),
        SettingRow(
          icon: "assets/icons/p_fingerprint.png", 
          title: "Enable Biometrics", 
          onPressed: () => _showInternalSnackbar(context, "Enable Biometrics")
        ),
        const SizedBox(height: 30),
        RoundButton(title: "Logout", type: RoundButtonType.secondaryBG, onPressed: widget.onLogout),
      ],
    ),
  );
}

// =========================================================================
// 4. ChangePasswordView (بدون تغيير)
// =========================================================================

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
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
  
  void _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ المستخدم غير مسجل الدخول أو البريد غير متوفر.')));
      return;
    }
    
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
      // 1. إعادة المصادقة (Re-authentication) لأمان Firebase
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: currentPassword
      );
      
      await user.reauthenticateWithCredential(credential);

      // 2. تحديث كلمة المرور
      await user.updatePassword(newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم تحديث كلمة المرور بنجاح!')));
        Navigator.pop(context); 
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ غير معروف.';
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        errorMessage = '❌ كلمة المرور الحالية غير صحيحة.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = '❌ لأسباب أمنية، يجب إعادة تسجيل الدخول (تسجيل خروج ثم دخول) قبل محاولة تغيير كلمة المرور.';
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
            onPressed: _updatePassword, 
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 5. AddAdminsView (تحديث بالمنطق الحقيقي Firestore)
// =========================================================================
class AddAdminsView extends StatelessWidget {
  const AddAdminsView({super.key});

  // 📌 هذه الدالة هي الآن حقيقية وتُعدّل Firestore
  void _setAdminRole(BuildContext context, String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ يرجى إدخال بريد إلكتروني صالح.')),
      );
      return;
    }
    
    // 1. البحث عن المستخدم في Firestore بواسطة الإيميل (يتطلب index في Firestore)
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: trimmedEmail) // افتراض وجود حقل 'email'
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ المستخدم ($trimmedEmail) غير موجود في قاعدة البيانات.')),
           );
        }
        return;
      }
      
      final docId = result.docs.first.id;

      // 2. تحديث وثيقة المستخدم لجعله مديراً
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isAdmin': true, // تعيين الدور
        'adminAssignedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown Admin', // تسجيل من قام بالتعيين
      });
      
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ تم بنجاح تعيين $trimmedEmail كمدير!')),
         );
      }

    } on FirebaseException catch (e) {
      print("Firestore Error setting admin: $e");
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ فشل تعيين المدير: ${e.message}')),
         );
      }
    } catch (e) {
      print("Generic Error setting admin: $e");
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ حدث خطأ غير متوقع أثناء تعيين المدير.')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    
    return PlaceholderPage(
      title: "Add Admins",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'قم بإدخال البريد الإلكتروني للمستخدم الذي تريد تعيينه كـ "مدير" (Admin). يجب أن يكون المستخدم مسجلاً بالفعل:', 
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
              _setAdminRole(context, emailController.text);
            },
          ),
        ],
      ),
    );
  }
}

// 6. ContactUsView (بدون تغيير)
class ContactUsView extends StatelessWidget {
  static const String gymSlogan = "Get strong with us! Your journey begins now. 💪🌟";
  static const String gymWhatsApp = "+20 100 5235831";
  static const String gymPhone = "010 05235831";
  static const String gymEmail = "egogym.banha@gmail.com";
  static const String gymFacebook = "@egoo.gym (4.4k followers)";
  static const String gymPriceRange = "Medium (\$\$\$ - Recommended)";
  static const String gymLocationAddress = "Street 2, Qism Banha, Second Banha, Before Al-Fahs Bridge in front of Othaim Ego Gym, Benha, Egypt";
  static const String gymLocationLink = "https://bit.ly/egogym-location";

  const ContactUsView({super.key});

  void _showLinkAction(BuildContext context, String linkType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulating opening $linkType link...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: "Contact Ego Gym",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gym Information:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
          const SizedBox(height: 10),
          Text(
            gymSlogan,
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.accentColor), 
          ),
          const Divider(color: AppColors.lightGrayColor, height: 30),
          
          const Text('Contact Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
          const SizedBox(height: 10),
          ContentRow(label: "WhatsApp", value: gymWhatsApp, onTap: () => _showLinkAction(context, "WhatsApp")),
          ContentRow(label: "Phone", value: gymPhone, onTap: () => _showLinkAction(context, "Phone Call")),
          ContentRow(label: "Email", value: gymEmail, onTap: () => _showLinkAction(context, "Email")),
          ContentRow(label: "Facebook Handle", value: gymFacebook, onTap: () => _showLinkAction(context, "Facebook")),
          const Divider(color: AppColors.lightGrayColor, height: 30),

          const Text('Location:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
          const SizedBox(height: 10),
          ContentRow(label: "Address", value: gymLocationAddress),
          ContentRow(label: "Google Maps Link", value: gymLocationLink, onTap: () => _showLinkAction(context, "Google Maps")),
          const Divider(color: AppColors.lightGrayColor, height: 30),

          const Text('Pricing:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
          const SizedBox(height: 10),
          ContentRow(label: "Price Range", value: gymPriceRange),
          const SizedBox(height: 30),
          
          RoundButton(
            title: "Visit Gym Location (Simulated)",
            type: RoundButtonType.primaryBG,
            onPressed: () => _showLinkAction(context, "Gym Location"),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 7. UserProfile Code (تحديث بمنطق Firestore الحقيقي)
// =========================================================================

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  // 📌 قائمة اختبار لمدراء التطوير (يمكن حذفها بعد النشر)
  final List<String> _developerAdmins = const [
      "admin@example.com",     
      "micohelmy5@gmail.com", // ✅ تم وضع بريدك هنا

  ];
  
  bool _isAdmin = false; 

  bool positive = false;
  String _fullName = "Loading...";
  String _goal = "Loading...";
  String _height = "---";
  String _weight = "---";
  String _age = "---";
  String _email = "---";
  String _dob = "---";
  String _gender = "---";
  bool _isLoading = true;
  
  void _showInternalSnackbar(BuildContext context, String action) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Setting clicked: $action')),
     );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // يمكنك توجيه المستخدم لشاشة تسجيل الدخول بعد تسجيل الخروج
        // Navigator.pushAndRemoveUntil(...) 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged out successfully!")));
      }
    } catch (e) {
      print("Logout Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error during logout: $e")));
      }
    }
  }
// 📌 التعديل: جلب حالة الأدمن والبيانات من Firestore بشكل أكثر دقة

// 📌 النسخة المُعدلة لتتبع الأخطاء (Debug Console)
void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    print("DEBUG 1: Starting _fetchUserData. User is: ${user != null ? 'Logged In' : 'NULL'}"); //

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fullName = "Guest User";
          _email = "guest@example.com";
        });
      }
      return;
    }

    final userEmail = user.email?.toLowerCase() ?? '';
    print("DEBUG 2: Current User Email: $userEmail"); //
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      String defaultName = user.displayName ?? userEmail.split('@')[0];
      Map<String, dynamic> data = userDoc.data() ?? {};
      
      print("DEBUG 3: Firestore Document Exists: ${userDoc.exists}"); //

      if (mounted) {
        setState(() {
          // ... (جلب البيانات الأخرى) ...
          
          // 💡 التحقق من الأدمن
          bool isFirebaseAdmin = data['isAdmin'] as bool? ?? false; 
          bool isDeveloperAdmin = _developerAdmins.contains(userEmail); 
          
          _isAdmin = isFirebaseAdmin || isDeveloperAdmin; //
          
          print("DEBUG 4: isFirebaseAdmin (from Firestore): $isFirebaseAdmin"); //
          print("DEBUG 5: isDeveloperAdmin (from local list): $isDeveloperAdmin"); //
          print("DEBUG 6: Final _isAdmin value: $_isAdmin"); //
          
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print("ERROR FETCHING DATA: $e"); //
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fullName = user.displayName ?? userEmail.split('@')[0];
          _email = userEmail;
        });
      }
    }
}

  void _saveUserData(UserData updatedData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Save Error: User not logged in.");
      return;
    }
    
    // 📌 تحديث Firestore (Update Firestore)
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        updatedData, 
        SetOptions(merge: true) // دمج البيانات مع ما هو موجود
      );
      
      // تحديث الحالة المحلية
      if (mounted) {
          setState(() {
              _fullName = updatedData['fullName'] ?? _fullName;
              _goal = updatedData['goal'] ?? _goal;
              _height = updatedData['height'] ?? _height;
              _weight = updatedData['weight'] ?? _weight;
              _age = updatedData['age'] ?? _age;
              _email = updatedData['email'] ?? _email;
              _dob = updatedData['dob'] ?? _dob;
              _gender = updatedData['gender'] ?? _gender;
          });
      }
      print("Data saved to Firestore successfully.");
      
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.blackColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
      );
    }
    
    final currentData = {
      'fullName': _fullName,
      'email': _email,
      'dob': _dob,
      'gender': _gender,
      'goal': _goal,
      'height': _height,
      'weight': _weight,
      'age': _age,
    };
    
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.blackColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Image 
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.cardBackgroundColor,
              child: Text(_fullName.isNotEmpty ? _fullName[0] : 'U', style: const TextStyle(fontSize: 40, color: AppColors.accentColor)),
            ),
            const SizedBox(height: 10),
            Text(_fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
            Text(_email, style: const TextStyle(fontSize: 14, color: AppColors.darkGrayColor)),
            const SizedBox(height: 25),

            // Fitness Stats Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TitleSubtitleCell(title: "${_weight} kg", subtitle: "Weight"),
                  TitleSubtitleCell(title: "${_height} cm", subtitle: "Height"),
                  TitleSubtitleCell(title: "${_age} yrs", subtitle: "Age"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Account List
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
                  const Divider(color: AppColors.lightGrayColor, height: 20),
                  SettingRow(
                    icon: "assets/icons/p_user.png",
                    title: "Personal Data",
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalDataView(
                        userData: currentData, 
                        onDataSaved: _saveUserData
                      )));
                    }
                  ),
                  SettingRow(
                    icon: "assets/icons/p_achievement.png",
                    title: "Achievements",
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementView()));
                    }
                  ),
                  // زر الأدمنز يظهر إذا كان المستخدم مديراً في Firestore أو في قائمة التطوير
                 // ...
                  if (_isAdmin) 
                    SettingRow(
                      // استبدل مسار الأيقونة بـ IconData مؤقت
                      icon: "assets/icons/p_add_user.png", // ابقِ هذا السطر إذا كنت تريد استخدامه
                      title: "Add Admins",
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAdminsView()));
                      },
                      // 💡 التعديل: استخدم أيقونة مدمجة
                      trailing: const Icon(Icons.security, color: AppColors.redColor), 
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings and More List
             Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Notification & Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
                  const Divider(color: AppColors.lightGrayColor, height: 20),
                  SettingRow(
                    icon: "assets/icons/p_notification.png", 
                    title: "Push Notifications", 
                    onPressed: () => _showInternalSnackbar(context, "Notifications Toggle"), 
                    trailing: Switch(value: true, onChanged: (val) { _showInternalSnackbar(context, "Notifications: ${val ? 'ON' : 'OFF'}"); }, activeColor: AppColors.accentColor),
                  ),
                  SettingRow(
                    icon: "assets/icons/p_setting.png", 
                    title: "Settings", 
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => SettingView(onLogout: _logout)));
                    }
                  ),
                  SettingRow(
                    icon: "assets/icons/p_contact.png", 
                    title: "Contact Ego Gym", 
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsView()));
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}