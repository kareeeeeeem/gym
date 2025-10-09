import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:vibration/vibration.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenToNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_notifications');
    final count = prefs.getInt('unread_count') ?? 0;

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

      setState(() {
        _notifications.insert(0, newNotif);
        _unreadCount++;
      });

      _saveNotifications();
      _playNotificationEffect();
    });

    OneSignal.Notifications.addClickListener((event) {
      debugPrint("🔔 Notification clicked: ${event.notification.title}");
    });
  }

  String formatTime(String timeIso) {
    final time = DateTime.parse(timeIso);
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hrs ago";
    } else {
      return DateFormat('dd MMM yyyy • hh:mm a').format(time);
    }
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('saved_notifications');
    prefs.remove('unread_count');
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
              badgeColor: Colors.yellowAccent,
              padding: EdgeInsets.all(6),
            ),
            badgeContent: Text(
              '$_unreadCount',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () async {
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
                  child: Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.notifications_active,
                            color: Colors.white),
                      ),
                      title: Text(
                        n['title'],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            n['body'],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatTime(n['time']),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
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
