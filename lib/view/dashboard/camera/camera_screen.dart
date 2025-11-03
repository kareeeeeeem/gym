// ignore_for_file: use_build_context_synchronously

import 'package:fitnessapp/const/common_widgets/round_button.dart';
import 'package:fitnessapp/const/common_widgets/round_gradient_button.dart';
import 'package:fitnessapp/const/utils/app_colors.dart';
import 'package:flutter/material.dart';

// 📸 الحزم المطلوبة
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// 🔥 لمعالجة الأذونات
import 'package:permission_handler/permission_handler.dart';

// 🎨 لمعالجة الصور وإضافة العلامة المائية
import 'package:image/image.dart' as img;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:url_launcher/url_launcher.dart';


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
  bool _isPickingOrCapturing = false;
  bool _isPermissionRequesting = false;
  
  // ✅ [جديد] - لتتبع الكاميرا المختارة حالياً (مهم للتبديل)
  late CameraDescription _selectedCamera; 


  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      // ✅ [جديد] - تحديد الكاميرا الافتراضية
      _selectedCamera = widget.cameras.first;
    }
    _requestPermissionAndInitializeCamera();
  }
  
  @override
  void dispose() {
    // التأكد من عدم الوصول إلى الكنترولر إذا لم تكن الكاميرات موجودة
    if (widget.cameras.isNotEmpty && _controller.value.isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  // 🔥 الدالة لإنشاء واجهة المستخدم في حالة عدم وجود إذن
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
                const Icon(Icons.camera_alt_outlined, size: 60, color: AppColors.primaryColor1),
                const SizedBox(height: 20),
                const Text(
                    "Please restart the app",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // الزر لطلب الإذن/فتح الإعدادات
                InkWell(
                    onTap: _isPermissionRequesting ? null : () async {
                        var status = await Permission.camera.status;
                        if (status.isPermanentlyDenied) {
                            // استخدام url_launcher لفتح الإعدادات
                            await launchUrl(Uri.parse('app-settings:'), mode: LaunchMode.platformDefault); 
                        } else {
                            // طلب الإذن إذا لم يكن ممنوعًا بشكل دائم
                            await _requestPermissionAndInitializeCamera();
                        }
                    },
                    child: Container(
                        padding:  EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                        decoration: BoxDecoration(
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
                            _isPermissionRequesting ? "Please restart the app..." : "Request permission/open settings",
                            style: const TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                            ),
                        ),
                    ),
                ),
            ],
        ),
    );
}

  // =========================================================================
  // 1. منطق التبديل بين الكاميرات (الأمامية/الخلفية)
  // =========================================================================
  void _onSwitchCamera() async {
  if (_isPickingOrCapturing || _isPermissionRequesting || widget.cameras.length <= 1) return;

  setState(() {
    _isCameraReady = false;
  });

  try {
    // 1️⃣ أوقف الكنترولر الحالي وانتظر التخلص منه
    await _controller.dispose();

    // 2️⃣ تحديد الكاميرا الجديدة
    final currentCameraIndex = widget.cameras.indexOf(_selectedCamera);
    final newCameraIndex = (currentCameraIndex + 1) % widget.cameras.length;
    _selectedCamera = widget.cameras[newCameraIndex];

    // 3️⃣ إنشاء الكنترولر الجديد
    _controller = CameraController(
      _selectedCamera,
      ResolutionPreset.high,
      enableAudio: false, // تحسين الأداء
    );

    // 4️⃣ تهيئة الكاميرا وانتظارها فعليًا
    await _controller.initialize();

    if (!mounted) return;

    setState(() {
      _isCameraReady = true;
    });
  } catch (e) {
    print("Camera Switch Error: $e");
    setState(() {
      _isCameraReady = false;
    });
  }
}

  // =========================================================================
  // 2. طلب الإذن وتهيئة الكاميرا (تم تنقيحها)
  // =========================================================================
  Future<void> _requestPermissionAndInitializeCamera() async {
    if (_isPermissionRequesting || widget.cameras.isEmpty) return;
    
    if(mounted) {
      setState(() { _isPermissionRequesting = true; });
    }

    try {
      var status = await Permission.camera.request();
        
      if (status.isGranted) {
        setState(() { _hasCameraPermission = true; });
          
        _controller = CameraController(
            _selectedCamera, // ✅ استخدام الكاميرا المختارة
            ResolutionPreset.high, 
        );

        _initializeControllerFuture = _controller.initialize().then((_) {
            if (!mounted) return;
            setState(() { _isCameraReady = true; });
        }).catchError((e) {
            print("Camera Initialization Error: $e");
            setState(() { _isCameraReady = false; });
        });

      } else {
          setState(() { _hasCameraPermission = false; });
      }
    } catch (e) {
      print("Error during permission request: $e");
    } finally {
      if (mounted) {
          setState(() { _isPermissionRequesting = false; });
      }
    }
  }


  // =========================================================================
  // 3. التقاط الصورة وإضافة العلامة المائية
  // =========================================================================
  void _takePhotoAndSave() async {
    if (!_isCameraReady || !_controller.value.isInitialized || _isPickingOrCapturing) return;

    setState(() { _isPickingOrCapturing = true; }); // قفل الأزرار

    try {
      await _initializeControllerFuture;

      // 1. التقاط الصورة الفعلي
      final XFile imageFile = await _controller.takePicture();

      // 2. قراءة الملف كبايت وفك التشفير
      final bytes = await imageFile.readAsBytes();
img.Image? originalImage = img.decodeImage(bytes);

if (originalImage == null) throw Exception("Failer.");

// ✅ لو الكاميرا أمامية، اقلب الصورة أفقيًا
if (_selectedCamera.lensDirection == CameraLensDirection.front) {
  originalImage = img.flipHorizontal(originalImage);
}

      if (originalImage == null) throw Exception("فشل في فك تشفير الصورة.");

      // 3. إضافة العلامة المائية
      const String watermarkText = "Ego Gym";
      final int fontSize = (originalImage.height / 18).round().clamp(80, 120);
      const double charWidthFactor = 0.6;
      final int estimatedTextWidth = (fontSize * watermarkText.length * charWidthFactor).round();
      final int textX = originalImage.width - estimatedTextWidth - 40; // هامش 40
      final int textY = originalImage.height - fontSize - 40; // هامش 40
      final img.Color watermarkColor = img.ColorRgb8(200, 200, 200); 

      img.drawString(
        originalImage,
        watermarkText,
        font: img.arial14,
        x: textX,
        y: textY,
        color: watermarkColor,
      );

      // 4. حفظ في ملف مؤقت
      final tempDir = await getTemporaryDirectory();
      final newPath = '${tempDir.path}/EgoGym_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final File newImageFile = File(newPath);
      await newImageFile.writeAsBytes(img.encodeJpg(originalImage, quality: 90));

      // 5. حفظ في المعرض
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("✅ تم التقاط وحفظ الصورة بنجاح.")),
        // );
      } else {
        throw Exception("failed.");
      }
    } catch (e) {
      print("Capture Error: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("❌ فشل التقاط/معالجة الصورة: ${e.toString()}")),
      // );
    } finally {
      if (mounted) {
        setState(() { _isPickingOrCapturing = false; }); // فتح الأزرار
      }
    }
  }

  // =========================================================================
  // 4. عرض آخر صورة ملتقطة (لحل مشكلة "رؤية الصور")
  // =========================================================================
  void _showLastCapturedImage() {
      if (_lastCapturedImagePath == null) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text("لم يتم التقاط أي صورة بعد لعرضها.")),
          // );
          return;
      }
      
      // عرض الصورة الملتقطة في نافذة حوار (Dialog)
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              backgroundColor: AppColors.blackColor,
              title: const Text("last picture", style: TextStyle(color: AppColors.whiteColor)),
              content: Image.file(
                  File(_lastCapturedImagePath!),
                  fit: BoxFit.contain,
                  height: MediaQuery.of(context).size.height * 0.5,
              ),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("close", style: TextStyle(color: AppColors.primaryColor1)),
                  ),
              ],
          ),
      );
  }
  
  // =========================================================================
  // 5. فتح المعرض لاختيار صورة (لتلبية زر "الجاليري")
  // =========================================================================
  void _openGallery() async {
    if (_isPickingOrCapturing) return; // منع التزامن

    setState(() { _isPickingOrCapturing = true; });

    try {
      final ImagePicker picker = ImagePicker();
      
      // هذا الأمر يفتح المعرض للسماح للمستخدم باختيار صورة
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
          // 💡 هنا يمكنك إضافة منطق معالجة لصورة المعرض (مثل إضافة العلامة المائية إذا لزم الأمر)
          // ScaffoldMessenger.of(context).showSnackBar(
          //    SnackBar(content: Text("✅ تم اختيار صورة من المعرض: ${image.name}")),
          // );
      }
    } catch (e) {
      print("Gallery Error: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text("❌ فشل فتح المعرض: ${e.toString()}")),
      // );
    } finally {
      setState(() { _isPickingOrCapturing = false; }); 
    }
  }


