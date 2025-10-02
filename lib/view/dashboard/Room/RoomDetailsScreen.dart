import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ⚠️ تأكد أن مسار الاستيراد هذا صحيح
import 'GymRoomsScreen.dart'; 
// (يجب أن يكون ملف GymRoomsScreen.dart يحتوي على AppColors و GymRoom)

// =========================================================================
// 0. تعريف الألوان (Ego Gym Theme - Deep Red/Maroon & Electric Gold)
// =========================================================================
class AppColors {
  // ألوان Ego Gym التي تم استخدامها سابقاً
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); // Dark Background
  static const Color darkGrayColor = Color(0xFFC0C0C0); // Lighter Gray for text on dark bg
  static const Color primaryColor1 = Color(0xFF8B0000); // Dark Maroon/Deep Red
  static const Color accentColor = Color(0xFFFFA500); // Electric Gold/Amber
  static const Color accentGradientStart = Color(0xFFFFCC00); // Lighter Gold
  static const Color accentGradientEnd = Color(0xFF8B0000); // Maroon/Deep Red
  static const Color cardBackgroundColor = Color(0xFF222222); // Dark background for cards
  static const Color replyColor = Color(0xFF4B0082); // Indigo/Dark Violet for Reply Indicator
}

// ⚠️ يجب أن يكون نموذج GymRoom موجوداً في ملف GymRoomsScreen.dart أو مُعاراً هنا ليعمل الكود

// =========================================================================
// 1. شاشة تفاصيل الغرفة (RoomDetailsScreen) - مُعدَّلة
// =========================================================================

class RoomDetailsScreen extends StatefulWidget {
  // ⚠️ تم إهمال تعريف GymRoom هنا (افتراضاً أنه مُستورد)
  final GymRoom room;

  const RoomDetailsScreen({super.key, required this.room});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; 
  final _messageController = TextEditingController(); 
  
  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'مستخدم غير معروف';
  bool get isCreator => widget.room.creatorId == currentUserId;
  
  // 🟢 حالة جديدة للرد على الرسائل
  Map<String, dynamic>? _replyToMessage; 

  late final CollectionReference messagesRef;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'ar'; 
    
    // 🔥 تهيئة مرجع الرسائل داخل وثيقة الغرفة
    messagesRef = _firestore
        .collection('artifacts')
        .doc('default-app-id')
        .collection('public')
        .doc('data')
        .collection('room')
        .doc(widget.room.id) 
        .collection('messages'); 
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  // 🟢 وظيفة لتعيين الرسالة المراد الرد عليها
  void _setReplyTo(Map<String, dynamic>? message) {
    setState(() {
      _replyToMessage = message;
      // تركيز حقل الإدخال بعد تحديد الرد
      FocusScope.of(context).requestFocus(FocusNode()); 
    });
  }

  // =========================================================================
  // 2. منطق إرسال الرسالة - مُعدَّل لدعم الرد
  // =========================================================================

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // 🟢 تجهيز بيانات الرد (إذا كان موجوداً)
    final Map<String, dynamic> messageData = {
      'text': text,
      'senderId': currentUserId,
      'senderName': currentUserName,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    if (_replyToMessage != null) {
      messageData['replyTo'] = {
        'originalSenderName': _replyToMessage!['senderName'],
        'originalText': _replyToMessage!['text'],
      };
    }

    try {
      await messagesRef.add(messageData);
      _messageController.clear(); 
      // 🟢 مسح حالة الرد بعد الإرسال
      _setReplyTo(null); 
    } catch (e) {
      print('Error sending message: $e');
    }
  }
  
  // =========================================================================
  // 3. منطق التفاعل (Reactions)
  // =========================================================================
  
  void _addReaction(String messageId, String emoji) async {
    final reactionData = {
      'uid': currentUserId,
      'name': currentUserName,
      'emoji': emoji,
    };
    
    try {
        final docRef = messagesRef.doc(messageId);
        
        await docRef.update({
            // استخدام ArrayUnion لإضافة تفاعل جديد (قد يتم تكرار الـ UID، يتطلب منطق إضافي لمنع تكرار تفاعل المستخدم الواحد)
            'reactions': FieldValue.arrayUnion([reactionData]), 
        });

    } catch (e) {
      print('Error adding reaction: $e');
    }
  }


