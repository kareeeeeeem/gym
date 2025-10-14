import 'package:fitnessapp/view/dashboard/profile/ContactUsView.dart';
import 'package:fitnessapp/view/dashboard/profile/kareemEmda.dart';
import 'package:fitnessapp/view/dashboard/profile/sendNotifiactions.dart';
import 'package:fitnessapp/view/welcome/on_boarding/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
// 💡 يجب عليك إضافة حزمة 'url_launcher' في pubspec.yaml لتشغيل الروابط
import 'package:url_launcher/url_launcher.dart'; 

// =========================================================================
// 1. Color Definitions (AppColors)
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
}

// =========================================================================
// 2. Core Widgets Definitions
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
    // ... (Button UI remains the same)
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
  // ... (TitleSubtitleCell remains the same) ...
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentColor)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.darkGrayColor)),
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
  final IconData iconData; 
  final String title;
  final VoidCallback? onPressed;
  final Widget? trailing; 

  const SettingRow({Key? key, required this.iconData, required this.title, required this.onPressed, this.trailing}) : super(key: key);

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
              iconData, 
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
// 3. PlaceholderPage (Crucial for Scrolling)
// =========================================================================

class PlaceholderPage extends StatelessWidget {
  final String title;
  final Widget content;
  const PlaceholderPage({super.key, required this.title, required this.content});

  // ✅ تم التأكد من استخدام SingleChildScrollView لتمكين التمرير في جميع الصفحات
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
      body: SingleChildScrollView( // 💡 هذا يضمن التمرير
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
          // ContentRow(label: "Date of Birth", value: userData['dob'] ?? "N/A"),
          ContentRow(label: "Gender", value: userData['gender'] ?? "N/A"),
          // ContentRow(label: "Goal", value: userData['goal'] ?? "N/A"),
          // ContentRow(label: "Height (cm)", value: userData['height'] ?? "N/A"),
          // ContentRow(label: "Weight (kg)", value: userData['weight'] ?? "N/A"),
          // ContentRow(label: "Age (years)", value: userData['age'] ?? "N/A"),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح.')));
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
          // 💡 لاحظ أن الإيميل هنا قابل للتعديل ولكنه يتطلب إعادة مصادقة في Firebase Auth لتحديثه كإيميل رئيسي
          EditInputField(label: "Email", controller: _emailController, keyboardType: TextInputType.emailAddress), 
          // EditInputField(label: "Date of Birth (DD/MM/YYYY)", controller: _dobController, keyboardType: TextInputType.datetime),
          // EditInputField(label: "Gender", controller: _genderController),
          // EditInputField(label: "Goal", controller: _goalController),
          // EditInputField(label: "Height (cm)", controller: _heightController, keyboardType: TextInputType.number),
          // EditInputField(label: "Weight (kg)", controller: _weightController, keyboardType: TextInputType.number),
          // EditInputField(label: "Age (years)", controller: _ageController, keyboardType: TextInputType.number),
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
  Widget build(BuildContext context) => const PlaceholderPage(
    title: "Achievements",
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your fitness milestones:', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
        SizedBox(height: 20),
        ContentRow(label: "Current Streak", value: "🔥 14 Days"),
        ContentRow(label: "Total Workouts", value: "115 Workouts"),
        ContentRow(label: "Best Weight Loss", value: "5 kg in 1 Month"),
        SizedBox(height: 20),
        Text("Badges Earned:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        SizedBox(height: 10),
        Wrap( 
          spacing: 10,
          children: [
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
  final bool isAdmin; 

  const SettingView({super.key, required this.onLogout, required this.isAdmin});
  

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  // ... (Logic remains the same, relies on PlaceholderPage scrolling) ...
  final bool _darkModeEnabled = true; 

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
        const SizedBox(height: 30),
        const Text("Security:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.whiteColor)),
        
        if (widget.isAdmin) 
            SettingRow(
              iconData: Icons.security, 
              title: "Manage Admins", 
              onPressed: () {
                // ✅ التوجيه إلى شاشة إدارة المدراء
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAdminsView()));
              }
            ),
        SettingRow(
          iconData: Icons.lock, 
          title: "Change Password",
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordView()));
          }
        ),
        // SettingRow(
        //   iconData: Icons.fingerprint, 
        //   title: "Enable Biometrics", 
        //   onPressed: () => _showInternalSnackbar(context, "Enable Biometrics")
        // ),
        const SizedBox(height: 30),
        RoundButton(title: "Logout", type: RoundButtonType.secondaryBG, onPressed: widget.onLogout),
      ],
    ),
  );
}

