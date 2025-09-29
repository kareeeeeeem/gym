import 'package:fitnessapp/view/home/home_screen.dart';
import 'package:fitnessapp/view/login/login_screen.dart';
import 'package:fitnessapp/view/profile/complete_profile_screen.dart';
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

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
      // Create user in Firebase
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // 💡 Optional Step: Update User's Display Name
      await _auth.currentUser!.updateDisplayName(_nameController.text.trim());

      // Authentication successful, navigate to the main screen
      if (mounted) {
        // Navigate to User Home Screen
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
                Text(
                  'Create Your Account',
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
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
                
                // Log In Option
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: AppColors.grayColor, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push( context,
                          MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                        );
                      },

                      child: Text(
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
