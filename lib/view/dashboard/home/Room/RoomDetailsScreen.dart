import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // 🟢 1. إضافة مكتبة File
import 'package:firebase_storage/firebase_storage.dart'; // 🟢 2. إضافة مكتبة Firebase Storage

// ⚠️ تأكد أن مسار الاستيراد هذا صحيح
import 'GymRoomsScreen.dart'; 
// (يفترض أن هذا الملف يحتوي على AppColors وتعريف GymRoom)


// =========================================================================
// 0. تعريف الألوان (Ego Gym Theme)
// =========================================================================
class AppColors {
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

// =========================================================================
// 1. شاشة تفاصيل الغرفة (RoomDetailsScreen)
// =========================================================================

class RoomDetailsScreen extends StatefulWidget {
  final GymRoom room;

  const RoomDetailsScreen({super.key,  required this.room});

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
  bool get isParticipant => widget.room.participantUids.contains(currentUserId);

  Map<String, dynamic>? _replyToMessage; 

  late final CollectionReference messagesRef;
  late final DocumentReference roomRef; 

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'ar'; 
    
    // 🔥 تهيئة مراجع Firestore
    roomRef = _firestore
        .collection('artifacts')
        .doc('default-app-id')
        .collection('public')
        .doc('data')
        .collection('room')
        .doc(widget.room.id); 

    messagesRef = roomRef.collection('messages');
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  void _setReplyTo(Map<String, dynamic>? message) {
    setState(() {
      _replyToMessage = message;
      // تركيز حقل الإدخال بعد تحديد الرد
      FocusScope.of(context).requestFocus(FocusNode()); 
    });
  }

  // =========================================================================
  // 2. منطق الإغلاق والمغادرة (Close & Leave)
  // =========================================================================
  
  void _closeRoom() async {
    final confirmed = await _showConfirmationDialog(
      'تأكيد الإغلاق', 
      'هل أنت متأكد من رغبتك في إغلاق هذه الغرفة وإنهاء الجلسة؟ سيتم إخفاؤها من القائمة الرئيسية.', 
      'إغلاق',
      isDestructive: true,
    );
    
    if (confirmed) {
      try {
        await roomRef.update({'isClosed': true});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إغلاق الغرفة بنجاح. سيتم توجيهك الآن.')),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        _showAlertDialog('خطأ في الإغلاق', 'فشل في إغلاق الغرفة.');
      }
    }
  }

  void _leaveRoom() async {
    final confirmed = await _showConfirmationDialog(
      'تأكيد المغادرة', 
      'هل أنت متأكد من مغادرة الغرفة؟ لن تتمكن من رؤية المحادثة بعد المغادرة.', 
      'مغادرة',
      isDestructive: true
    );
    
    if (confirmed) {
      try {
        await roomRef.update({
          'participants': FieldValue.arrayRemove([
             widget.room.participants.firstWhere((p) => p['uid'] == currentUserId, orElse: () => null)
          ].where((item) => item != null).toList()),
          'participantUids': FieldValue.arrayRemove([currentUserId]),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم مغادرة الغرفة بنجاح.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        _showAlertDialog('خطأ في المغادرة', 'فشل في مغادرة الغرفة. يرجى المحاولة لاحقاً.');
      }
    }
  }
  
  // 💡 دالة مساعدة لعرض حالة العملية (نجاح/خطأ)
  void _showStatusSnackBar(String message, {bool isError = false}) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryColor1,
        ),
      );
  }

  // =========================================================================
  // 3. منطق إرسال الرسالة واختيار الصورة (مُفعّل بالكامل)
  // =========================================================================
  
