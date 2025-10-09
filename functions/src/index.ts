/**
 * هذا الكود يرسل إشعار FCM لجميع المستخدمين المشتركين في 'all_users' 
 * عند إنشاء وثيقة جديدة في مجموعة 'public_notifications'.
 */
// استخدام واجهة v1 للدوال السحابية
import * as functions from 'firebase-functions/v1'; 
import * as admin from 'firebase-admin'; // هذا الاستيراد صحيح

// تهيئة Firebase Admin SDK
admin.initializeApp();

// اسم المجموعة التي يتم الاستماع إليها
const NOTIFICATIONS_COLLECTION = 'public_notifications';

// اسم الموضوع (Topic) الذي يشترك فيه جميع المستخدمين
const GLOBAL_TOPIC = 'all_users'; 

/**
 * دالة تُطلق عند إنشاء وثيقة جديدة في 'public_notifications'.
 */
export const sendPublicNotification = functions.firestore
  .document(`${NOTIFICATIONS_COLLECTION}/{notificationId}`)
  .onCreate(async (snapshot, context) => {
    
    // تسجيل بيانات للمراقبة (للوصول إليها في لوحة تحكم Firebase)
    functions.logger.info("Function triggered by new notification document.", {
      notificationId: context.params.notificationId,
      triggeringUser: snapshot.data()?.senderId
    });

    const notificationData = snapshot.data();
    
    // التحقق من وجود البيانات الأساسية
    if (!notificationData.title || !notificationData.body) {
      functions.logger.log("Notification skipped: Missing title or body.");
      return null;
    }

    const title = notificationData.title as string;
    const body = notificationData.body as string;

    // بناء حمولة رسالة FCM
    const messagePayload: admin.messaging.Message = {
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
      
    } catch (error) {
      functions.logger.error('Error sending message:', error);
      return null;
    }
  });