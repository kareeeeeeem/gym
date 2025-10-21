import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/activity/WorkoutLogPage.dart';
import 'package:fitnessapp/view/dashboard/activity/off/what_train_row.dart';
import 'package:fitnessapp/view/dashboard/activity/library.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../const/common_widgets/round_button.dart';
import 'whatDoYouWant.dart'; // نفترض أن هذا يحتوي على WorkoutDetailView

// الكلاس ActivityAppColors
class ActivityAppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color darkGrayColor = Color(0xFFC0C0C0); 
  static const Color primaryColor1 = Color(0xFF8B0000); // ماروني داكن/أحمر عميق
  static const Color accentColor = Color(0xFFFFA500); // ذهبي/عنبري
  
  // تدرج جديد يمزج بين الماروني والذهبي
  static List<Color> primaryG = [
    primaryColor1,
    const Color(0xFFCC5500), // لون بيني
  ];
}

// الكلاس ActivityScreen
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);
    static const String routeName = '/ActivityScreen';


  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List latestArr = [
    {
      "image": "assets/images/Workout1.png",
      "title": "Fullbody Workout",
      "time": "Today, 03:00pm"
    },
    {
      "image": "assets/images/Workout2.png",
      "title": "Upperbody Workout",
      "time": "June 05, 02:00pm"
    },
  ];

  List whatArr = [
    {
      "image": "assets/images/what_1.png",
      "title": "Fullbody Workout",
      "exercises": "11 Exercises",
      "time": "32mins"
    },
    {
      "image": "assets/images/what_2.png",
      "title": "Lowebody Workout",
      "exercises": "12 Exercises",
      "time": "40mins"
    },
    {
      "image": "assets/images/what_3.png",
      "title": "AB Workout",
      "exercises": "14 Exercises",
      "time": "20mins"
    }
  ];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Container(
      // تطبيق ثيم التدرج اللوني للخلفية العلوية (ماروني وذهبي)
      decoration:
          BoxDecoration(gradient: LinearGradient(colors: ActivityAppColors.primaryG)),
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              // pinned: true,
              title: const Text(
                "Workout Tracker",
                style: TextStyle(
                    color: ActivityAppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              actions: [
                InkWell(
                  onTap: () {
                     Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        // 💡 تم استدعاء WorkoutLogPage التي تحتوي على الروتينات المخصصة
                                        builder: (context) => FitnessApp())); 
                          
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        // استخدام لون خلفية داكن مع شفافية
                        color: ActivityAppColors.blackColor.withOpacity(0.3), 
                        borderRadius: BorderRadius.circular(10)),
                    child: Image.asset(
                      "assets/icons/more_icon.png",
                      color: ActivityAppColors.accentColor, // أيقونة باللون الذهبي
                      width: 15,
                      height: 15,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              ],
            ),
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leadingWidth: 0,
              leading: const SizedBox(),
              expandedHeight: media.height * 0.21,
              flexibleSpace: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: media.width * 0.5,
                width: double.maxFinite,
                child: LineChart(
                  LineChartData(
                    lineTouchData: lineTouchData1, 
                    lineBarsData: lineBarsData1,
                    minY: -0.5,
                    maxY: 110,
                    titlesData: FlTitlesData(
                        show: true,
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false), // إخفاء عناوين اليسار لتبسيط الكود
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: bottomTitles,
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: rightTitles,
                        )),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 25,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: ActivityAppColors.whiteColor.withOpacity(0.15),
                          strokeWidth: 2,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ];
        },
        body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
                color: ActivityAppColors.whiteColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25))),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // جعل المحتوى يبدأ من اليسار
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Center( // توسيط الخط الأفقي
                       child: Container(
                         width: 50,
                         height: 4,
                         decoration: BoxDecoration(
                             color: ActivityAppColors.darkGrayColor.withOpacity(0.3),
                             borderRadius: BorderRadius.circular(3)),
                       ),
                    ),

                    SizedBox(
                      height: media.width * 0.05,
                    ),
                     Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 24),
                      decoration: BoxDecoration(
                        // خلفية فاتحة للجدول اليومي
                        color: ActivityAppColors.primaryColor1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            " My previous exercises",
                            style: TextStyle(
                                color: ActivityAppColors.blackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(
                            width: 70,
                            height: 25,
                            child: RoundButton(
                              title: "Check",
                              // ✅ FIX 2: تم استبدال 'gradientColors' بـ 'colors' لحل مشكلة المعامل غير المعرّف
                              onPressed: ()  {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        // 💡 تم استدعاء WorkoutLogPage التي تحتوي على الروتينات المخصصة
                                        builder: (context) => WorkoutLogPage())); 
                          
                  },
                            ),
                          )
                        ],
                      ),
                      
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     const Text(
                    //       "Upcoming Workout",
                    //       style: TextStyle(
                    //           color: ActivityAppColors.blackColor,
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.w700),
                    //     ),
                    //     TextButton(
                    //       onPressed: () {},
                    //       child: const Text(
                    //         "See More",
                    //         style: TextStyle(
                    //             color: ActivityAppColors.darkGrayColor, // لون رمادي داكن
                    //             fontSize: 14,
                    //             fontWeight: FontWeight.w700),
                    //       ),
                    //     )
                    //   ],
                    // ),
                    // // 🔴 حل مشكلة الحجم اللانهائي (Infinite Size) بإزالة Expanded 
                    // // وحيث أن هذا الـ ListView معطى الخصائص shrinkWrap: true و physics: NeverScrollableScrollPhysics، فإنه يعمل بشكل صحيح داخل SingleChildScrollView.
                    // ListView.builder(
                    //   padding: EdgeInsets.zero,
                    //   physics: const NeverScrollableScrollPhysics(),
                    //   shrinkWrap: true,
                    //   itemCount: latestArr.length,
                    //   itemBuilder: (context, index) {
                    //     var wObj = latestArr[index] as Map? ?? {};
                    //     // 💡 تم تصحيح الـ Widget المستدعى ليكون UpcomingWorkoutRow بدلاً من WorkoutLogPage
                    //     return WhatTrainRow(wObj: wObj); 
                    //   }),
                    

                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    const Text( 
                      "What Do You Want to Train:",
                      style: TextStyle(
                          color: ActivityAppColors.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    // هذا الـ ListView يعمل بشكل صحيح لأنه يستخدم shrinkWrap: true و physics: NeverScrollableScrollPhysics
                    ListView.builder(
  padding: EdgeInsets.zero,
  physics: const NeverScrollableScrollPhysics(),
  shrinkWrap: true,
  itemCount: whatArr.length,
  itemBuilder: (context, index) {
    var wObj = whatArr[index] as Map? ?? {};
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailView(dObj: wObj),
          ),
        );
      },
      child: WhatTrainRow(wObj: wObj), // ✅ صح كده
    );
  },
),

                    SizedBox(
                      height: media.width * 0.1,
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  // 💡 تم تحويل الدالات إلى Getters لضمان عملها بشكل صحيح

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          // ✅ FIX 2: تم استبدال 'tooltipBgColor' بدالة 'getTooltipColor'
          getTooltipColor: (spot) => ActivityAppColors.primaryColor1.withOpacity(0.8),
          tooltipBorder: const BorderSide(
            color: ActivityAppColors.accentColor, // حدود باللون الذهبي
            width: 1.0, 
          ),
          getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
            return lineBarsSpot.map((lineBarSpot) {
              return LineTooltipItem(
                "${lineBarSpot.x.toInt()} mins ago",
                const TextStyle(
                  color: ActivityAppColors.whiteColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      );

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
        lineChartBarData1_2,
      ];

  // المسار الأساسي (الأكثر وضوحاً) باللون الذهبي/العنبري
  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: true,
        color: ActivityAppColors.accentColor, 
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData:  BarAreaData(show: false),
        spots: const [
          FlSpot(1, 35),
          FlSpot(2, 70),
          FlSpot(3, 40),
          FlSpot(4, 80),
          FlSpot(5, 25),
          FlSpot(6, 70),
          FlSpot(7, 35),
        ],
      );

  // المسار الثانوي (الخافت) باللون الأبيض أو الرمادي الفاتح
  LineChartBarData get lineChartBarData1_2 => LineChartBarData(
        isCurved: true,
        color: ActivityAppColors.whiteColor.withOpacity(0.5),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData:  BarAreaData(
          show: false,
        ),
        spots: const [
          FlSpot(1, 80),
          FlSpot(2, 50),
          FlSpot(3, 90),
          FlSpot(4, 40),
          FlSpot(5, 80),
          FlSpot(6, 35),
          FlSpot(7, 60),
        ],
      );

  SideTitles get rightTitles => SideTitles(
        getTitlesWidget: rightTitleWidgets,
        showTitles: true,
        interval: 20,
        reservedSize: 40,
      );

  Widget rightTitleWidgets(double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0%';
        break;
      case 20:
        text = '20%';
        break;
      case 40:
        text = '40%';
        break;
      case 60:
        text = '60%';
        break;
      case 80:
        text = '80%';
        break;
      case 100:
        text = '100%';
        break;
      default:
        return Container();
    }

    return Text(text,
        style: const TextStyle(
          color: ActivityAppColors.whiteColor,
          fontSize: 12,
        ),
        textAlign: TextAlign.center);
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    var style = const TextStyle(
      color: ActivityAppColors.whiteColor,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = Text('Sun', style: style);
        break;
      case 2:
        text = Text('Mon', style: style);
        break;
      case 3:
        text = Text('Tue', style: style);
        break;
      case 4:
        text = Text('Wed', style: style);
        break;
      case 5:
        text = Text('Thu', style: style);
        break;
      case 6:
        text = Text('Fri', style: style);
        break;
      case 7:
        text = Text('Sat', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      space: 10,
      meta: meta,
      child: text, 
    );
  }
}