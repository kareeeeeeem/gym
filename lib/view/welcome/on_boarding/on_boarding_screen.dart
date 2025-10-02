import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/dashboard/home/home_screen.dart' hide DashboardScreen;
import 'package:fitnessapp/view/welcome/on_boarding/widgets/pager_widget.dart';
import 'package:fitnessapp/aus/signup/signup_screen.dart';
import 'package:flutter/material.dart';

class OnBoardingScreen extends StatefulWidget {
  static String routeName = "/OnBoardingScreen";
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  PageController pageController = PageController();
  List pageList = [
    {
      "title": "Track Your Goal",
      "subtitle":
          "Don't worry if you have trouble determining your goals, We can help you determine your goals and track your goals",
      "image": "assets/images/on_board1.png"
    },
    {
      "title": "Get Burn",
      "subtitle":
          "Let’s keep burning, to achive yours goals, it hurts only temporarily, if you give up now you will be in pain forever",
      "image": "assets/images/on_board2.png"
    },
    {
      "title": "Eat Well",
      "subtitle":
          "Let's start a healthy lifestyle with us, we can determine your diet every day. healthy eating is fun",
      "image": "assets/images/on_board3.png"
    },
    {
      "title": "Improve Sleep Quality",
      "subtitle":
          "Improve the quality of your sleep with us, good quality sleep can bring a good mood in the morning",
      "image": "assets/images/on_board4.png"
    }
  ];
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: pageList.length,
            onPageChanged: (i) {
              setState(() {
                selectedIndex = i;
              });
            },
            itemBuilder: (context, index) {
              var temp = pageList[index] as Map? ?? {};
              return PagerWidget(obj: temp);
            },
          ),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    color:  Colors.white,
                    value: (selectedIndex+1) / 4,
                    strokeWidth: 3,
                  ),
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      color:  Colors.white),
                  child: IconButton(
                    icon: const Icon(
                      Icons.navigate_next,
                      color:  Colors.blue,
                      size: 50,
                    ),
                    onPressed: () {
                      if (selectedIndex < 3) {
                        selectedIndex = selectedIndex + 1;
                        pageController.animateToPage(selectedIndex,
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeInSine);
                      }
                      Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DashboardScreen(cameras: [],)),
);

                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