// ... (بقية دوال المساعدة مثل _buildPermissionDeniedWidget تبقى كما هي)
// ... (دالة checkAndRequestCameraPermission تبقى كما هي)


  // =========================================================================
  // 6. دالة البناء (Build) مع التعديلات الجديدة
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    
    if (!_hasCameraPermission) {
      return Scaffold(
          backgroundColor: AppColors.blackColor,
          body: _buildPermissionDeniedWidget(media)
      );
    }
    
    if (widget.cameras.isEmpty) {
        return const Scaffold(
            backgroundColor: AppColors.blackColor,
            body: Center(
                child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Text("Please restart the application..",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: AppColors.primaryColor1))
                )
            )
        );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Progress Camera",
          style: TextStyle(color: AppColors.whiteColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          // ✅ [تعديل] - زر تبديل الكاميرا أصبح يعمل
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: AppColors.whiteColor),
            onPressed: _onSwitchCamera,
          ),
          const SizedBox(width: 8)
        ],
      ),
      backgroundColor: AppColors.blackColor,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          
          // 📸 منطقة الكاميرا الفعلية
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && _isCameraReady) {
                // 💡 [ملاحظة] - استخدام BoxFit.cover لملء الشاشة مع الحفاظ على الأبعاد.
                return SizedBox.expand(
  child: FittedBox(
    fit: BoxFit.cover, // 💡 يخلي الكاميرا تملى الشاشة كلها زي سناب شات
    child: SizedBox(
      width: _controller.value.previewSize?.height ?? 0,
      height: _controller.value.previewSize?.width ?? 0,
      child: CameraPreview(_controller),
    ),
  ),
);

              } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          "Error: Camera is not available (${snapshot.error})",
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
          // أزرار التحكم في الأسفل (المعرض، التقاط، عرض آخر صورة)
          // ------------------------------------------------------------------
          Container(
            height: media.height * 0.2,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Padding(
                padding: const EdgeInsets.only(bottom:  65.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    
                    // 1. زر المعرض (Gallery Icon) - لفتح المعرض واختيار صورة
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
                        height: 100,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: AppColors.primaryG),
                            borderRadius: BorderRadius.circular(37.5),
                            border: Border.all(color: AppColors.whiteColor, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black38, blurRadius: 15, offset: Offset(0, 8))
                            ]),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 55,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                    
                    // 3. ✅ [جديد] - زر عرض آخر صورة ملتقطة (لرؤية الصور)
                    InkWell(
                      onTap: _showLastCapturedImage,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: _lastCapturedImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  File(_lastCapturedImagePath!),
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ),
                              )
                            : const Icon(
                                Icons.visibility,
                                size: 28,
                                color: AppColors.whiteColor,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}