// =========================================================================
// 4. ChangePasswordView
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
    print('DEBUG_PASSWORD: Attempting to update password.');

    if (user == null || user.email == null) {
      print('DEBUG_PASSWORD: User is null or email is missing.');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ المستخدم غير مسجل الدخول أو البريد غير متوفر.')));
      return;
    }
    
    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      print('DEBUG_PASSWORD: New passwords do not match.');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ كلمة المرور الجديدة وتأكيدها غير متطابقتين.')));
      return;
    }

    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    
    if (newPassword.length < 6) {
      print('DEBUG_PASSWORD: New password too short.');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل.')));
      return;
    }


    try {
      print('DEBUG_PASSWORD: Re-authenticating user: ${user.email}');
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: currentPassword
      );
      
      await user.reauthenticateWithCredential(credential);
      print('DEBUG_PASSWORD: Re-authentication successful. Updating password...');
      await user.updatePassword(newPassword);

      print('DEBUG_PASSWORD: Password updated successfully.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم تحديث كلمة المرور بنجاح!')));
        Navigator.pop(context); 
      }

    } on FirebaseAuthException catch (e) {
      print('DEBUG_PASSWORD: FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage = 'حدث خطأ غير معروف.';
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        errorMessage = '❌ كلمة المرور الحالية غير صحيحة.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = '❌ لأسباب أمنية، يجب إعادة تسجيل الدخول (تسجيل خروج ثم دخول) قبل محاولة تغيير كلمة المرور.';
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      
    } catch (e) {
      print('DEBUG_PASSWORD: General Error: $e');
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
// 5. ManageAdminsView (RE-DESIGNED & FIXED)
// =========================================================================

class ManageAdminsView extends StatefulWidget {
  const ManageAdminsView({super.key});

  @override
  State<ManageAdminsView> createState() => _ManageAdminsViewState();
}

class _ManageAdminsViewState extends State<ManageAdminsView> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoadingAction = false;
  final currentUserEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // 1. Function to find user by email and toggle admin status
  void _toggleAdminRole(bool makeAdmin) async {
    final email = _emailController.text.trim().toLowerCase();
    print('DEBUG_ADMIN: Attempting to toggle role for email: $email, makeAdmin: $makeAdmin');

    if (email.isEmpty || !email.contains('@')) {
      _showSnackbar('❌ يرجى إدخال بريد إلكتروني صحيح.');
      print('DEBUG_ADMIN: Invalid email format.');
      return;
    }

    // Protection against modifying current user's role
    if (email == currentUserEmail) {
      _showSnackbar('❌ لا يمكنك تعديل صلاحياتك كـ Admin عبر هذه الشاشة. أنت الأدمن الأصلي.');
      print('DEBUG_ADMIN: Attempt to modify current user\'s role blocked.');
      return;
    }

    setState(() => _isLoadingAction = true);

    try {
      // 1. Search for user by email (Requires creating an index in Firestore console)
      print('DEBUG_ADMIN: Searching for user document by email...');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showSnackbar('❌ لم يتم العثور على مستخدم مسجل بهذا الإيميل: $email. تأكد من أن المستخدم قام بتسجيل الدخول مرة واحدة على الأقل وأن الإيميل مسجل في Firestore.');
        print('DEBUG_ADMIN: User document not found for email: $email');
        return;
      }

      final userId = querySnapshot.docs.first.id;
      final existingData = querySnapshot.docs.first.data();
      print('DEBUG_ADMIN: User found. UID: $userId, Current isAdmin status: ${existingData['isAdmin']}');

      // 2. Update the role
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'isAdmin': makeAdmin,
        'adminAssignedBy': makeAdmin
            ? currentUserEmail ?? 'Unknown Admin'
            : FieldValue.delete(), // حذف الحقل عند إزالة الصلاحية
        'email': email, // تأكيد وجود الإيميل في الحقل
      }, SetOptions(merge: true));

      print('DEBUG_ADMIN: Firestore update successful.');

      String action = makeAdmin ? 'تعيين' : 'إزالة صلاحيات';
      _showSnackbar('✅ تم $action المستخدم $email بنجاح! قد تحتاج بضع ثوانٍ لتحديث القائمة.');
      _emailController.clear();
      setState(() {}); 

    } on FirebaseException catch (e) {
      _showSnackbar('❌ فشل العملية: ${e.message}');
      print('DEBUG_ADMIN: FirebaseException: ${e.code} - ${e.message}');
    } catch (e) {
      _showSnackbar('❌ حدث خطأ غير متوقع: $e');
      print('DEBUG_ADMIN: General Error: $e');
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: "Manage Admins",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
           'make and remofe Admins',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.whiteColor)
          ),
          const SizedBox(height: 20),
          
          // Input Field
          EditInputField(
            label: "Enter user email to set/remove permission Admin",
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: RoundButton(
                  title: _isLoadingAction ? 'Currently Hiring...' : "set Admin",
                  type: RoundButtonType.primaryBG,
                  onPressed: _isLoadingAction ? null : () => _toggleAdminRole(true),
                  height: 45,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RoundButton(
                  title: _isLoadingAction ? 'Removing...' : "Remove ",
                  type: RoundButtonType.secondaryBG,
                  onPressed: _isLoadingAction ? null : () => _toggleAdminRole(false),
                  height: 45,
                ),
              ),
            ],
          ),
          
          const Divider(color: AppColors.lightGrayColor, height: 40),
          
          // List of current Admins
          const Text('List of current Admins:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryColor)),
          const SizedBox(height: 15),
          
          StreamBuilder<QuerySnapshot>(
            // 💡 StreamBuilder لعرض المدراء فقط (isAdmin == true)
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isAdmin', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
              }
              if (snapshot.hasError) {
                print('DEBUG_ADMIN_LIST: Error loading admins: ${snapshot.error}');
                return Text('خطأ في جلب القائمة: ${snapshot.error}', style: const TextStyle(color: AppColors.redColor));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('لا يوجد مدراء حالياً.', style: TextStyle(color: AppColors.darkGrayColor));
              }

              final admins = snapshot.data!.docs;
              print('DEBUG_ADMIN_LIST: ${admins.length} admins loaded.');

              return ListView.builder(
                // ✅ ضروري ليعمل داخل SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), 
                shrinkWrap: true,
                itemCount: admins.length,
                itemBuilder: (context, index) {
                  final adminDoc = admins[index];
                  final adminData = adminDoc.data() as Map<String, dynamic>;
                  // 💡 FIX: نعتمد على الإيميل من Firestore كأولوية، ونرجع للـ ID في حالة الضرورة القصوى فقط
                  final email = adminData['email']?.toString() ?? 'No Email (UID: ${adminDoc.id})'; 
                  final isCurrentUser = adminDoc.id == currentUserId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ContentRow(
                      label: isCurrentUser ? 'You are the current admin)' : 'ِ Admin number ${index + 1}',
                      value: email,
                      // منع الضغط على الصف الخاص بالأدمن الحالي
                      onTap: isCurrentUser ? () => _showSnackbar('You cannot delete your permissions as Admin.') : null, 
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// =========================================================================
// 6. Link Launching Function (FIXED)
// =========================================================================

// ✅ الدالة الصحيحة لتشغيل الروابط
void _showLinkAction(BuildContext context, String linkType, String url) async {
    print('DEBUG_LINK: Attempting to launch $linkType with URL: $url');
    // 💡 يجب إضافة حزمة 'url_launcher' في pubspec.yaml وتنفيذ flutter pub get
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('DEBUG_LINK: Launch successful.');
      } else {
         if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ فشل فتح الرابط ($linkType). تأكد من صلاحية الرابط: $url')));
         }
         print('DEBUG_LINK: Cannot launch URL.');
      }
    } catch (e) {
       if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ حدث خطأ غير متوقع أثناء فتح الرابط.')));
       }
       print('DEBUG_LINK: General Error during launch: $e');
    }
}



