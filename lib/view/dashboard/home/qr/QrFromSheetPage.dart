import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class QrFromSheetPage extends StatefulWidget {
  final String userId;
  const QrFromSheetPage({super.key, required this.userId});

  @override
  State<QrFromSheetPage> createState() => _QrFromSheetPageState();
}

class _QrFromSheetPageState extends State<QrFromSheetPage> {
  String? qrUrl; // رابط QR من Google Sheet
  String? localPath; // مسار الصورة المحفوظة محليًا
  bool loading = true;

  final String sheetCsvUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQFboBLUOSqa9kv7XVK4_xEuCapTQSDVu5lDaiY3nGqu36xpk4fC51yfrb1kXXI3KjaRN0LlD-bRVGD/pub?gid=2044843027&single=true&output=csv';

  @override
  void initState() {
    super.initState();
    _fetchQrUrl();
  }

  Future<void> _fetchQrUrl() async {
    setState(() => loading = true);
    
    print('--- QR Code Fetch Start ---');
    print('1. Searching for User ID (Email): ${widget.userId}'); 

    try {
      final resp = await http.get(Uri.parse(sheetCsvUrl + '&t=${DateTime.now().millisecondsSinceEpoch}'));
      
      if (resp.statusCode == 200) {
        final lines = LineSplitter.split(resp.body).toList();
        String? foundUrl;

        // نبدأ البحث من الأسفل (آخر إدخال)
        for (int i = lines.length - 1; i >= 1; i--) {
          final row = lines[i].split(',');
          
          if (row.length < 3) continue;
          
          final id = row[1].trim(); 
          final url = row[2].trim(); 

          print('2. Checking CSV Row ID: "$id" | Original URL: "$url"'); 
          
          // المقارنة
          if (id.toLowerCase() == widget.userId.toLowerCase() && url.isNotEmpty) {
            foundUrl = url;
            print('3. ✅ Match Found! Original URL: $foundUrl');
            break;
          }
        } // نهاية حلقة البحث

        if (foundUrl != null) {
          String finalUrl = foundUrl;
          
          // 💡 منطق التحويل التلقائي:
          if (finalUrl.contains('/file/d/') && finalUrl.contains('/view?')) {
              // هذا هو رابط مشاركة عادي. سنقوم بتحويله إلى رابط تنزيل مباشر.
              
              // 1. استخراج الـ File ID
              final startIndex = finalUrl.indexOf('/d/') + 3;
              final endIndex = finalUrl.indexOf('/view?');
              
              if (startIndex > 3 && endIndex > startIndex) {
                  final fileId = finalUrl.substring(startIndex, endIndex);
                  
                  // 2. بناء رابط التنزيل المباشر مع بارامتر &confirm=no_cached لحل مشكلة Invalid image data
                  finalUrl = 'https://drive.google.com/uc?id=$fileId&export=download&confirm=no_cached';
                  print('4. ✨ Converted URL to Direct Download: $finalUrl');
              }
          }

          qrUrl = finalUrl;
          
          localPath = await _downloadAndSave(finalUrl, widget.userId);
          if (localPath!.isEmpty) {
             print('5. ❌ Download Failed. Attempting to load local file.');
          }
        } else {
          print('4. ❌ Search finished, No QR URL found for ${widget.userId}.');
          await _loadLocalOnly();
        }
      } else {
        print('6. ❌ Failed to load CSV. Status Code: ${resp.statusCode}');
        await _loadLocalOnly();
      }
    } catch (e) {
      print('7. ❌ Connection/Parsing Error: $e');
      await _loadLocalOnly();
    } finally {
        print('--- QR Code Fetch End ---');
        setState(() => loading = false);
    }
}


  Future<void> _loadLocalOnly() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.userId}.png');
    if (await file.exists()) {
      localPath = file.path;
    }
  }

Future<String> _downloadAndSave(String url, String userId) async {
    try {
        final response = await http.get(Uri.parse(url));
        // 💡 تحقق من حالة الرد HTTP
        if (response.statusCode != 200) {
            print('7. ❌ Download Failed. HTTP Status: ${response.statusCode}'); 
            return ''; // إذا لم يكن 200، إرجع فارغاً
        }
        
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$userId.png');
        await file.writeAsBytes(response.bodyBytes);
        print('7. ✅ Download Success. Local Path: ${file.path}');
        return file.path;
    } catch (e) {
        print('7. ❌ Error during download/save: $e'); 
        // ... (باقي كود التحميل المحلي)
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$userId.png');
        if (await file.exists()) return file.path;
        return '';
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My QR Code')),
      body: Center(
        child: loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading your QR Code...'),
                ],
              )
            : localPath == null || localPath!.isEmpty
                ? const Text('No QR Code available yet.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: FadeInImage(
                          // 🚨 هذا هو السطر الذي يسبب الخطأ إذا لم يكن الملف موجوداً
                          // placeholder: AssetImage('assets/loading.gif'),
                          
                          // استخدم هذا بدلاً منه:
                          placeholder: MemoryImage(Uint8List(0)), // placeholder فارغ لا يسبب مشاكل

                          image: FileImage(File(localPath!)) as ImageProvider,
                          fadeInDuration: Duration(seconds: 1), // يمكنك تقليل المدة
                          width: 260,
                          height: 260,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Scan this QR code to proceed',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchQrUrl,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
