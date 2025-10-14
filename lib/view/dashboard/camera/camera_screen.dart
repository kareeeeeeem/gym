// ignore_for_file: use_build_context_synchronously

import 'package:fitnessapp/const/common_widgets/round_button.dart';
import 'package:fitnessapp/const/common_widgets/round_gradient_button.dart';
import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:flutter/material.dart';

// 📸 الحزم المطلوبة
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // لحفظ الملفات المؤقتة
import 'dart:io';

// 🔥 لمعالجة الأذونات
import 'package:permission_handler/permission_handler.dart'; 

// 🎨 لمعالجة الصور وإضافة العلامة المائية (يجب إضافة الحزمة في pubspec.yaml)
import 'package:image/image.dart' as img;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
  import 'package:permission_handler/permission_handler.dart';





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
  bool _isPickingOrCapturing = false; // 🟢 الجديد: لمنع أي عملية تصوير/اختيار متزامنة
  bool _isPermissionRequesting = false;




  @override
  void initState() {
    super.initState();
    _requestPermissionAndInitializeCamera();
  }

Future<bool> checkAndRequestCameraPermission() async {
  // 1. التحقق من الحالة الحالية
  var status = await Permission.camera.status;

  // 2. إذا كانت الصلاحية ممنوحة بالفعل، عد بنجاح
  if (status.isGranted) {
    return true;
  } 

  // 3. إذا لم تكن ممنوحة أو لم يُطلب بها من قبل، قم بطلبها
  if (status.isDenied || status.isLimited || status.isRestricted) {
    var newStatus = await Permission.camera.request();
    return newStatus.isGranted;
  }
  
  // 4. إذا كانت ممنوعة بشكل دائم، اطلب من المستخدم فتح الإعدادات
  if (status.isPermanentlyDenied) {
    // يمكنك هنا إظهار SnackBar أو AlertDialog للمستخدم
    openAppSettings(); // دالة لفتح إعدادات التطبيق
    return false;
  }

  return status.isGranted;
}
  // 🔥 الدالة لطلب الإذن وتهيئة الكاميرا// ✅ التعديل الذي يجب وضعه (مع إضافة منطق القفل والفتح)
Future<void> _requestPermissionAndInitializeCamera() async {
    // 1. القفل: التحقق مما إذا كان طلب الإذن قيد التنفيذ بالفعل
    if (_isPermissionRequesting) {
        return;
    }
    
    // 2. تعيين الحالة على "جاري الطلب" وعرضها على الواجهة
    if(mounted) {
       setState(() {
            _isPermissionRequesting = true;
       });
    }

    try {
        // 3. تنفيذ طلب الإذن
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
    } catch (e) {
        print("Error during permission request: $e");
    } finally {
        // 4. فتح القفل: إعادة تعيين الحالة بعد الانتهاء
        if (mounted) {
            setState(() {
                _isPermissionRequesting = false;
            });
        }
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

    // 2. قراءة الملف كبايت
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception("فشل في فك تشفير الصورة.");
    }
// 3. إضافة العلامة المائية
    const String watermarkText = "Ego Gym";
    // 🔑 التعديل 1: تحسين حجم الخط ليتناسب مع معظم الصور، مع حد أقصى للحجم
    final int fontSize = (originalImage.height / 18).round().clamp(40, 120); 

    // 🔑 التعديل 2: تحديد موضع العلامة المائية في الزاوية اليمنى السفلية (مع هامش 40 بكسل)
    // لحساب عرض النص، نحتاج إلى تقدير يعتمد على نوع الخط. سنستخدم تقدير تقريبي:
    const double charWidthFactor = 0.6; // تقدير نسبة عرض الحرف إلى ارتفاعه
    final int estimatedTextWidth = (fontSize * watermarkText.length * charWidthFactor).round();
    
    // 🔹 تحديد الموضع (يمين أسفل الصورة)
    final int textX = originalImage.width - (fontSize * 6); // ← المسافة من اليمين
    final int textY = originalImage.height - fontSize - 50; // ← المسافة من الأسفل

    // 🔑 التعديل 3: استخدام لون رمادي فاتح شبه شفاف (للحصول على تأثير "مطبوع")
    // بما أن img.drawString لا تدعم الشفافية، نستخدم لون فاتح بديل للأبيض.
    final img.Color watermarkColor = img.ColorRgb8(200, 200, 200); // رمادي فاتح

    // يمكنك استخدام خط أكبر وأكثر وضوحًا إذا كان متاحًا، لكن سنبقي على الخط الافتراضي
    // مع تعديل الحجم
    img.drawString(
      originalImage,
      watermarkText,
      // يجب أن تستخدم خطًا متاحًا، arial24 هو خط مصغر، سنستخدمه مع الحجم المعدل
      font: img.arial14, // استخدام خط أصغر للحجم يجعله يتناسب مع الحجم الذي حسبناه
      x: textX,
      y: textY,
      color: watermarkColor,
    );
    // 4. تشفير الصورة المعدلة
    final encodedImageBytes = img.encodeJpg(originalImage, quality: 90);

    // 5. حفظ في ملف مؤقت
    final tempDir = await getTemporaryDirectory();
    final newPath =
        '${tempDir.path}/EgoGym_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final File newImageFile = File(newPath);
    await newImageFile.writeAsBytes(encodedImageBytes);

    // 6. حفظ في المعرض باستخدام saver_gallery
    final result = await SaverGallery.saveFile(
      filePath: newPath,
      fileName: "EgoGym_${DateTime.now().millisecondsSinceEpoch}.jpg",
      androidRelativePath: "Pictures/EgoGym",
      skipIfExists: false,
    );

    if (result.isSuccess) {
      setState(() {
        _lastCapturedImagePath = newImageFile.path;
      });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ beautiful.")),
          );
        } else {
          throw Exception("فشل حفظ الصورة في المعرض.");
        }
      } catch (e) {
        print("Watermark Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ فشل: ${e.toString()}")),
        );
      }
    }


  // دالة وهمية للانتقال إلى المعرض