// =========================================================================
// 8. UserProfile Code (Final Fixes and Data Loading - FIXED)
// =========================================================================

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  
  bool _isAdmin = false; 
  String _fullName = "Loading...";
  String _goal = "---";
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

// داخل class _UserProfileState
void _logout() async {
  print('DEBUG_AUTH: Attempting to log out...');
  try {
    // 1. تسجيل الخروج من Firebase
    await FirebaseAuth.instance.signOut();
    print('DEBUG_AUTH: Logout successful.');
    
    // 2. 🚀 التنقل إلى شاشة الدخول ومسح كل الصفحات
    if (mounted) {
      // ⚠️ يجب عليك تعريف شاشة الدخول (LoginScreen) هنا
      // افترض أن اسم الشاشة هو LoginScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const StartScreen(), // ⬅️ ضع اسم شاشة الدخول الصحيح هنا
        ),
        (Route<dynamic> route) => false, // يزيل كل صفحات التطبيق السابقة
      );
      
      // يمكنك إزالة الـ SnackBar هنا إذا أردت، لأن التنقل سيغطي الشاشة
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged out successfully!")));
    }
    
  } catch (e) {
    print('DEBUG_AUTH: Error during logout: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error during logout: $e")));
    }
  }
}
// ✅ تم إصلاح مشكلة عدم جلب البيانات وضمان قراءة الإيميل 
void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG_FETCH: Starting data fetch. User: ${user != null ? user.uid : "null"}');

    if (user == null) {
      print('DEBUG_FETCH: Guest user detected.');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fullName = "Guest User";
          _email = "guest@example.com";
        });
      }
      return;
    }

    // 💡 استخدام إيميل Firebase Auth كقيمة افتراضية
    final userEmail = user.email?.toLowerCase() ?? 'No Email (Auth)';
    
    try {
      print('DEBUG_FETCH: Fetching user document from Firestore for UID: ${user.uid}');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      String defaultName = user.displayName ?? userEmail.split('@')[0];
      Map<String, dynamic> data = userDoc.data() ?? {};
      
      // دالة مساعدة لضمان قراءة البيانات بشكل آمن كـ String
      String readAsString(dynamic value, String defaultValue) {
        if (value == null) return defaultValue;
        return value.toString();
      }

      if (mounted) {
        setState(() {
          // 💡 التحقق من الأدمن (يعتمد على Firestore فقط)
          bool isFirebaseAdmin = data['isAdmin'] as bool? ?? false; 
          _isAdmin = isFirebaseAdmin; 
          
          // ✅ جلب وتعبئة جميع البيانات الشخصية باستخدام الدالة الآمنة
          _fullName = readAsString(data['fullName'], defaultName);
          _goal = readAsString(data['goal'], '---');
          _height = readAsString(data['height'], '---');
          _weight = readAsString(data['weight'], '---');
          _age = readAsString(data['age'], '---');
          _dob = readAsString(data['dob'], '---');
          _gender = readAsString(data['gender'], '---');
          
          // 💡 القيمة الأساسية للإيميل هي من Firestore، مع العودة إلى Firebase Auth كاحتياط
          _email = readAsString(data['email'], userEmail); 

          _isLoading = false;
          print('DEBUG_FETCH: Data loaded successfully. IsAdmin: $_isAdmin, Email: $_email');
        });
      }
      
    } on FirebaseException catch (e) {
      print('DEBUG_FETCH: Firestore Error: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fullName = user.displayName ?? userEmail.split('@')[0];
          _email = userEmail;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error loading data: ${e.message}')));
        });
      }
    } catch (e) {
       print('DEBUG_FETCH: General Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fullName = user.displayName ?? userEmail.split('@')[0];
          _email = userEmail;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error loading data: $e')));
        });
      }
    }
}

  void _saveUserData(UserData updatedData) async {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG_SAVE: Starting data save. User: ${user != null ? user.uid : "null"}');
    if (user == null) {
      print('DEBUG_SAVE: Save failed - User is null.');
      return;
    }
    
    try {
      print('DEBUG_SAVE: Updating Firestore document for UID: ${user.uid}');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        updatedData.map((key, value) => MapEntry(key, value)), 
        SetOptions(merge: true) 
      );
      print('DEBUG_SAVE: Firestore update successful.');
      
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
      
    } on FirebaseException catch (e) {
      print('DEBUG_SAVE: Firestore Error: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error saving data: ${e.message}')));
      }
    } catch (e) {
      print('DEBUG_SAVE: General Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error saving data: $e')));
      }
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
    
    // ✅ تم جعل شاشة UserProfile تسمح بالتمرير
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.blackColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      body: SingleChildScrollView( // 💡 هذا يضمن التمرير
        padding: const EdgeInsets.all(25),
        
        child: Column(

          mainAxisSize: MainAxisSize.min, // 💡 أضف هذه الخاصية
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Image 
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.cardBackgroundColor,
              child: Text(_fullName.isNotEmpty ? _fullName[0] : 'U', style: const TextStyle(fontSize: 40, color: AppColors.accentColor)),
            ),
            const SizedBox(height: 10),
            Text(_fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.whiteColor)),
            Text(_email, style: const TextStyle(fontSize: 14, color: AppColors.darkGrayColor)),
            const SizedBox(height: 25),

            // Fitness Stats Card
            // Container(
            //   padding: const EdgeInsets.all(15),
            //   decoration: BoxDecoration(
            //     color: AppColors.cardBackgroundColor,
            //     borderRadius: BorderRadius.circular(15),
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceAround,
            //     children: [
            //       TitleSubtitleCell(title: "${_weight} kg", subtitle: "Weight"),
            //       TitleSubtitleCell(title: "${_height} cm", subtitle: "Height"),
            //       TitleSubtitleCell(title: "${_age} yrs", subtitle: "Age"),
            //     ],
            //   ),
            // ),
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
                    iconData: Icons.person, 
                    title: "Personal Data",
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalDataView(
                        userData: currentData, 
                        onDataSaved: _saveUserData
                      )));
                    }
                  ),
                  // زر إدارة المدراء يظهر إذا كان المستخدم مديراً 
                  if (_isAdmin) 
                    SettingRow(
                      iconData: Icons.security, 
                      title: "Manage Admins",
                      onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAdminsView()));
                      },
                      trailing: const Icon(Icons.security, color: AppColors.redColor), 
                    ),

                    if (_isAdmin) 
                    SettingRow(
                      iconData: Icons.notification_add, 
                      title: "AdminNotificationScreen",
                      onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminNotificationPage()));
                      },
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
                  // SettingRow(
                  //   iconData: Icons.notifications, 
                  //   title: "Push Notifications", 
                  //   onPressed: () => _showInternalSnackbar(context, "Notifications Toggle"), 
                  //   trailing: Switch(value: true, onChanged: (val) { _showInternalSnackbar(context, "Notifications: ${val ? 'ON' : 'OFF'}"); }, activeColor: AppColors.accentColor),
                  // ),
                  SettingRow(
                    iconData: Icons.settings, 
                    title: "Settings", 
                    onPressed: () {
                       // ✅ تمرير حالة المدير إلى SettingView
                       Navigator.push(context, MaterialPageRoute(builder: (context) => SettingView(onLogout: _logout, isAdmin: _isAdmin)));
                    }
                  ),
                  SettingRow(
                    iconData: Icons.call, 
                    title: "About Ego Gym", 
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsView()));
                    }
                  ),
                  SettingRow(
                    iconData: Icons.code, 
                    title: "About the Developer", 
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) =>  const HowUsView()));
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Colors.transparent, 
        elevation: 0, // نلغي الظل
        height:  10, // ارتفاع بسيط ليرفع الزر قليلاً
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[], // لا توجد عناصر فعلية
        ),
      ),    
    );
  }
}