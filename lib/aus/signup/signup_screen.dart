import 'package:fitnessapp/aus/login/login_screen.dart';
import 'package:fitnessapp/const/complete_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; 
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
  final _firestore = FirebaseFirestore.instance;
  
  
  bool _isFacebookLoading = false;
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


// =========================================================================
  // . apple Logic
  // =========================================================================
Future<void> _signInWithApple() async {
  setState(() => _isLoading = true);
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    // إنشاء Credential لتسجيل الدخول إلى Firebase
    final oAuthProvider = OAuthProvider('apple.com');
    final authCredential = oAuthProvider.credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(authCredential);
    final user = userCredential.user;

    if (user != null) {
      // تحقق من وجود المستخدم في Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email?.toLowerCase(),
          'fullName': credential.givenName != null
              ? '${credential.givenName} ${credential.familyName ?? ''}'
              : 'Apple User',
          'photoUrl': null,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Apple Sign-In failed: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

// =========================================================================
  // . googel Logic (تم تحديثه لإضافة بيانات المستخدم إلى Firestore)
  // =========================================================================
Future<void> _signInWithGoogle() async {
  setState(() => _isLoading = true);
  try {
    final googleSignIn = GoogleSignIn.instance; 
    await googleSignIn.initialize();
    
    final GoogleSignInAccount? googleUser = await googleSignIn.authenticate(
      scopeHint: ['email','profile'],
    );

    if (googleUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );


    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      // حفظ بيانات المستخدم في Firestore لو جديد
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email?.toLowerCase(),
          'fullName': user.displayName ?? 'Google User',
          'photoUrl': user.photoURL,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // التوجيه إلى CompleteProfileScreen بعد التسجيل أو تسجيل الدخول
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
        );
      }
    }


  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google Sign-In failed: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  
// =========================================================================
  // 3. facebooklogin Logic (تم تحديثه لإضافة بيانات المستخدم إلى Firestore)
  // =========================================================================
Future<void> _signInWithFacebook() async {
  setState(() => _isFacebookLoading = true);

  try {
    await FacebookAuth.instance.logOut(); // تأمين الجلسة القديمة

    final LoginResult result = await FacebookAuth.instance.login(
      loginBehavior: LoginBehavior.webOnly, 
    );


    if (result.status == LoginStatus.success) {
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': user.email?.toLowerCase(),
            'fullName': user.displayName ?? 'Facebook User',
            'photoUrl': user.photoURL,
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
          );
        }
      }
    } else if (result.status == LoginStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Facebook login cancelled")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook login failed: ${result.message}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error during Facebook login: $e")),
    );
  } finally {
    setState(() => _isFacebookLoading = false);
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
          // 2. حفظ بيانات المستخدم في Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email!.toLowerCase(), 
            'fullName': _nameController.text.trim(),
            'isAdmin': false, 
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // Optional Step: Update User's Display Name
          await user.updateDisplayName(_nameController.text.trim());
      }
      

      // Authentication successful, navigate to the main screen
      if (mounted) {
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          // ⬅️ تأكد من أن "assets/images/sign.png" هو المسار الصحيح لصورتك
          image: AssetImage("assets/images/sign.png"), 
          fit: BoxFit.cover, // لتغطية كامل الشاشة
          ),
      ),
      child: Stack(
        children: [
          // طبقة التعتيم الداكنة (Dark Overlay)
          Container(
            // لتقليل حدة ألوان الخلفية وتحسين رؤية النص الأبيض
            color: Colors.black.withOpacity(0.5), 
          ),
       Scaffold(
       // ✅ التعديل الحاسم: لجعل الخلفية تظهر من خلال Scaffold
       backgroundColor: Colors.transparent, 
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Title
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      // 🌟 تم تعديل اللون إلى الأبيض لتحسين التباين
                      color: AppColors.whiteColor, 
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Motto
                  Text(
                    'Transform Ego into Achievement. Join EGO Gym.',
                    style: TextStyle(
                      // 🌟 تم تعديل اللون إلى أبيض مع تعتيم خفيف
                      color: AppColors.whiteColor.withOpacity(0.8), 
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
      
      
      
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // 🌟 تم تعديل لون الـ Divider
                      const Expanded(child: Divider(color: AppColors.whiteColor, thickness: 1)), 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            // 🌟 تم تعديل لون النص
                            color: AppColors.whiteColor.withOpacity(0.8), 
                            fontSize: 14),
                        ),
                      ),
                      // 🌟 تم تعديل لون الـ Divider
                      const Expanded(child: Divider(color: AppColors.whiteColor, thickness: 1)), 
                    ],
                  ),
                  const SizedBox(height: 10),
      
                  // Apple Login Button
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithApple,
                      icon: const Icon(Icons.apple, size: 28, color: Colors.white),
                      label: const Text(
                        'Continue with Apple',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                      ),
                    ),
                  ),
      
                  const SizedBox(height: 10),
      
                  // Google Login Button
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(
                        Icons.g_mobiledata,
                        size: 28,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB4437),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                      ),
                    ),
                  ),
                
                
                  const SizedBox(height: 10),
      
                  // Facebook Login Button
                  SizedBox(
                    // 🚨 تم تصحيح العرض ليتناسب مع الأزرار الأخرى
                    width: MediaQuery.of(context).size.width * 0.8, 
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _isFacebookLoading ? null : _signInWithFacebook,
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: _isFacebookLoading
                          ? const SizedBox(
                              height: 10,
                              width: 10,
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
                  ),
                  
                  
                  // Log In Option
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          // 🌟 تم تعديل اللون إلى أبيض مع تعتيم خفيف
                          color: AppColors.whiteColor.withOpacity(0.7), 
                          fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const UserLoginScreen()), 
                            (Route<dynamic> route) => false,
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
       ),
    ]),
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
          ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(color: AppColors.whiteColor, strokeWidth: 2))
          : const Text('Sign Up Now', style: TextStyle(color: AppColors.whiteColor, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // Styled Text Field Widget (Updated for better contrast on dark background)
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
      // 🌟 النص المدخل أصبح باللون الأبيض
      style: const TextStyle(color: AppColors.whiteColor), 
      decoration: InputDecoration(
        labelText: label,
        // 🌟 أيقونة بلون بارز
        prefixIcon: Icon(icon, color: AppColors.accentColor), 
        // 🌟 الـ Label باللون الأبيض الخفيف
        labelStyle: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w400), 
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
          // 🌟 حدود واضحة بلون Primary
          borderSide: const BorderSide(color: AppColors.primaryColor1, width: 2), 
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.redColor, width: 2), 
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.redColor, width: 2),
        ),
        // 🌟 خلفية الحقول شفافة وداكنة قليلاً
        fillColor: AppColors.blackColor.withOpacity(0.4), 
        filled: true,
      ),
    );
  }
}