  void _pickImageFromGallery() async {
    
    // 🛑 التحقق من المشاركة قبل الإرسال
    if (!isParticipant) {
        _showAlertDialog('غير مسموح', 'يجب أن تكون مشاركاً في الغرفة لتتمكن من إرسال الرسائل.');
        return;
    }
    
    print('Gallery button pressed! Attempting to open image picker...');
    
    try {
      final picker = ImagePicker(); 
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80); 
      
      if (pickedFile != null) {
        
        _showStatusSnackBar('جاري رفع الصورة...', isError: false);
        
        // 1. إنشاء مرجع للتخزين (Storage Reference)
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child(widget.room.id)
            .child('${DateTime.now().millisecondsSinceEpoch}_$currentUserId.jpg');

        // 2. رفع الملف
        final uploadTask = storageRef.putFile(File(pickedFile.path));
        final snapshot = await uploadTask.whenComplete(() {});
        
        // 3. الحصول على رابط التنزيل
        final imageUrl = await snapshot.ref.getDownloadURL();
        
        // 4. إرسال الرسالة إلى Firestore
        await messagesRef.add({
          'text': '', // نترك النص فارغاً أو نضع نصاً افتراضياً
          'senderId': currentUserId,
          'senderName': currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
          'reactions': [],
          'type': 'image', // 💡 تحديد نوع الرسالة كصورة
          'imageUrl': imageUrl, // 💡 إضافة رابط الصورة
        });
        
        _showStatusSnackBar('تم إرسال الصورة بنجاح!', isError: false);
        print('Image successfully uploaded and message sent.');

      } else {
        _showStatusSnackBar('تم إلغاء اختيار الصورة.', isError: false);
        print('Image selection cancelled.');
      }
      
    } catch (e) {
      _showStatusSnackBar('حدث خطأ أثناء رفع الصورة أو إرسالها. يرجى مراجعة الصلاحيات.', isError: true); 
      print('Image processing/upload error: $e'); 
    }
  }


  void _sendMessage() async {
    // 🛑 التحقق من المشاركة قبل الإرسال
    if (!isParticipant) {
        _showAlertDialog('غير مسموح', 'يجب أن تكون مشاركاً في الغرفة لتتمكن من إرسال الرسائل.');
        return;
    }
    
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final Map<String, dynamic> messageData = {
      'text': text,
      'senderId': currentUserId,
      'senderName': currentUserName,
      'timestamp': FieldValue.serverTimestamp(),
      'reactions': [],
      'type': 'text', // 💡 إضافة نوع الرسالة النصية
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
      _setReplyTo(null); 
    } catch (e) {
      print('Error sending message: $e');
    }
  }
  
  // =========================================================================
  // 4. منطق التفاعل (Reactions)
  // =========================================================================
  
  void _addReaction(String messageId, String emoji, List<dynamic> currentReactions) async {
    
    // 1. إزالة أي تفاعل سابق لنفس المستخدم
    final List<Map<String, dynamic>> updatedReactions = currentReactions
        .where((r) => r['uid'] != currentUserId)
        .map((r) => r as Map<String, dynamic>)
        .toList();
        
    final newReaction = {
      'uid': currentUserId,
      'name': currentUserName,
      'emoji': emoji,
    };
    
    // 2. إضافة التفاعل الجديد
    updatedReactions.add(newReaction);
    
    try {
        final docRef = messagesRef.doc(messageId);
        // 3. تحديث قائمة التفاعلات بالكامل
        await docRef.update({'reactions': updatedReactions}); 

    } catch (e) {
      print('Error adding reaction: $e');
    }
  }


  // =========================================================================
  // 5. بناء واجهة المستخدم الرئيسية
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    if (!isParticipant) {
      // ⚠️ منع المستخدمين غير المشاركين من رؤية الشات 
      return Scaffold(
        backgroundColor: AppColors.blackColor,
        appBar: AppBar(
          title: Text(widget.room.title, style: const TextStyle(color: AppColors.whiteColor)),
          backgroundColor: AppColors.blackColor,
          iconTheme: const IconThemeData(color: AppColors.whiteColor),
        ),
        body: const Center( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 60, color: AppColors.primaryColor1),
              SizedBox(height: 20),
              Text(
                'يجب الانضمام للغرفة لرؤية المحادثة وإرسال الرسائل.',
                style: TextStyle(fontSize: 16, color: AppColors.darkGrayColor),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.blackColor, 
      appBar: AppBar(
        title: Text(widget.room.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        backgroundColor: AppColors.blackColor, 
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.whiteColor), 
        actions: [
          // 🔥 زر الإغلاق (للمنشئ فقط)
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.lock_open, color: AppColors.accentColor), 
              onPressed: _closeRoom, 
            ),
          
          // 🔥 زر المغادرة (للمشارك وغير المنشئ)
          if (!isCreator && isParticipant)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: AppColors.darkGrayColor), 
              onPressed: _leaveRoom,
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
          
          // 🟢 صندوق الرد
          if (_replyToMessage != null) 
            _buildReplyToBox(),

          _buildMessageInput(),
        ],
      ),
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
            
            data['id'] = doc.id;
            
            return _buildMessageBubble(doc.id, data, isMe); 
          },
        );
      },
    );
  }
  
  // =========================================================================
  // 6. تصميم فقاعة الرسالة (Message Bubble)
  // =========================================================================
  
  Widget _buildMessageBubble(String messageId, Map<String, dynamic> data, bool isMe) {
    final timestamp = data['timestamp'] as Timestamp?;
    final replyTo = data['replyTo'] as Map<String, dynamic>?; 
    final reactions = data['reactions'] as List<dynamic>? ?? []; 
    
    // 💡 الحصول على نوع الرسالة
    final messageType = data['type'] as String? ?? 'text'; 
    
    String timeString = timestamp != null 
        ? DateFormat('hh:mm a', 'ar').format(timestamp.toDate().toLocal()) 
        : 'الآن';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showReactionOptions(messageId, data, reactions),
            onTap: () => _setReplyTo(data),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryColor1 : AppColors.cardBackgroundColor, 
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(5),
                  bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(15),
                ),
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
                  if (replyTo != null)
                    _buildReplyToIndicator(replyTo),
                  
                  if (!isMe)
                    Text(
                      data['senderName'] ?? 'مستخدم',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentColor,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),

                  // 🔥 منطق عرض محتوى الرسالة (صورة أو نص)
                  if (messageType == 'image' && data['imageUrl'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imageUrl'],
                            width: 200, 
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                width: 200, 
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accentColor,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => 
                              const Text('فشل تحميل الصورة', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        // عرض نص إضافي إذا وُجد
                        if (data['text'] != null && data['text']!.isNotEmpty) 
                           Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text(
                               data['text']!,
                               style: TextStyle(
                                 color: isMe ? AppColors.whiteColor : AppColors.darkGrayColor,
                                 fontSize: 15,
                               ),
                             ),
                           ),
                      ],
                    )
                  else
                    // عرض الرسالة النصية العادية
                    Text(
                      data['text'] ?? 'رسالة فارغة',
                      style: TextStyle(
                        color: isMe ? AppColors.whiteColor : AppColors.darkGrayColor,
                        fontSize: 15,
                      ),
                    ),
                  // 🔥 نهاية منطق عرض المحتوى

                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
  
  // 🟢 مؤشر الرسالة المردود عليها
  Widget _buildReplyToIndicator(Map<String, dynamic> replyTo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.replyColor,
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
              color: AppColors.accentColor,
            ),
          ),
          Text(
            replyTo['originalText'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // 🟢 عرض التفاعلات المجمعة
// 🟢 عرض التفاعلات المجمعة (تمت إضافتها لإظهار قائمة بأسماء المتفاعلين)
Widget _buildReactionsDisplay(List<dynamic> reactions) {
  final Map<String, List<String>> reactionsMap = {};
  
  for (var reaction in reactions) {
    final emoji = reaction['emoji'] as String;
    final name = reaction['name'] as String;
    
    // تجميع الأسماء حسب نوع التفاعل
    if (!reactionsMap.containsKey(emoji)) {
      reactionsMap[emoji] = [];
    }
    reactionsMap[emoji]!.add(name);
  }
  
  return GestureDetector( // 💡 جعل المنطقة قابلة للضغط
    onTap: () {
      if (reactions.isNotEmpty) {
        _showReactorsList(reactionsMap); // استدعاء الدالة الجديدة
      }
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: reactionsMap.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentColor, width: 0.5),
          ),
          child: Text(
            // عرض عدد الأشخاص في كل نوع تفاعل
            '${entry.key} ${entry.value.length}', 
            style: const TextStyle(fontSize: 10, color: AppColors.darkGrayColor),
          ),
        );
      }).toList(),
    ),
  );
}
  // 🟢 إظهار خيارات التفاعل عند الضغط المطول
  void _showReactionOptions(String messageId, Map<String, dynamic> data, List<dynamic> currentReactions) {
    final List<String> availableReactions = ['👍', '❤️', '😂', '🔥', '👏']; 

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackgroundColor,
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
              const Divider(color: AppColors.darkGrayColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: availableReactions.map((emoji) {
                  return IconButton(
                    icon: Text(emoji, style: const TextStyle(fontSize: 30)),
                    onPressed: () {
                      _addReaction(messageId, emoji, currentReactions);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const Divider(color: AppColors.darkGrayColor),
              // 🟢 خيار الرد هنا أيضاً
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

  // 🟢 صندوق عرض الرسالة المردود عليها
  Widget _buildReplyToBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.replyColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentColor, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ترد على: ${_replyToMessage!['senderName'] ?? 'مستخدم'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentColor),
                ),
                Text(
                  _replyToMessage!['text'] ?? 'رسالة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.whiteColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.darkGrayColor, size: 20),
            onPressed: () => _setReplyTo(null),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 7. الـ Widgets المساعدة
  // =========================================================================

  void _toggleWorkoutStatus() {
    if (!isCreator) {
      _showAlertDialog('غير مسموح', 'فقط مؤسس الغرفة (${widget.room.creatorName}) هو من يمكنه بدء التمرين.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar( 
        content: Text('تم بدء التمرين بنجاح!'), 
        backgroundColor: AppColors.primaryColor1,
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryColor1.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text( 
            'التفاصيل:',
            style: TextStyle(fontSize: 14, color: AppColors.accentColor, fontWeight: FontWeight.bold),
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
            DateFormat('EEEE, hh:mm a', 'ar').format(widget.room.startTime.toDate().toLocal()),
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
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGrayColor),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.w500),
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
        color: AppColors.cardBackgroundColor,
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 1)),
      ),
      child: SafeArea( 
        child: Row(
          children: [
            // 🔥 زر المعرض (يستدعي الدالة المعدلة)
            IconButton(
              icon: const Icon(Icons.photo_library, color: AppColors.accentColor), 
              onPressed: _pickImageFromGallery, // 💡 استدعاء الدالة الجديدة
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.whiteColor),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: const TextStyle(color: AppColors.darkGrayColor), 
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.blackColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(), 
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primaryColor1),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message, String confirmText, {bool isDestructive = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackgroundColor,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        content: Text(message, style: const TextStyle(color: AppColors.darkGrayColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.darkGrayColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: TextStyle(color: isDestructive ? Colors.red : AppColors.accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackgroundColor,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        content: Text(message, style: const TextStyle(color: AppColors.darkGrayColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(color: AppColors.accentColor)),
          )
        ],
      ),
    );
  }
  // =========================================================================
// 8. عرض قائمة المتفاعلين
// =========================================================================

void _showReactorsList(Map<String, List<String>> reactionsMap) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cardBackgroundColor,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأشخاص الذين تفاعلوا', 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: AppColors.whiteColor
              )
            ),
            Divider(color: AppColors.darkGrayColor.withOpacity(0.5)),
            
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: reactionsMap.entries.map((entry) {
                  final emoji = entry.key;
                  final names = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$emoji (${names.length})', // عرض التفاعل وعدد المتفاعلين به
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.accentColor
                          ),
                        ),
                        // عرض قائمة الأسماء
                        ...names.map((name) => Padding(
                          padding: const EdgeInsets.only(right: 15.0, top: 2),
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 14, color: AppColors.darkGrayColor),
                            textAlign: TextAlign.start,
                          ),
                        )).toList(),
                        
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
}