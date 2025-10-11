import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitnessapp/view/dashboard/Room/GymRoomsScreen.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/aus/signup/signup_screen.dart';
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 💡 Import the sign-up screen to enable navigation


// =========================================================================
// 1. Colors and Utility Components
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color grayColor = Color(0xFF7B6F72);
  static const Color lightGrayColor = Color(0xFFF7F8F8);
  static const Color primaryColor1 = Color(0xFF92A3FD); 
  static const Color accentColor = Color(0xFFC58BF2); // Accent color for user screen
  static const Color redColor = Color(0xFFEA4E79);
}

// =========================================================================
// 2. Main User Login Screen (UserLoginScreen)
// =========================================================================

class UserLoginScreen extends StatefulWidget {
  static const String routeName = '/user_login';
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _firestore = FirebaseFirestore.instance; // ⬅️ أضف هذا السطر


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Sign In function (Added to ensure user data is updated/merged on login)
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final User? user = userCredential.user;

      if (user != null) {
          // 🔑 الخطوة الحاسمة: تحديث/دمج بيانات المستخدم في Firestore
          // هذا يضمن أن المستخدمين القدامى لديهم حقل 'email' في وثيقتهم لتجنب أخطاء البحث عن الأدمن.
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email!.toLowerCase(), 
            // يمكن إضافة تحديثات أخرى هنا، مثل آخر وقت دخول 'lastLogin': FieldValue.serverTimestamp()
          }, SetOptions(merge: true));
      }


      // Authentication successful, navigate to the main user screen
      if (mounted) {
        // 💡 Navigate to the main user screen (DashboardScreen in this context)
// ✅ الاستخدام الصحيح لـ MaterialPageRoute
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (context) => const DashboardScreen(cameras: [],), // ⬅️ بناء المسار الجديد (المعامل الأول)
  ),
  (Route<dynamic> route) => false, // ⬅️ شرط الإزالة (المعامل الثاني): أزل كل شيء
);      }
      
    } on FirebaseAuthException catch (e) {
      String message = 'Login error. Please try again.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Navigate to Sign Up screen
  void _goToSignUpScreen() {
    // 💡 Navigating to the sign-up screen
    Navigator.of(context).pushNamed(UserSignUpScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    // Removed Directionality(textDirection: TextDirection.rtl) for English LTR layout
    return Scaffold(
      backgroundColor: AppColors.whiteColor, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // EGO Logo/Title
                Text(
                  'EGO',
                  style: TextStyle(
                    color: AppColors.primaryColor1,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  'Welcome back! Unleash your inner strength.',
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                 Text(
                  'Sign in to start your daily workout',
                  style: TextStyle(
                    color: AppColors.grayColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                // Password field
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Forgot Password button
                Align(
                  alignment: Alignment.centerRight, // Changed alignment for LTR
                  child: TextButton(
                    onPressed: () {
                      // 💡 TODO: Implement forgot password functionality
                    },
                    child: Text(
                      'Forgot your password?',
                      style: TextStyle(color: AppColors.grayColor, fontSize: 14),
                    ),
                  ),
                ),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.redColor, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 40),

                // Login button
                _buildLoginButton(),
                
                // Sign Up option
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account yet?",
                      style: TextStyle(color: AppColors.grayColor, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: _goToSignUpScreen,
                      child: Text(
                        'Register Now',
                        style: TextStyle(color: AppColors.primaryColor1, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Login button widget
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentColor, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 5,
      ),
      child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.whiteColor, strokeWidth: 2))
          : const Text('Login', style: TextStyle(color: AppColors.whiteColor, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // Styled text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.blackColor), 
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor1), 
        labelStyle: const TextStyle(color: AppColors.grayColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accentColor, width: 2), 
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.redColor, width: 2), 
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.redColor, width: 2),
        ),
        fillColor: AppColors.lightGrayColor,
        filled: true,
      ),
    );
  }
}