// دالة عرض آخر صورة ملتقطة (أكثر فائدة)
void _showLastCapturedImage() {
    if (_lastCapturedImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("لم يتم التقاط أي صورة بعد.")),
        );
        return;
    }
    
    // عرض الصورة الملتقطة في نافذة حوار (Dialog)
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: AppColors.blackColor,
            title: const Text("آخر صورة ملتقطة", style: TextStyle(color: AppColors.whiteColor)),
            content: Image.file(
                File(_lastCapturedImagePath!),
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.height * 0.5,
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("إغلاق", style: TextStyle(color: AppColors.secondaryColor1)),
                ),
            ],
        ),
    );
}
// 🔥 دالة بناء واجهة المستخدم في حالة عدم وجود إذن (يجب إضافتها داخل _CameraScreenState)
Widget _buildPermissionDeniedWidget(Size media) {
    return Container(
        width: double.maxFinite,
        height: media.height, 
        decoration: const BoxDecoration(
           color: AppColors.blackColor,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(30),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Icon(Icons.camera_alt_outlined, size: 60, color: AppColors.primaryColor1), // تم تغيير اللون ليتناسب مع الثيم
                const SizedBox(height: 20),
                const Text(
                    "يتطلب هذا التطبيق إذن الوصول إلى الكاميرا.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // ✅ التعديل الذي يجب وضعه (استبدال RoundGradientButton بالكامل)
InkWell(
    // 💡 الآن يمكننا تمرير null بأمان
    onTap: _isPermissionRequesting ? null : () {
        // نستخدم الدالة غير المتزامنة هنا كما تعلمنا
        () async {
            var status = await Permission.camera.status;
            if (status.isPermanentlyDenied) {
                await launchUrl(Uri.parse('app-settings:'), mode: LaunchMode.platformDefault); 
            } else {
                await _requestPermissionAndInitializeCamera();
            }
        }();
    },
    child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        // استخدام نفس تدرج الألوان (Gradients)
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryG),
            borderRadius: BorderRadius.circular(30),
            boxShadow: _isPermissionRequesting ? null : const [
                BoxShadow(
                    color: Colors.black26, 
                    blurRadius: 10, 
                    offset: Offset(0, 4)
                ),
            ],
        ),
        alignment: Alignment.center,
        child: Text(
            _isPermissionRequesting ? "جارٍ الطلب..." : "طلب الإذن/فتح الإعدادات",
            style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
            ),
        ),
    ),
)],
        ),
    );
}
// دالة وهمية للانتقال إلى المعرض (المُعدَّلة)
void _openGallery() async {
  if (_isPickingOrCapturing) return; // 🟢 منع التزامن

  setState(() {
    _isPickingOrCapturing = true;
  });

  try {
    final ImagePicker picker = ImagePicker();
    
    // هذا الأمر يفتح المعرض للسماح للمستخدم باختيار صورة
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) {
        print("تم فتح المعرض، لكن لم يتم اختيار صورة.");
    } else {
        print("تم اختيار الصورة: ${image.path}");
        // 💡 يمكنك إضافة منطق معالجة الصورة أو العلامة المائية هنا إذا أردت معالجة صور المعرض.
    }
  } catch (e) {
    print("Gallery Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل فتح المعرض: ${e.toString()}")),
    );
  } finally {
    setState(() {
      _isPickingOrCapturing = false; // 🟢 إعادة التعيين
    });
  }
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
         return const Scaffold(
          backgroundColor: AppColors.blackColor,
          body: Center(
              child: Padding(
                  padding: EdgeInsets.all(30.0),
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
                      onTap: _openGallery,
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
      ), bottomNavigationBar: const BottomAppBar(
        color: Colors.transparent, 
        elevation: 0, // نلغي الظل
        height:  10, // ارتفاع بسيط ليرفع الزر قليلاً
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[], // لا توجد عناصر فعلية
        ),
      ),                  
    );
  }
}