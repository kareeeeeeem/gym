import 'package:flutter/material.dart';
import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:fitnessapp/view/welcome/on_boarding/widgets/on_boarding_screen.dart';

class StartScreen extends StatefulWidget {
  static String routeName = "/StartScreen";

  const StartScreen({Key? key}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _scaleLogo;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeLogo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.5)),
    );

    _scaleLogo = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.6, curve: Curves.elasticOut)),
    );

    _fadeText = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8)),
    );

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. الخلفية (صورة splash.png)
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/splash.png"), 
          fit: BoxFit.cover, 
        ),
      ),
      // 2. استخدام Stack لوضع طبقة التعتيم والمحتوى فوق الصورة
      child: Stack(
        children: [
          // 2.1. طبقة التعتيم الداكنة (Dark Overlay) لتحسين وضوح النص
          Container(
            color: Colors.black.withOpacity(0.4), 
          ),

          // 2.2. Scaffold الشفاف الذي يحمل المحتوى
          Scaffold(
            backgroundColor: Colors.transparent, 
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // الشعار (Ego)
                  FadeTransition(
                    opacity: _fadeLogo,
                    child: ScaleTransition(
                      scale: _scaleLogo,
                      child: const Text(
                        "Ego",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // الشعار الفرعي
                  FadeTransition(
                    opacity: _fadeText,
                    child: const Text(
                      "Everybody Can Train",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // زر "Get Started"
                  SlideTransition(
                    position: _buttonSlide,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: MaterialButton(
                        minWidth: double.maxFinite,
                        height: 55,
                          color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textColor: const Color.fromARGB(255, 54, 54, 55),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const OnBoardingScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}