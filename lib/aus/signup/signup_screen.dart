import 'package:fitnessapp/view/dashboard/home/home_screen.dart';
import 'package:fitnessapp/aus/login/login_screen.dart';
import 'package:fitnessapp/const/complete_profile_screen.dart';
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; 
  import 'package:google_sign_in/google_sign_in.dart';



// 💡 You should import the main user screen to navigate to it after successful registration.
// Please adjust this path to match your project structure.
// 💡 You can import the login screen to navigate back to it.
// import 'user_login_screen.dart'; 

// =========================================================================
// 1. App Colors and Helper Components (Consistent Design)
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color grayColor = Color(0xFF7B6F72);
  static const Color lightGrayColor = Color(0xFFF7F8F8);
  static const Color primaryColor1 = Color(0xFF92A3FD); // Primary Blue
  static const Color accentColor = Color(0xFFC58BF2); // Accent Purple/Pink
  static const Color redColor = Color(0xFFEA4E79);
}

// =========================================================================
// 2. Main User Sign Up Screen (UserSignUpScreen)
// =========================================================================

class UserSignUpScreen extends StatefulWidget {
  static const String routeName = '/user_signup';
  const UserSignUpScreen({super.key});

  @override
  State<UserSignUpScreen> createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firestore = FirebaseFirestore.instance; // ⬅️ أضف هذا السطر
  
  
      bool _isFacebookLoading = false; // ✅ أضف هذا السطر هنا
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  
//  Future<void> signInWithGoogle(BuildContext context) async {
//   try {
//     // ✅ الإنشاء الصحيح
//     final GoogleSignIn googleSignIn = GoogleSignIn(
//       scopes: ['email', 'profile'],
//     );

//     // 🔹 تسجيل الدخول
//     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

//     if (googleUser == null) {
//       debugPrint("🔸 Google Sign-In cancelled by user");
//       return;
//     }

//     // 🔹 الحصول على بيانات المصادقة
//     final GoogleSignInAuthentication googleAuth =
//         await googleUser.authentication;

//     // 🔹 إنشاء بيانات الاعتماد لـ Firebase
//     final credential = GoogleAuthProvider.credential(
//       idToken: googleAuth.idToken,
//       accessToken: googleAuth.accessToken,
//     );

//     // 🔹 تسجيل الدخول في Firebase
//     final userCredential =
//         await FirebaseAuth.instance.signInWithCredential(credential);
//     final user = userCredential.user;

//     if (user != null) {
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();

//       if (!userDoc.exists) {
//         await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//           'email': user.email?.toLowerCase(),
//           'fullName': user.displayName,
//           'photoUrl': user.photoURL,
//           'isAdmin': false,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//       }

//       if (context.mounted) {
//         Navigator.pushReplacementNamed(
//             context, CompleteProfileScreen.routeName);
//       }
//     }
//   } catch (e) {
//     debugPrint("❌ Google Sign-In Error: $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Google Sign-In failed: $e')),
//     );
//   }
// }

  
  
  
  
// =========================================================================
  // 3. facebooklogin Logic
  // =========================================================================
Future<void> _signInWithFacebook() async {
  setState(() {
    _isFacebookLoading = true;
  });

  try {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);

      await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CompleteProfileScreen(),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook login failed: ${result.message}")),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during Facebook login: $e")),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isFacebookLoading = false;
      });
    }
  }
}

  

  // Sign Up Function
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final User? user = userCredential.user;

      if (user != null) {
          // 2. 🔑 الخطوة الحاسمة: حفظ بيانات المستخدم في Firestore
          await _firestore.collection('users').doc(user.uid).set({
            // هذا الحقل ضروري لعملية البحث عن الأدمن بواسطة الإيميل
            'email': user.email!.toLowerCase(), 
            'fullName': _nameController.text.trim(), // حفظ الاسم أيضاً
            'isAdmin': false, // القيمة الافتراضية
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // 💡 Optional Step: Update User's Display Name
          await user.updateDisplayName(_nameController.text.trim());
      }
      

      // Authentication successful, navigate to the main screen
      if (mounted) {
        // Navigate to User Home Screen ⬅️ تم استعادة هذا الجزء
        Navigator.of(context).pushReplacementNamed(CompleteProfileScreen.routeName); 
      }
      
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create account. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
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



  @override
  Widget build(BuildContext context) {
    // We remove Directionality(textDirection: TextDirection.rtl) for English
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
                // Title and Motto
                const Text(
                  'Create Your Account',
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Transform Ego into Achievement. Join EGO Gym.',
                  style: TextStyle(
                    color: AppColors.grayColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Full Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password (min 6 characters)',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Confirm Password Field
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.check_circle_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                // Error Message
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

                // Sign Up Button (CTA)
                _buildSignUpButton(),

                const SizedBox(height: 15),

// Facebook Login Button
ElevatedButton.icon(
  onPressed: _isLoading || _isFacebookLoading ? null : _signInWithFacebook,
  icon: const Icon(Icons.facebook, color: Colors.white),
  label: _isFacebookLoading
      ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
      : const Text(
          'Continue with Facebook',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1877F2), // Facebook Blue
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: const EdgeInsets.symmetric(vertical: 14),
    elevation: 5,
  ),
),


                
                // Log In Option
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: AppColors.grayColor, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        // 💡 التعديل هنا: يجب استبدال UserLoginScreen بالصفحة الرئيسية للتطبيق.
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const UserLoginScreen()), // ⬅️ ضع اسم الصفحة الرئيسية/الوجهات هنا
                          (Route<dynamic> route) => false, // هذا الشرط يعني: أزل كل شيء أسفل الصفحة الجديدة
                        );
                      },

                      child: const Text(
                        'Login',
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

  // Sign Up Button Widget
  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signUp,
      style: ElevatedButton.styleFrom(
        // Use Accent Color for emphasis
        backgroundColor: AppColors.accentColor, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 5,
      ),
      child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.whiteColor, strokeWidth: 2))
          : const Text('Sign Up Now', style: TextStyle(color: AppColors.whiteColor, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // Styled Text Field Widget (Copied from Login Screen for consistency)
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
      style: const TextStyle(color: AppColors.blackColor),
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
