import 'package:flutter/material.dart';

// =========================================================================
// 1. تعريف الألوان (Ego Gym Theme)
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color darkGrayColor = Color(0xFF707070); 
  static const Color grayColor = Color(0xFFC0C0C0); 
  static const Color lightGrayColor = Color(0xFFF1F1F1); 
  static const Color primaryColor1 = Color(0xFF8B0000); // ماروني داكن
  static const Color accentColor = Color(0xFFFFA500); // ذهبي/عنبري
  static const Color primaryColor2 = Color(0xFFCC5500); 
  static const Color secondaryColor2 = Color(0xFFDCDCDC); // لون فاتح للتمييز
  
  static List<Color> primaryG = [
    primaryColor1,
    primaryColor2, 
  ];
}


// =========================================================================
// 2. Mock Screens and Custom Widgets
// =========================================================================

// Mock 2.1: شاشة تفاصيل خطوة التمرين
class ExercisesStepDetails extends StatelessWidget {
  final Map eObj;
  const ExercisesStepDetails({Key? key, required this.eObj}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          eObj["title"]?.toString() ?? "خطوة التمرين",
          style: const TextStyle(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.primaryColor1,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // محتوى تفصيلي عن التمرين
            Text(
              eObj["title"]?.toString() ?? "",
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackColor),
            ),
            const SizedBox(height: 10),
            Text(
              "القيمة: ${eObj["value"]?.toString() ?? ""}",
              style: const TextStyle(fontSize: 16, color: AppColors.darkGrayColor),
            ),
            const SizedBox(height: 20),
            // عرض رابط الفيديو
            if (eObj["video_url"] != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "شاهد الشرح (YouTube):",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor1),
                    ),
                    InkWell(
                      onTap: () {
                        // في بيئة الإنتاج، يتم فتح الرابط هنا
                        print("Opening Video URL: ${eObj["video_url"]}");
                      },
                      child: Text(
                        eObj["video_url"].toString(),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              "الوصف:",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor),
            ),
            const SizedBox(height: 5),
            Text(
              "هذا القسم يوضح بالتفصيل كيفية أداء تمرين ${eObj["title"]}. تأكد من الحفاظ على الوضعية الصحيحة لتجنب الإصابات. ركز على التنفس أثناء الأداء.",
              style: const TextStyle(fontSize: 16, color: AppColors.darkGrayColor),
            ),
          ],
        ),
      ),
    );
  }
}

// Mock 2.2: شاشة جدولة التمرين
class WorkoutScheduleView extends StatelessWidget {
  static const String routeName = "/workout_schedule";
  const WorkoutScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("جدولة التمرين", style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primaryColor1,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      body: const Center(
        child: Text(
          "شاشة تحديد موعد التمرين",
          style: TextStyle(fontSize: 18, color: AppColors.blackColor),
        ),
      ),
    );
  }
}

