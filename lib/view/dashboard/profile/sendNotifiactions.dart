import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  // TODO: Replace with your OneSignal keys
  final String oneSignalAppId = 'e17ceb1e-09d4-41d4-aee4-91cdee1b1d6b';
  final String oneSignalApiKey = 'os_v2_app_4f6owhqj2ra5jlxeshg64gy5npqoruu6mq4u4r5yuxk5vsuggywgvdpy4tu3xkvfuwrisn5jtlpokyvjgycmsad5j6ted6s6nnynlfy';

  Future<void> sendNotification() async {
    final String title = _titleController.text.trim();
    final String message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      print("⚠️ Title or Message is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final url = Uri.parse('https://onesignal.com/api/v1/notifications');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $oneSignalApiKey',
        },
        body: jsonEncode({
          "app_id": oneSignalAppId,
          "included_segments": ["All"],
          "headings": {"en": title},
          "contents": {"en": message},
        }),
      );

      print("📤 Sending notification...");
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Notification sent successfully!')),
        );
        _titleController.clear();
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to send: ${response.body}')),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Send Notification", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Send Push Notification to All Users",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Message",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSending ? null : sendNotification,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SEND", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
