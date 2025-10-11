import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

// ValueNotifier مشترك للإشعارات
final ValueNotifier<List<Map<String, dynamic>>> notificationsNotifier =
    ValueNotifier<List<Map<String, dynamic>>>([]);

class NotificationsPage extends StatefulWidget {
    static const String routeName = "/notifications"; // <-- أضف هذا

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  // نخزن reference للـ listener عشان نلغيها بعدين
  late VoidCallback _notifierListener;

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    _notifierListener = () {
      if (!mounted) return; // 🔒 تأكد إن الصفحة موجودة قبل setState
      setState(() {
        _notifications = notificationsNotifier.value;
        _unreadCount = _notifications.length;
      });
      _playNotificationEffect();
    };

    notificationsNotifier.addListener(_notifierListener);

    _listenToNotifications();
  }

  @override
  void dispose() {
    notificationsNotifier.removeListener(_notifierListener);
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_notifications');
    final count = prefs.getInt('unread_count') ?? 0;

    if (!mounted) return;

    setState(() {
      if (data != null) {
        _notifications = List<Map<String, dynamic>>.from(jsonDecode(data));
      }
      _unreadCount = count;
    });
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notifications', jsonEncode(_notifications));
    await prefs.setInt('unread_count', _unreadCount);
  }

  Future<void> _playNotificationEffect() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 300);
      }
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint("⚠️ Error playing effect: $e");
    }
  }

  void _listenToNotifications() {
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();

      final notif = event.notification;
      final newNotif = {
        "title": notif.title ?? "No title",
        "body": notif.body ?? "No message",
        "time": DateTime.now().toIso8601String(),
      };

      // تحديث الـ ValueNotifier بدل setState مباشرة
      notificationsNotifier.value = [newNotif, ...notificationsNotifier.value];

      _saveNotifications();
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      debugPrint("🔔 Notification clicked: ${event.notification.title}");
    });
  }

  String formatTime(String timeIso) {
    final time = DateTime.parse(timeIso);
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return DateFormat('dd MMM yyyy • hh:mm a').format(time);
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('saved_notifications');
    prefs.remove('unread_count');
    if (!mounted) return;
    setState(() {
      _notifications.clear();
      _unreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 5, end: 8),
            showBadge: _unreadCount > 0,
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.deepOrange,
              padding: EdgeInsets.all(6),
            ),
            badgeContent: Text(
              '$_unreadCount',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () async {
                if (!mounted) return;
                setState(() => _unreadCount = 0);
                final prefs = await SharedPreferences.getInstance();
                prefs.setInt('unread_count', 0);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications yet 💤",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.notifications_active, color: Colors.black),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              n['title'],
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "NEW",
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            n['body'],
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatTime(n['time']),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
