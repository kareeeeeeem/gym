"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendPublicNotification = void 0;
/**
 * هذا الكود يرسل إشعار FCM لجميع المستخدمين المشتركين في 'all_users'
 * عند إنشاء وثيقة جديدة في مجموعة 'public_notifications'.
 */
// استخدام واجهة v1 للدوال السحابية
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin")); // هذا الاستيراد صحيح
// تهيئة Firebase Admin SDK
admin.initializeApp();
// اسم المجموعة التي يتم الاستماع إليها
const NOTIFICATIONS_COLLECTION = 'public_notifications';
// اسم الموضوع (Topic) الذي يشترك فيه جميع المستخدمين
const GLOBAL_TOPIC = 'all_users';
/**
 * دالة تُطلق عند إنشاء وثيقة جديدة في 'public_notifications'.
 */
exports.sendPublicNotification = functions.firestore
    .document(`${NOTIFICATIONS_COLLECTION}/{notificationId}`)
    .onCreate(async (snapshot, context) => {
    var _a;
    // تسجيل بيانات للمراقبة (للوصول إليها في لوحة تحكم Firebase)
    functions.logger.info("Function triggered by new notification document.", {
        notificationId: context.params.notificationId,
        triggeringUser: (_a = snapshot.data()) === null || _a === void 0 ? void 0 : _a.senderId
    });
    const notificationData = snapshot.data();
    // التحقق من وجود البيانات الأساسية
    if (!notificationData.title || !notificationData.body) {
        functions.logger.log("Notification skipped: Missing title or body.");
        return null;
    }
    const title = notificationData.title;
    const body = notificationData.body;
    // بناء حمولة رسالة FCM
    const messagePayload = {
        notification: {
            title: title,
            body: body,
            // يمكنك إضافة أيقونة أو صوت هنا
            // sound: 'default',
        },
        data: {
            // بيانات مخصصة ليتم معالجتها في التطبيق
            type: 'public_broadcast',
            sender_id: notificationData.senderId || 'admin',
            image: notificationData.image_path || '',
        },
        topic: GLOBAL_TOPIC, // الإرسال إلى الموضوع العام
    };
    try {
        // إرسال الإشعار
        const response = await admin.messaging().send(messagePayload);
        functions.logger.log('Successfully sent message to topic:', GLOBAL_TOPIC, 'Response:', response);
        return response;
    }
    catch (error) {
        functions.logger.error('Error sending message:', error);
        return null;
    }
});
//# sourceMappingURL=index.js.map