import Flutter
import UIKit
import flutter_facebook_auth // [1] استيراد المكتبة الخاصة بالفيسبوك

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // [2] هذه الدالة الجديدة مهمة لمعالجة رابط العودة (URL Scheme) من فيسبوك
  override func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // نطلب من flutter_facebook_auth التعامل مع رابط العودة
        ApplicationDelegate.shared.application(
            application,
            open: url,
            options: options
        )
        // يجب أن نضمن استدعاء الدالة الأساسية (super) أيضًا
        return super.application(application, open: url, options: options)
    }
}
