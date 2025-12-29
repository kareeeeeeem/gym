import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Still needed for the type definition
import 'package:intl/intl.dart';
import 'dart:io'; 
import 'package:firebase_storage/firebase_storage.dart'; 

// ⚠️ تأكد أن مسار الاستيراد هذا صحيح
import 'GymRoomsScreen.dart'; 
// (يفترض أن هذا الملف يحتوي على AppColors وتعريف GymRoom)


// =========================================================================
// 0. تعريف الألوان (Ego Gym Theme - Modified for WhatsApp Style)
// =========================================================================
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); // Dark Background
  static const Color darkGrayColor = Color(0xFFC0C0C0); // Lighter Gray for text on dark bg
  static const Color primaryColor1 = Color(0xFF8B0000); // Dark Maroon/Deep Red (Original)
  static const Color whatsappGreen = Color(0xFFDCF8C6); // Light green/calm for 'isMe' messages
  static const Color accentColor = Color(0xFFFFA500); // Electric Gold/Amber
  static const Color accentGradientStart = Color(0xFFFFCC00); 
  static const Color accentGradientEnd = Color(0xFF8B0000); 
  static const Color cardBackgroundColor = Color(0xFF222222); // Dark background for cards (Other person's bubble)
  static const Color replyColor = Color(0xFF4B0082); // Indigo/Dark Violet for Reply Indicator
  static const Color darkTextColor = Color(0xFF1D1617); // Text color for light bubbles
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
  String get currentUserName => _auth.currentUser?.displayName ?? 'Unknown User';
  bool get isCreator => widget.room.creatorId == currentUserId;
  bool get isParticipant => widget.room.participantUids.contains(currentUserId);

  Map<String, dynamic>? _replyToMessage; 

  late final CollectionReference messagesRef;
  late final DocumentReference roomRef; 

  @override
  void initState() {
    super.initState();
    // 💡 تغيير الإعدادات المحلية إلى الإنجليزية
    Intl.defaultLocale = 'en_US'; 
    
    // 🔥 تهيئة مراجع Firestore (مع افتراض default-app-id)
    const appId = 'default-app-id'; // Use __app_id in a real environment
    roomRef = _firestore
        .collection('artifacts')
        .doc(appId)
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
    });
  }

  // =========================================================================
  // 2. منطق الإغلاق والمغادرة (Close & Leave)
  // =========================================================================
  
  void _closeRoom() async {
    final confirmed = await _showConfirmationDialog(
      'Confirm Closure', 
      'Are you sure you want to close this room and end the session? It will be hidden from the main list.', 
      'Close',
      isDestructive: true,
    );
    
    if (confirmed) {
      try {
        await roomRef.update({'isClosed': true});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room closed successfully. You will be redirected now.')),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        _showAlertDialog('Closure Error', 'Failed to close the room.');
      }
    }
  }

  void _leaveRoom() async {
    final confirmed = await _showConfirmationDialog(
      'Confirm Leave', 
      'Are you sure you want to leave the room? You will not be able to see the conversation afterward.', 
      'Leave',
      isDestructive: true
    );
    
    if (confirmed) {
      try {
        // تحديث قائمة المشاركين (participants) وقائمة UIDs
        await roomRef.update({
          // إزالة كائن المشارك من مصفوفة participants
          'participants': FieldValue.arrayRemove([
             // البحث عن المشارك الحالي في القائمة
             widget.room.participants.firstWhere((p) => p['uid'] == currentUserId, orElse: () => null)
          ].where((item) => item != null).toList()),
          // إزالة UID من مصفوفة participantUids
          'participantUids': FieldValue.arrayRemove([currentUserId]),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully left the room.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        _showAlertDialog('Leaving Error', 'Failed to leave the room. Please try again later.');
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
  // 3. منطق إرسال الرسالة واختيار الملف (Hash out: تم وضع تعليق على رفع الملفات)
  // =========================================================================
  
  // ⛔ تم وضع تعليق على الدالة: _showMediaPickerDialog
  /*
  void _showMediaPickerDialog() {
      if (!isParticipant) {
          _showAlertDialog('Not Allowed', 'You must be a participant in the room to send messages.');
          return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardBackgroundColor,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo, color: AppColors.accentColor),
                  title: const Text('Image from Gallery', style: TextStyle(color: AppColors.whiteColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadFile(isVideo: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: AppColors.primaryColor1),
                  title: const Text('Video from Gallery', style: TextStyle(color: AppColors.whiteColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadFile(isVideo: true);
                  },
                ),
              ],
            ),
          );
        },
      );
  }
  */

  // ⛔ تم وضع تعليق على الدالة: _uploadFile
  /*
  void _uploadFile({required bool isVideo}) async {
    
    if (!isParticipant) return;
    
    print('Media upload started. Is Video: $isVideo');
    
    try {
      final picker = ImagePicker(); 
      final XFile? pickedFile = isVideo
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery, imageQuality: 80); 
      
      if (pickedFile != null) {
        
        final fileType = isVideo ? 'Video' : 'Image';
        _showStatusSnackBar('Uploading $fileType...', isError: false);
        
        final storagePath = isVideo ? 'chat_videos' : 'chat_images';
        final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

        final storageRef = FirebaseStorage.instance
            .ref()
            .child(storagePath)
            .child(widget.room.id)
            .child('${DateTime.now().millisecondsSinceEpoch}_$currentUserId.${isVideo ? 'mp4' : 'jpg'}');

        final uploadTask = storageRef.putFile(File(pickedFile.path), SettableMetadata(contentType: mimeType));
        final snapshot = await uploadTask.whenComplete(() {});
        
        final fileUrl = await snapshot.ref.getDownloadURL();
        
        await messagesRef.add({
          'text': _messageController.text.trim(), 
          'senderId': currentUserId,
          'senderName': currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
          'reactions': [],
          'type': isVideo ? 'video' : 'image', 
          'fileUrl': fileUrl, 
        });

        _messageController.clear(); 
        
        _showStatusSnackBar('$fileType sent successfully!', isError: false);
        print('$fileType successfully uploaded and message sent.');

      } else {
        _showStatusSnackBar('File selection cancelled.', isError: false);
        print('Media selection cancelled.');
      }
      
    } catch (e) {
      _showStatusSnackBar('An error occurred during file upload. Check permissions.', isError: true); 
      print('Media processing/upload error: $e'); 
    }
  }
  */


  void _sendMessage() async {
    // 🛑 التحقق من المشاركة قبل الإرسال
    if (!isParticipant) {
        _showAlertDialog('Not Allowed', 'You must be a participant in the room to send messages.');
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
        // بما أن الرفع معطل، سنركز على النصوص فقط في الردود
        'originalText': _replyToMessage!['text'] ?? 'Attached message', 
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
                'You must join the room to view the conversation and send messages.',
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
          
          // 🟢 صندوق الرد (واجهة محسّنة)
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
          return Center(child: Text('Error loading messages: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Start a new conversation!',
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
  // 6. تصميم فقاعة الرسالة (Message Bubble - WhatsApp Style)
  // =========================================================================
  
  Widget _buildMessageBubble(String messageId, Map<String, dynamic> data, bool isMe) {
    final timestamp = data['timestamp'] as Timestamp?;
    final replyTo = data['replyTo'] as Map<String, dynamic>?; 
    final reactions = data['reactions'] as List<dynamic>? ?? []; 
    
    // 💡 بما أن الرفع معطل، هذا الجزء يتم تجاهله عملياً في الـ UI
    final messageType = data['type'] as String? ?? 'text'; 
    final fileUrl = data['fileUrl'] as String?; 

    // 💡 استخدام 'en_US' لضمان تنسيق الوقت الإنجليزي
    String timeString = timestamp != null 
        ? DateFormat('hh:mm a', 'en_US').format(timestamp.toDate().toLocal()) 
        : 'Now';

    // 💡 تحديد لون الخلفية والنص بناءً على المرسل
    final bubbleColor = isMe ? AppColors.whatsappGreen : AppColors.cardBackgroundColor; 
    final textColor = isMe ? AppColors.darkTextColor : AppColors.whiteColor;
    
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
                color: bubbleColor,
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
                crossAxisAlignment: CrossAxisAlignment.start, // Align everything to start for simplicity
                children: [
                  if (replyTo != null)
                    _buildReplyToIndicator(replyTo, isMe),
                  
                  if (!isMe)
                    Text(
                      data['senderName'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentColor, // Gold color for name
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),

                  // ⛔ وضع تعليق على محتوى الصور والفيديو (لأنه تم تعطيل الرفع)
                  if (messageType == 'text') 
                    // عرض الرسالة النصية العادية
                    Text(
                      data['text'] ?? 'Empty message',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                      ),
                    )
                  else 
                    // رسالة نصية بديلة إذا كان المحتوى ليس نصياً وتم تعطيله
                    Text(
                      data['text'] ?? 'Media content (disabled)',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

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
                            color: isMe ? AppColors.darkTextColor.withOpacity(0.6) : AppColors.darkGrayColor.withOpacity(0.7),
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

  // 🟢 مؤشر الرسالة المردود عليها (شكل محسن)
  Widget _buildReplyToIndicator(Map<String, dynamic> replyTo, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), 
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        // خلفية فاتحة للردود
        color: isMe ? AppColors.whiteColor.withOpacity(0.7) : AppColors.replyColor.withOpacity(0.3), 
        borderRadius: BorderRadius.circular(8),
        // شريط جانبي بلون مميز
        border: Border(left: BorderSide(color: AppColors.accentColor, width: 3)), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replied to: ${replyTo['originalSenderName']}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isMe ? AppColors.primaryColor1 : AppColors.accentColor, // لون مختلف حسب المرسل
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyTo['originalText'] ?? '.. Attached message ..',
            maxLines: 2, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? AppColors.darkTextColor : AppColors.darkGrayColor, 
            ),
          ),
        ],
      ),
    );
  }
  
  // ⛔ تم وضع تعليق على الدالة: _buildVideoPlaceholder
  /*
  Widget _buildVideoPlaceholder(String videoUrl, BuildContext context) {
      return Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.blackColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.videocam_rounded, size: 50, color: AppColors.primaryColor1), // أيقونة فيديو واضحة
            const Positioned(
              bottom: 10,
              child: Text(
                'Video Sent',
                style: TextStyle(color: AppColors.whiteColor, fontSize: 12),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                     _showAlertDialog('Video Playback', 'Video playback is not supported in this environment, but the file is attached.');
                  },
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
  }
  */

  // 🟢 عرض التفاعلات المجمعة 
  Widget _buildReactionsDisplay(List<dynamic> reactions) {
    final Map<String, List<String>> reactionsMap = {};
    
    for (var reaction in reactions) {
      final emoji = reaction['emoji'] as String;
      final name = reaction['name'] as String;
      
      if (!reactionsMap.containsKey(emoji)) {
        reactionsMap[emoji] = [];
      }
      reactionsMap[emoji]!.add(name);
    }
    
    return GestureDetector(
      onTap: () {
        if (reactions.isNotEmpty) {
          _showReactorsList(reactionsMap);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionsMap.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(left: 3),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.blackColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentColor, width: 0.5),
            ),
            child: Text(
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
                'React to: ${data['senderName']}', 
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
                title: const Text('Reply to message', style: TextStyle(color: AppColors.whiteColor)),
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

  // 🟢 صندوق عرض الرسالة المردود عليها (شكل محسن)
  Widget _buildReplyToBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.cardBackgroundColor, 
        // شريط جانبي بارز
        border: Border(left: BorderSide(color: AppColors.accentColor, width: 4)), 
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replying to: ${_replyToMessage!['senderName'] ?? 'User'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentColor),
                  ),
                  Text(
                    _replyToMessage!['text'] ?? 'Message',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.whiteColor),
                  ),
                ],
              ),
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
            'Details:',
            style: TextStyle(fontSize: 14, color: AppColors.accentColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.fitness_center, 
            'Target Muscle', 
            widget.room.targetMuscle,
            AppColors.accentColor,
          ),
          _buildDetailRow(
            Icons.access_time_filled, 
            'Start Time', 
            DateFormat('EEEE, hh:mm a', 'en_US').format(widget.room.startTime.toDate().toLocal()),
            AppColors.primaryColor1,
          ),
          _buildDetailRow(
            Icons.people_alt, 
            'Participants', 
            '${widget.room.participants.length} / ${widget.room.maxCapacity} joined',
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
            // ⛔ زر إرفاق الملفات - تم وضع تعليق عليه
            /*
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.accentColor), 
              onPressed: _showMediaPickerDialog, 
            ),
            */
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.whiteColor),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrayColor)),
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
            child: const Text('OK', style: TextStyle(color: AppColors.accentColor)),
          )
        ],
      ),
    );
  }
  
  // =========================================================================
  // 8. عرض قائمة المتفاعلين (تم إكمالها)
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
                'People Who Reacted', 
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
                            '$emoji (${names.length})', 
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