  // =========================================================================
  // 4. بناء واجهة المستخدم الرئيسية - استخدام ألوان Ego Gym
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor, // خلفية سوداء داكنة
      appBar: AppBar(
        title: Text(widget.room.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        backgroundColor: AppColors.blackColor, // خلفية سوداء للشريط
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.whiteColor), // أيقونات بيضاء
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.lock_open, color: AppColors.accentColor), // أيقونة ذهبية
              onPressed: () => _showAlertDialog(
                'إغلاق الغرفة', 
                'هل أنت متأكد من رغبتك في إغلاق هذه الغرفة وإنهاء الجلسة؟'
              ),
            ),
        ],
      ),
      
      body: Column(
        children: [
          _buildRoomInfoCard(),

          // 🔥 قسم الشات الفعلي
          Expanded(
            child: _buildChatMessagesList(),
          ),
          
          // 🟢 إضافة صندوق الرد في حال وجود رسالة للرد عليها
          if (_replyToMessage != null) 
            _buildReplyToBox(),

          _buildMessageInput(),
        ],
      ),
      
     // floatingActionButton: _buildMainActionButton(),
    );
  }

  Widget _buildChatMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: messagesRef.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في تحميل الرسائل: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'ابدأ محادثة جديدة!',
              style: TextStyle(color: AppColors.darkGrayColor, fontSize: 16),
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true, 
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>;
            final isMe = data['senderId'] == currentUserId;
            
            return _buildMessageBubble(doc.id, data, isMe); // تمرير ID الرسالة
          },
        );
      },
    );
  }
  
  // =========================================================================
  // 5. تصميم فقاعة الرسالة (Message Bubble) - تصميم Ego Gym
  // =========================================================================
  
  Widget _buildMessageBubble(String messageId, Map<String, dynamic> data, bool isMe) {
    final timestamp = data['timestamp'] as Timestamp?;
    final replyTo = data['replyTo'] as Map<String, dynamic>?; 
    final reactions = data['reactions'] as List<dynamic>? ?? []; 
    
    String timeString = timestamp != null 
        ? DateFormat('hh:mm a').format(timestamp.toDate()) 
        : 'الآن';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 🟢 تمكين الضغط الطويل للرد والتفاعل
          GestureDetector(
            onLongPress: () => _showReactionOptions(messageId, data),
            onTap: () => _setReplyTo(data), // 🟢 الضغط الخفيف للرد
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12), // زيادة التباعد قليلاً
              decoration: BoxDecoration(
                // ألوان الثيم الداكن
                color: isMe ? AppColors.primaryColor1 : AppColors.cardBackgroundColor, 
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(5),
                  bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(15),
                ),
                // إضافة ظل خفيف للبروز
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 🟢 عرض معلومات الرد
                  if (replyTo != null)
                    _buildReplyToIndicator(replyTo),
                  
                  if (!isMe)
                    Text(
                      data['senderName'] ?? 'مستخدم',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentColor, // اسم المرسل بالذهبي
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),

                  Text(
                    data['text'] ?? 'رسالة فارغة',
                    style: TextStyle(
                      color: isMe ? AppColors.whiteColor : AppColors.darkGrayColor, // نص أبيض على الماروني/نص فاتح على الداكن
                      fontSize: 15,
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         // 🟢 عرض التفاعلات
                        if (reactions.isNotEmpty)
                          _buildReactionsDisplay(reactions),
                        
                        const Spacer(),
                        
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? AppColors.whiteColor.withOpacity(0.7) : AppColors.darkGrayColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 🟢 مؤشر الرسالة المردود عليها (تصميم داكن)
  Widget _buildReplyToIndicator(Map<String, dynamic> replyTo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.replyColor, // لون مميز للرد
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رد على: ${replyTo['originalSenderName']}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.accentColor, // اسم المرسل بالذهبي
            ),
          ),
          Text(
            replyTo['originalText'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.whiteColor, // نص أبيض
            ),
          ),
        ],
      ),
    );
  }
  
  // 🟢 عرض التفاعلات المجمعة (تعديل الألوان)
  Widget _buildReactionsDisplay(List<dynamic> reactions) {
    final Map<String, int> reactionCounts = {};
    
    for (var reaction in reactions) {
      final emoji = reaction['emoji'] as String;
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reactionCounts.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundColor, // خلفية داكنة
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentColor, width: 0.5), // إطار ذهبي خفيف
          ),
          child: Text(
            '${entry.key} ${entry.value}',
            style: const TextStyle(fontSize: 10, color: AppColors.darkGrayColor), // نص فاتح
          ),
        );
      }).toList(),
    );
  }
  
  // 🟢 إظهار خيارات التفاعل عند الضغط المطول (تعديل الألوان)
  void _showReactionOptions(String messageId, Map<String, dynamic> data) {
    final List<String> availableReactions = ['👍', '❤️', '😂', '🔥', '👏']; 

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackgroundColor, // خلفية داكنة
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'التفاعل مع رسالة: ${data['senderName']}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.whiteColor)
              ),
              Divider(color: AppColors.darkGrayColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: availableReactions.map((emoji) {
                  return IconButton(
                    icon: Text(emoji, style: const TextStyle(fontSize: 30)),
                    onPressed: () {
                      _addReaction(messageId, emoji);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              Divider(color: AppColors.darkGrayColor),
              // 🟢 إضافة خيار الرد هنا أيضاً
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.primaryColor1),
                title: const Text('الرد على الرسالة', style: TextStyle(color: AppColors.whiteColor)),
                onTap: () {
                  Navigator.pop(context);
                  _setReplyTo(data);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🟢 صندوق عرض الرسالة المردود عليها (تصميم داكن)
  Widget _buildReplyToBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.replyColor.withOpacity(0.5), // خلفية شفافة قليلاً
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentColor, width: 1.5), // إطار ذهبي
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ترد على: ${_replyToMessage!['senderName'] ?? 'مستخدم'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentColor), // ذهبي
                ),
                Text(
                  _replyToMessage!['text'] ?? 'رسالة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.whiteColor), // أبيض
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.darkGrayColor, size: 20),
            onPressed: () => _setReplyTo(null), // إلغاء الرد
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. الـ Widgets المساعدة (تعديل الألوان)
  // =========================================================================

  void _toggleWorkoutStatus() {
    if (!isCreator) {
      _showAlertDialog('غير مسموح', 'فقط مؤسس الغرفة (${widget.room.creatorName}) هو من يمكنه بدء التمرين.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم بدء التمرين بنجاح!'), 
        backgroundColor: AppColors.primaryColor1,
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor, // لون بطاقة داكن
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryColor1.withOpacity(0.5), width: 1), // إطار ماروني خفيف
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التفاصيل:',
            style: TextStyle(fontSize: 14, color: AppColors.accentColor, fontWeight: FontWeight.bold), // ذهبي
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.fitness_center, 
            'العضلة المستهدفة', 
            widget.room.targetMuscle,
            AppColors.accentColor,
          ),
          _buildDetailRow(
            Icons.access_time_filled, 
            'وقت البدء', 
            DateFormat('EEEE, hh:mm a', 'ar').format(widget.room.startTime.toDate()),
            AppColors.primaryColor1,
          ),
          _buildDetailRow(
            Icons.people_alt, 
            'المشاركون', 
            '${widget.room.participants.length} / ${widget.room.maxCapacity} مشترك',
            AppColors.darkGrayColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGrayColor), // رمادي فاتح
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w500), // أبيض
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.cardBackgroundColor, // خلفية داكنة لصندوق الإدخال
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 1)),
      ),
      child: SafeArea( 
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt, color: AppColors.accentColor), // ذهبي
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('سيتم فتح الكاميرا لمشاركة صورة التمرين هنا.'),
                    backgroundColor: AppColors.primaryColor1,
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.whiteColor), // نص الإدخال أبيض
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(color: AppColors.darkGrayColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.blackColor, // تعبئة سوداء داكنة
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(), 
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primaryColor1), // ماروني
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildMainActionButton() {
  //   final bool canStartWorkout = isCreator;
  //   final String label = canStartWorkout ? 'بدء التمرين' : 'مشاركة صورة (قريباً)';
  //   final IconData icon = canStartWorkout ? Icons.play_arrow : Icons.camera_alt;

  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(15),
  //       // زر متدرج (ماروني إلى ذهبي)
  //       gradient: LinearGradient(
  //         colors: canStartWorkout 
  //             ? [AppColors.accentColor, AppColors.primaryColor1]
  //             : [AppColors.darkGrayColor.withOpacity(0.8), AppColors.darkGrayColor.withOpacity(0.5)],
  //         begin: Alignment.bottomLeft,
  //         end: Alignment.topRight,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.primaryColor1.withOpacity(0.5),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: FloatingActionButton.extended(
  //       onPressed: canStartWorkout ? _toggleWorkoutStatus : () {
  //         _showAlertDialog('غير متاح حالياً', 'هذه الوظيفة قادمة قريباً. فقط مؤسس الغرفة يمكنه بدء التمرين.');
  //       },
  //       label: Text(
  //         label, 
  //         style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)
  //       ),
  //       icon: Icon(icon, color: AppColors.whiteColor),
  //       backgroundColor: Colors.transparent, // مهم لظهور التدرج
  //       elevation: 0,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //     ),
  //   );
  // }
  
  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackgroundColor, // خلفية داكنة
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        content: Text(message, style: const TextStyle(color: AppColors.darkGrayColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(color: AppColors.accentColor)), // ذهبي
          )
        ],
      ),
    );
  }
}