// Mock 2.3: زر التدرج اللوني (RoundGradientButton)
class RoundGradientButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  
  const RoundGradientButton({
    Key? key,
    required this.title,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.primaryG),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor1.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: onPressed,
        minWidth: double.maxFinite,
        height: 55,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        child: Text(
          title,
          style: const TextStyle(
              color: AppColors.whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// Mock 2.4: صف الأيقونة والعنوان والزر التالي (IconTitleNextRow)
class IconTitleNextRow extends StatelessWidget {
  final String icon;
  final String title;
  final String time;
  final Color color;
  final VoidCallback onPressed;
  
  const IconTitleNextRow({
    Key? key,
    required this.icon,
    required this.title,
    required this.time,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // استبدال Image.asset بأيقونة
              Icon(
                title.contains("Schedule") ? Icons.schedule : Icons.star,
                color: AppColors.primaryColor1,
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.blackColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onPressed,
            child: Row(
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.darkGrayColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.darkGrayColor,
                  size: 15,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Mock 2.5: قسم مجموعات التمرين (ExercisesSetSection)
class ExercisesSetSection extends StatelessWidget {
  final Map sObj;
  final Function(Map obj) onPressed;
  
  const ExercisesSetSection({Key? key, required this.sObj, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var setArr = sObj["set"] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 8),
          child: Text(
            sObj["name"]?.toString() ?? "مجموعة التمارين",
            style: const TextStyle(
                color: AppColors.blackColor,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),
        ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: setArr.length,
            itemBuilder: (context, index) {
              var eObj = setArr[index] as Map? ?? {};
              return InkWell(
                onTap: () {
                  onPressed(eObj);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grayColor.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // استبدال الصورة بأيقونة
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fitness_center, color: AppColors.primaryColor1, size: 30),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eObj["title"].toString(),
                              style: const TextStyle(
                                color: AppColors.blackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              eObj["value"].toString().contains("x")
                                  ? "${eObj["value"]} Repetitions"
                                  : "${eObj["value"]} Time",
                              style: const TextStyle(
                                color: AppColors.darkGrayColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.darkGrayColor,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              );
            }),
      ],
    );
  }
}


// =========================================================================
// 3. الشاشة الرئيسية (WorkoutDetailView) - الكود المُعدَّل
// =========================================================================

class WorkoutDetailView extends StatefulWidget {
  final Map dObj;
  const WorkoutDetailView({Key? key, required this.dObj}) : super(key: key);

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {

  // بيانات المعدات (تم استبدال صور assets بأيقونات)
  List youArr = [
    {"icon": Icons.fitness_center, "title": "Barbell"},
    {"icon": Icons.sports_tennis, "title": "Skipping Rope"},
    {"icon": Icons.local_drink, "title": "Bottle 1 Liters"},
  ];

  // بيانات التمارين (تم إضافة روابط فيديوهات مقترحة)
  List exercisesArr = [
    {
      "name": "Set 1",
      "set": [
        {"title": "Warm Up", "value": "05:00", "video_url": "https://youtu.be/G2E2XwK6mG0"},
        {"title": "Jumping Jack", "value": "12x", "video_url": "https://youtu.be/rfJ3X7U6z20"},
        {"title": "Skipping", "value": "15x", "video_url": "https://youtu.be/tEaH-1D-0oQ"},
        {"title": "Squats", "value": "20x", "video_url": "https://youtu.be/aclHhFWD75M"},
        {"title": "Arm Raises", "value": "00:53", "video_url": "https://youtu.be/u88d8b_Wq1Y"},
        {"title": "Rest and Drink", "value": "02:00", "video_url": null}, // لا يوجد فيديو
      ],
    },
    {
      "name": "Set 2",
      "set": [
        {"title": "Warm Up", "value": "05:00", "video_url": "https://youtu.be/G2E2XwK6mG0"},
        {"title": "Jumping Jack", "value": "12x", "video_url": "https://youtu.be/rfJ3X7U6z20"},
        {"title": "Skipping", "value": "15x", "video_url": "https://youtu.be/tEaH-1D-0oQ"},
        {"title": "Squats", "value": "20x", "video_url": "https://youtu.be/aclHhFWD75M"},
        {"title": "Arm Raises", "value": "00:53", "video_url": "https://youtu.be/u88d8b_Wq1Y"},
        {"title": "Rest and Drink", "value": "02:00", "video_url": null},
      ],
    }
  ];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Container(
      decoration:
      BoxDecoration(gradient: LinearGradient(colors: AppColors.primaryG)),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.lightGrayColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon( // أيقونة رجوع
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              actions: [
                InkWell(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.lightGrayColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon( // أيقونة المزيد
                      Icons.more_horiz,
                      size: 15,
                      color: AppColors.blackColor,
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
              leading: Container(),
              expandedHeight: media.width * 0.5,
              flexibleSpace: Align(
                alignment: Alignment.center,
                child: Icon( // صورة placeholder للتمرين الرئيسي
                  Icons.directions_run,
                  size: media.width * 0.4,
                  color: AppColors.whiteColor.withOpacity(0.8),
                ),
              ),
            ),
          ];
        },
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25))),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.grayColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3)),
                      ),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.dObj["title"].toString(),
                                  style: const TextStyle(
                                      color: AppColors.blackColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  "${widget.dObj["exercises"].toString()} | ${widget.dObj["time"].toString()} | 320 Calories Burn",
                                  style: const TextStyle(
                                      color: AppColors.grayColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Icon(
                              Icons.favorite_border,
                              color: AppColors.primaryColor1,
                              size: 20,
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      IconTitleNextRow(
                          icon: "assets/icons/time_icon.png",
                          title: "Schedule Workout",
                          time: "5/27, 09:00 AM",
                          color: AppColors.primaryColor2.withOpacity(0.3),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutScheduleView()));
                          }),
                      SizedBox(
                        height: media.width * 0.02,
                      ),
                      IconTitleNextRow(
                          icon: "assets/icons/difficulity_icon.png",
                          title: "Difficulity",
                          time: "Beginner",
                          color: AppColors.secondaryColor2.withOpacity(0.3),
                          onPressed: () {}),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "You'll Need",
                            style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${youArr.length} Items",
                              style:
                              const TextStyle(color: AppColors.grayColor, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.5,
                        child: ListView.builder(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: youArr.length,
                            itemBuilder: (context, index) {
                              var yObj = youArr[index] as Map? ?? {};
                              return Container(
                                  margin: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: media.width * 0.35,
                                        width: media.width * 0.35,
                                        decoration: BoxDecoration(
                                            color: AppColors.lightGrayColor,
                                            borderRadius:
                                            BorderRadius.circular(15)),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          yObj["icon"] as IconData,
                                          size: media.width * 0.2,
                                          color: AppColors.darkGrayColor,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          yObj["title"].toString(),
                                          style: const TextStyle(
                                              color: AppColors.blackColor,
                                              fontSize: 12),
                                        ),
                                      )
                                    ],
                                  ));
                            }),
                      ),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Exercises",
                            style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${exercisesArr.length} Sets",
                              style:
                              const TextStyle(color: AppColors.grayColor, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      ListView.builder(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: exercisesArr.length,
                          itemBuilder: (context, index) {
                            var sObj = exercisesArr[index] as Map? ?? {};
                            return ExercisesSetSection(
                              sObj: sObj,
                              onPressed: (obj) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExercisesStepDetails(eObj: obj,),
                                  ),
                                );
                              },
                            );
                          }),
                      SizedBox(
                        height: media.width * 0.1,
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      RoundGradientButton(title: "Start Workout", onPressed: () {})
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
