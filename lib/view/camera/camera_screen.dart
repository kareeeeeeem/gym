import 'package:fitnessapp/const/common_widgets/round_button.dart';
import 'package:fitnessapp/const/common_widgets/round_gradient_button.dart';
import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:flutter/material.dart';

// 📸 الحزم المطلوبة
import 'package:camera/camera.dart'; 
import 'package:path_provider/path_provider.dart'; // لحفظ الملفات المؤقتة
import 'dart:io';

// 🔥 لمعالجة الأذونات
import 'package:permission_handler/permission_handler.dart'; 

// 🎨 لمعالجة الصور وإضافة العلامة المائية (يجب إضافة الحزمة في pubspec.yaml)
import 'package:image/image.dart' as img;


class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras; 
  static const String routeName = "/camera_screen";

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  
  late CameraController _controller;
  Future<void>? _initializeControllerFuture; 
  
  bool _isCameraReady = false; 
  bool _hasCameraPermission = false; 

  String? _lastCapturedImagePath; 

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInitializeCamera();
  }
  
  // 🔥 الدالة لطلب الإذن وتهيئة الكاميرا
  Future<void> _requestPermissionAndInitializeCamera() async {
    var status = await Permission.camera.request();
    
    if (status.isGranted) {
      setState(() {
        _hasCameraPermission = true;
      });
      
      if (widget.cameras.isNotEmpty) {
        _controller = CameraController(
          widget.cameras.first, 
          ResolutionPreset.high, 
        );

        _initializeControllerFuture = _controller.initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isCameraReady = true;
          });
        }).catchError((e) {
          print("Camera Initialization Error: $e");
          setState(() {
            _isCameraReady = false;
          });
        });
      }
    } else {
        setState(() {
            _hasCameraPermission = false;
        });
    }
  }

  @override
  void dispose() {
    if (widget.cameras.isNotEmpty && _controller.value.isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }


  // دالة التقاط الصورة وإضافة العلامة المائية
  void _takePhotoAndSave() async {
    if (!_isCameraReady || !_controller.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الكاميرا غير جاهزة، يرجى الانتظار.")),
      );
      return;
    }

    try {
      await _initializeControllerFuture;
      
      // 1. التقاط الصورة الفعلي
      final XFile imageFile = await _controller.takePicture();
      
      // 2. قراءة الملف الملتقط كبايت (Bytes)
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception("فشل في فك تشفير الصورة.");
      }

      // 3. إضافة العلامة المائية "Ego Gym"
      
      const String watermarkText = "Ego Gym";
      final int fontSize = (originalImage.height / 30).round().clamp(10, 50); // حجم الخط
      
      // لتحديد موقع الخط (يجب استخدام خط مخصص لدعم اللغة العربية بشكل صحيح)
      final textWidth = fontSize * watermarkText.length;
      final int textX = originalImage.width - textWidth - 20; 
      final int textY = originalImage.height - fontSize - 20; 

      // رسم النص على الصورة
      // الكود المُصحَّح: تمرير النص كـ Positional Argument ثاني، والموقع كـ Named Parameters
img.drawString(
  originalImage,
  watermarkText, // ✅ تم تمرير النص كوسيط موضعي ثاني
  font: img.arial24, 
  x: textX,
  y: textY,
  color: img.ColorRgb8(255, 255, 255), 
);

      // 4. تشفير الصورة المُعدَّلة مرة أخرى
      final encodedImageBytes = img.encodeJpg(originalImage, quality: 90);

      // 5. حفظ الصورة المُعدَّلة في مسار مؤقت
      final tempDir = await getTemporaryDirectory();
      final newPath = '${tempDir.path}/EgoGym_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final File newImageFile = File(newPath);
      await newImageFile.writeAsBytes(encodedImageBytes);
      
      // 6. تحديث مسار آخر صورة ملتقطة
      setState(() {
        _lastCapturedImagePath = newImageFile.path;
      });

      // 7. *** هنا تحتاج لإضافة منطق حفظ الصورة في المعرض العام ***

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم التقاط الصورة وإضافة علامة Ego Gym.")),
      );

    } catch (e) {
      print("Watermark Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل التقاط الصورة أو إضافة العلامة المائية: ${e.toString()}")),
      );
    }
  }

  // دالة وهمية للانتقال إلى المعرض
  void _navigateToGallery() {
      // **ضع هنا منطق الانتقال الفعلي إلى شاشة المعرض**
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ الانتقال إلى معرض الصور...")),
      );
  }
  
  // 🔥 دالة بناء واجهة المستخدم في حالة عدم وجود إذن
  Widget _buildPermissionDeniedWidget(Size media) {
      return Container(
          width: double.maxFinite,
          height: media.height, 
          decoration: BoxDecoration(
             color: AppColors.blackColor,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(30),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  const Icon(Icons.camera_alt_outlined, size: 60, color: AppColors.secondaryColor2),
                  const SizedBox(height: 20),
                  const Text(
                      "يتطلب هذا التطبيق إذن الوصول إلى الكاميرا.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  RoundGradientButton(
                      title: "طلب الإذن/فتح الإعدادات", 
                      onPressed: () async {
                         var status = await Permission.camera.status;
                         if (status.isPermanentlyDenied) {
                            openAppSettings(); 
                         } else {
                            _requestPermissionAndInitializeCamera();
                         }
                      },
                  )
              ],
          ),
      );
  }


  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    
    // ==============================================================
    // 💡 حالة عدم وجود الإذن
    // ==============================================================
    if (!_hasCameraPermission) {
      return Scaffold(
          backgroundColor: AppColors.blackColor, 
          body: _buildPermissionDeniedWidget(media)
      );
    }
    
    // 💡 حالة عدم وجود كاميرات متاحة أصلاً
    if (widget.cameras.isEmpty) {
         return Scaffold(
          backgroundColor: AppColors.blackColor,
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text("❌ لا توجد كاميرات متاحة على هذا الجهاز.", 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: AppColors.secondaryColor1))
              )
          )
      );
    }

    // ==============================================================
    // 📸 واجهة الكاميرا الرئيسية (Dark Theme & Full Screen)
    // ==============================================================
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        // خلفية شفافة لـ Dark Theme
        backgroundColor: Colors.transparent, 
        elevation: 0,
        title: const Text(
          "Progress Camera",
          style: TextStyle(color: AppColors.whiteColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          // زر تبديل الكاميرا (يمكن إضافة منطق للتبديل هنا)
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: AppColors.whiteColor),
            onPressed: () {
                // منطق تبديل الكاميرا
            },
          ),
          const SizedBox(width: 8)
        ],
      ),
      backgroundColor: AppColors.blackColor, 
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
            // ------------------------------------------------------------------
            // 📸 منطقة الكاميرا الفعلية (بأبعاد الشاشة تقريباً)
            // ------------------------------------------------------------------
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && _isCameraReady) {
                  return SizedBox(
                    width: media.width,
                    height: media.height,
                    child: FittedBox(
                      fit: BoxFit.cover, 
                      child: SizedBox(
                        width: media.width,
                        height: media.width / _controller.value.aspectRatio,
                        child: CameraPreview(_controller),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            "خطأ: الكاميرا غير متاحة (${snapshot.error})",
                            style: const TextStyle(color: Colors.red),
                        ),
                    );
                } else {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryColor1),
                    );
                }
              },
            ),

            // ------------------------------------------------------------------
            // أزرار التحكم في الأسفل (التقاط + معرض)
            // ------------------------------------------------------------------
            Container(
              height: media.height * 0.2, // زيادة الارتفاع لراحة الأزرار
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1. زر المعرض (Gallery Icon)
                    InkWell(
                      onTap: _navigateToGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.photo_library_outlined,
                          size: 28,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                    
                    // 2. زر التقاط الصورة المركزي
                    InkWell(
                      onTap: _takePhotoAndSave, 
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: AppColors.secondaryG),
                            borderRadius: BorderRadius.circular(37.5),
                            border: Border.all(color: AppColors.whiteColor, width: 4), 
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black38, blurRadius: 15, offset: Offset(0, 8))
                            ]),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 35,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                    
                    // 3. مسافة فارغة للمحاذاة
                    const SizedBox(width: 50), 
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}