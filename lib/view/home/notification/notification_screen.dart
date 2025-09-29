import 'package:flutter/material.dart';
// 💡 فك التعليق عن حزم Firebase للبدء في قراءة البيانات الحية!
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =========================================================================
// 1. تعريف الألوان والبيانات
// =========================================================================

// تعريف الألوان المستخدمة (محاكاة لملف utils/app_colors.dart)
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color grayColor = Color(0xFF7B6F72);
  static const Color lightGrayColor = Color(0xFFF7F8F8);
  static const Color primaryColor1 = Color(0xFF92A3FD); 
  static const Color accentColor = Color(0xFFC58BF2);
}

// نموذج بيانات مبسط (يستخدم في محاكاة البيانات)
class NotificationModel {
  String id; // تم تغيير الـ ID إلى String ليتوافق مع IDs Firestore
  String image;
  String title;
  String content; // 💡 جديد: حقل محتوى الإشعار التفصيلي
  String time; 
  bool isRead;
  Timestamp? timestamp; 

  NotificationModel({
    required this.id,
    required this.image,
    required this.title,
    required this.content, // 💡 جديد: تم إضافته إلى الـ Constructor
    required this.time,
    required this.isRead,
    this.timestamp, 
  });
}

// بيانات وهمية قابلة للتعديل
// سيتم تجاهل هذه القائمة بمجرد تفعيل Firestore
List<NotificationModel> initialMockNotifications = [
  NotificationModel(id: '1', image: "assets/icons/notification_icon.png", title: "مرحباً بك في تطبيق اللياقة!", content: "هذا هو محتوى الإشعار التجريبي الأول.", time: "الآن", isRead: false),
  NotificationModel(id: '2', image: "assets/icons/notification_icon.png", title: "تحقق من تقدمك", content: "لقد حققت 70% من هدفك الأسبوعي. استمر!", time: "بالأمس | 10:00ص", isRead: false),
  NotificationModel(id: '3', image: "assets/icons/notification_icon.png", title: "تم تسجيل الدخول لجهاز جديد", content: "تم تسجيل دخول من جهاز غير معروف.", time: "بالأمس | 03:00م", isRead: true),
  NotificationModel(id: '4', image: "assets/icons/notification_icon.png", title: "تحدي جديد ينتظرك!", content: "انضم إلى تحدي الـ 30 يوماً الجديد.", time: "اليوم | 10:00ص", isRead: false),
];


// =========================================================================
// 2. تصميم شاشة الإشعارات
// =========================================================================

class NotificationScreen extends StatefulWidget {
  static const String routeName = "/NotificationScreen";

  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  // 📢 دالة لتغيير حالة الإشعار إلى "مقروء" على Firestore (تم فك التعليق)
  void _markAsRead(String notificationId) {
    
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final db = FirebaseFirestore.instance;

    db.collection('notifications')
      .doc(userId)
      .collection('user_notifications')
      .doc(notificationId)
      .update({'isRead': true})
      .then((_) => print("Notification ID $notificationId marked as read in Firestore."))
      .catchError((error) => print("Failed to update notification: $error"));
  }

