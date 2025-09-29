import 'package:flutter/material.dart';
// حزمة http ضرورية لإرسال الطلبات إلى خادم FCM
import 'package:http/http.dart' as http; 
import 'dart:convert';

// تعريف الألوان المستخدمة (محاكاة لملف utils/app_colors.dart)
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color grayColor = Color(0xFF7B6F72);
  static const Color lightGrayColor = Color(0xFFF7F8F8);
  static const Color primaryColor1 = Color(0xFF92A3FD); 
  static const Color accentColor = Color(0xFFC58BF2);
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
}

class AdminNotificationSenderScreen extends StatefulWidget {
  static const String routeName = "/AdminNotificationSenderScreen";
  
  const AdminNotificationSenderScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationSenderScreen> createState() => _AdminNotificationSenderScreenState();
}

class _AdminNotificationSenderScreenState extends State<AdminNotificationSenderScreen> {
  final TextEditingController _titleController = TextEditingController(text: "إشعار تجريبي جديد");
  final TextEditingController _bodyController = TextEditingController(text: "مرحباً، تحديث جديد في تطبيق اللياقة!");
  // 💡 يجب استبدال هذا التوكن بتوكن الجهاز المستهدف الفعلي أو بقائمة توكنات
  final TextEditingController _tokenController = TextEditingController(text: "FCM_TOKEN_GOES_HERE"); 
  final TextEditingController _imagePathController = TextEditingController(text: "assets/icons/default.png");
  
  String _statusMessage = '';
  bool _isLoading = false;

  // 📢 ملاحظة هامة: هذا الكود سيعمل فقط إذا تم استبدال 'SERVER_KEY' بالمفتاح السري
  // الخاص بتطبيق Firebase الخاص بك، وهو غير متاح في بيئة Canvas.
  // في بيئة الإنتاج، يجب أن تكون هذه العملية عبر Cloud Functions أو خادم آمن.
  Future<void> sendNotification() async {
    if (_tokenController.text.isEmpty || _titleController.text.isEmpty) {
      setState(() => _statusMessage = 'يرجى ملء حقل التوكن والعنوان.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'جارٍ إرسال الإشعار...';
    });

    // ⛔ يجب استبدال هذا بمفتاح الخادم الخاص بتطبيقك (Server Key)
    // لا تشارك هذا المفتاح أبداً علناً في تطبيق المستخدم
    const String serverKey = "YOUR_FCM_SERVER_KEY"; 
    
    // عنوان URL لإرسال الإشعار عبر FCM
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    final Map<String, dynamic> notificationData = {
      // 'to' هو التوكن لجهاز واحد. يمكن استبدالها بـ 'registration_ids' لمجموعة من الأجهزة
      'to': _tokenController.text.trim(), 
      'notification': {
        'title': _titleController.text,
        'body': _bodyController.text,
        "sound": "default",
        "badge": "1",
      },
      // البيانات المخصصة التي يتم حفظها في Firestore، يجب أن تكون هنا لتفعيل الحفظ
      'data': {
        'image_path': _imagePathController.text,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK', 
        'screen': 'notifications', // اسم الشاشة التي ستفتح عند النقر
      },
      'priority': 'high',
    };

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          // 💡 المصادقة باستخدام مفتاح الخادم
          'Authorization': 'key=$serverKey', 
        },
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = '✅ تم إرسال الإشعار بنجاح!';
          _isLoading = false;
        });
        print("FCM Response Success: ${response.body}");
      } else {
        setState(() {
          _statusMessage = '❌ فشل إرسال الإشعار. كود الحالة: ${response.statusCode}';
          _isLoading = false;
        });
        print("FCM Response Error: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ خطأ في الاتصال بالخادم: $e';
        _isLoading = false;
      });
      print("FCM Exception: $e");
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tokenController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor1,
        title: const Text(
          "إرسال إشعارات المسؤول",
          style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- حقل توكن الجهاز ---
            _buildTextField(
              controller: _tokenController,
              label: "توكن جهاز المستخدم (FCM Token)",
              hint: "أدخل توكن الجهاز المستهدف أو 'all' للكل (في الخادم)",
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // --- حقل العنوان ---
            _buildTextField(
              controller: _titleController,
              label: "عنوان الإشعار (Notification Title)",
              hint: "مثال: تحديث جديد",
            ),
            const SizedBox(height: 20),

            // --- حقل النص ---
            _buildTextField(
              controller: _bodyController,
              label: "نص الإشعار (Notification Body)",
              hint: "مثال: تحقق من تمارين اليوم",
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // --- حقل مسار الصورة (Data Payload) ---
            _buildTextField(
              controller: _imagePathController,
              label: "مسار الصورة (Data Payload: image_path)",
              hint: "مثال: assets/icons/promo.png",
            ),
            const SizedBox(height: 30),

            // --- زر الإرسال ---
            ElevatedButton(
              onPressed: _isLoading ? null : sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor1,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppColors.whiteColor)
                  : const Text(
                      "إرسال الإشعار",
                      style: TextStyle(fontSize: 18, color: AppColors.whiteColor, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
            
            // --- رسالة الحالة ---
            Center(
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage.contains('نجاح') ? AppColors.successColor : AppColors.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            const Text(
              "ملاحظة هامة:",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blackColor),
            ),
            const Text(
              "هذه الدالة تستخدم مفتاح الخادم السري (Server Key) ويجب أن تُنفَّذ من خادم خلفي آمن (مثل Firebase Cloud Functions) في بيئة الإنتاج، وليس مباشرة من تطبيق Flutter (Admin App) لأسباب أمنية.",
              style: TextStyle(color: AppColors.grayColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.blackColor),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightGrayColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grayColor.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.blackColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.grayColor.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
