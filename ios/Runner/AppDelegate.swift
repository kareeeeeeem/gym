import UIKit
import Flutter
import FBSDKCoreKit // تم إضافة هذا الاستيراد: لإصلاح خطأ 'Cannot find ApplicationDelegate'
import flutter_facebook_auth // [1] استيراد المكتبة الخاصة بالفيسبوك

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // [3] تهيئة Facebook SDK (مهم لكي يعمل تسجيل الدخول)
    ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
    )
    
    GeneratedPluginRegistrant.register(with: self)
    // استدعاء تطبيق الـ super class
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // [2] هذه الدالة الجديدة مهمة لمعالجة رابط العودة (URL Scheme) من فيسبوك
  override func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // نطلب من FBSDKCoreKit التعامل مع رابط العودة
        let facebookHandled = ApplicationDelegate.shared.application(
            application,
            open: url,
            options: options
        )
        // نرجع true إذا قام فيسبوك بالتعامل مع الرابط أو إذا قامت الدالة الأساسية بالتعامل معه
        return facebookHandled || super.application(application, open: url, options: options)
    }
}