  // 📢 دالة لمسح الكل أو تحديد الكل كمقروء (لزر 'More')
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.done_all, color: AppColors.primaryColor1),
              title: const Text('تعليم الكل كمقروء'),
              onTap: () {
                Navigator.pop(context);
                _markAllAsRead();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('مسح جميع الإشعارات'),
              onTap: () {
                Navigator.pop(context);
                _deleteAllNotifications();
              },
            ),
          ],
        );
      },
    );
  }
  
  // دالة تعليم الكل كمقروء (جديد)
  void _markAllAsRead() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final db = FirebaseFirestore.instance;
    final collectionRef = db.collection('notifications').doc(currentUser.uid).collection('user_notifications');
    
    try {
      final snapshot = await collectionRef.where('isRead', isEqualTo: false).get();
      final batch = db.batch();
      
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      print("All unread notifications marked as read.");
    } catch (e) {
      print("Error marking all as read: $e");
    }
  }

  // دالة مسح جميع الإشعارات (جديد)
  void _deleteAllNotifications() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final db = FirebaseFirestore.instance;
    final collectionRef = db.collection('notifications').doc(currentUser.uid).collection('user_notifications');
    
    try {
      final snapshot = await collectionRef.get();
      final batch = db.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("All notifications deleted.");
    } catch (e) {
      print("Error deleting all notifications: $e");
    }
  }

  // 📢 دالة سحب البيانات الحية من Firestore (تم فك التعليق)
  Stream<List<NotificationModel>> getNotificationsStream() async* {
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    // 💡 التحقق من المصادقة: إذا لم يكن هناك مستخدم مسجل الدخول، يتم إرجاع قائمة فارغة
    if (currentUser == null) {
      print("Warning: User is not authenticated. Cannot load personalized notifications.");
      yield [];
      return;
    }
    
    final String userId = currentUser.uid;
    final db = FirebaseFirestore.instance;

    final notificationsPath = db.collection('notifications')
      .doc(userId)
      .collection('user_notifications'); 

    // تم إزالة .orderBy لتجنب مشكلة الفهرسة، والفرز سيتم محليًا في StreamBuilder
    yield* notificationsPath.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // تحويل Timestamp إلى String وتنسيقه للعرض
        String timeString;
        Timestamp? rawTimestamp;
        try {
            // نستخدم Timestamp لتاريخ الإنشاء من Firestore
            rawTimestamp = data['time'] as Timestamp;
            timeString = rawTimestamp.toDate().toString().split('.')[0]; 
        } catch (_) {
            timeString = "وقت غير محدد";
        }
            
        return NotificationModel(
          id: doc.id, 
          image: data['image_path'] ?? "assets/icons/default.png",
          title: data['title'] ?? "إشعار جديد",
          content: data['body'] ?? "لا يوجد محتوى تفصيلي.", // 💡 قراءة حقل المحتوى (يُفترض أنه body)
          time: timeString, 
          isRead: data['isRead'] ?? false,
          timestamp: rawTimestamp, 
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
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
              child: Image.asset(
                "assets/icons/back_icon.png", 
                width: 15,
                height: 15,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.arrow_back_ios_new, size: 15, color: AppColors.blackColor),
              ),
            ),
          ),
          title: const Text(
            "الإشعارات",
            style: TextStyle(
                color: AppColors.blackColor,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          actions: [
            InkWell(
              onTap: _showMoreOptions,
              child: Container(
                margin: const EdgeInsets.all(8),
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.lightGrayColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Image.asset(
                  "assets/icons/more_icon.png",
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.more_horiz, size: 15, color: AppColors.blackColor),
                ),
              ),
            )
          ],
        ),
        
        // --- استخدام StreamBuilder لسحب البيانات من Firestore ---
        body: StreamBuilder<List<NotificationModel>>(
            stream: getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor1));
              }

              if (snapshot.hasError) {
                // 💡 طباعة رسالة الخطأ لتحديد المشكلة بدقة
                print("Error fetching notifications: ${snapshot.error}");
                // يجب أن تكون هذه المشكلة قد حُلت بتعديل قواعد الأمان
                return const Center(child: Text("حدث خطأ أثناء تحميل الإشعارات.", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)));
              }

              final notifications = snapshot.data ?? [];
              
              // 💡 الفرز المحلي: لضمان عرض الأحدث أولاً دون الحاجة لفهرس Firestore
              notifications.sort((a, b) {
                // الفرز تنازليًا بناءً على Timestamp (الأحدث أولاً)
                if (a.timestamp == null && b.timestamp == null) return 0;
                if (a.timestamp == null) return 1; // وضع الإشعارات بدون وقت في النهاية
                if (b.timestamp == null) return -1;
                return b.timestamp!.compareTo(a.timestamp!);
              });

              // 💡 رسالة واضحة في حالة عدم وجود إشعارات أو عدم تسجيل الدخول
              if (notifications.isEmpty) {
                // إذا لم يكن المستخدم مصادقًا، اعرض رسالة توجيهية
                if (FirebaseAuth.instance.currentUser == null) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(30.0),
                            child: Text(
                                "يرجى **تسجيل الدخول** لعرض الإشعارات الخاصة بك. لا يمكن تحميل بيانات المستخدمين غير المصادقين.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.grayColor, fontSize: 14)
                            ),
                        ),
                    );
                }
                
                // إذا كان المستخدم مصادقًا ولكن لا توجد إشعارات محفوظة
                return const Center(child: Text("لا توجد إشعارات حالياً.", style: TextStyle(color: AppColors.grayColor)));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                itemBuilder: ((context, index) {
                  var nObj = notifications[index];
                  return NotificationRow(
                    nObj: nObj,
                    onTap: () => _markAsRead(nObj.id), 
                  );
                }),
                separatorBuilder: (context, index) {
                  return Divider(
                    color: AppColors.grayColor.withOpacity(0.5),
                    height: 1,
                  );
                },
                itemCount: notifications.length,
              );
            },
          ),
    );
  }
}

// =========================================================================
//  مكون NotificationRow (صف الإشعار)
// =========================================================================
class NotificationRow extends StatelessWidget {
  final NotificationModel nObj;
  final VoidCallback onTap;

  const NotificationRow({Key? key, required this.nObj, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: nObj.isRead ? AppColors.whiteColor : AppColors.primaryColor1.withOpacity(0.05),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                nObj.image, 
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: nObj.isRead ? AppColors.grayColor.withOpacity(0.1) : AppColors.primaryColor1.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(Icons.notifications_active, color: nObj.isRead ? AppColors.grayColor : AppColors.whiteColor, size: 20),
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. العنوان
                    Text(
                      nObj.title,
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontWeight: nObj.isRead ? FontWeight.w500 : FontWeight.w700, 
                          fontSize: 12),
                    ),
                    // 💡 جديد: عرض محتوى/نص الإشعار التفصيلي
                    const SizedBox(height: 2), 
                    Text(
                      nObj.content,
                      maxLines: 2, // عرض سطرين فقط
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.grayColor.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // 3. الوقت
                    const SizedBox(height: 4), 
                    Text(
                      nObj.time,
                      style: TextStyle(
                        color: AppColors.grayColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )),
            IconButton(
                onPressed: () {},
                icon: Image.asset(
                  "assets/icons/sub_menu_icon.png",
                  width: 15,
                  height: 15,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.more_vert, size: 18, color: AppColors.grayColor),
                ))
          ],
        ),
      ),
    );
  }
}
