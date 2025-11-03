import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// لإضافة دالة التحويل من/إلى JSON
import 'dart:convert'; 
// لحفظ واستعادة البيانات محليًا
import 'package:shared_preferences/shared_preferences.dart'; 

// -------------------------------------------------------------------
// 1. Data Models (نماذج البيانات) - تم إضافة منطق التحويل لـ JSON
// -------------------------------------------------------------------

class SimpleSetLog {
  // جعل controllers نهائية (final) ولكن يجب التخلص منها (dispose) يدويًا
  final TextEditingController repsController; 
  final TextEditingController weightController; 

  // البناء الافتراضي يقبل قيمًا أولية لتمكين الاستعادة من JSON
  SimpleSetLog({String reps = '', String weight = ''}) 
      : repsController = TextEditingController(text: reps),
        weightController = TextEditingController(text: weight);

  // دالة تحويل الكائن إلى خريطة (Map) لحفظه
  Map<String, dynamic> toJson() => {
    'reps': repsController.text,
    'weight': weightController.text,
  };

  // دالة مصنع (Factory) لإنشاء الكائن من بيانات JSON
  factory SimpleSetLog.fromJson(Map<String, dynamic> json) {
    return SimpleSetLog(
      reps: json['reps'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
    );
  }
  
  // دالة للتخلص من controllers داخل الكائن
  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

class SimpleLogEntry {
  final TextEditingController exerciseNameController;
  final List<SimpleSetLog> sets; 

  SimpleLogEntry({String exerciseName = '', List<SimpleSetLog>? initialSets}) 
      : exerciseNameController = TextEditingController(text: exerciseName),
        sets = initialSets ?? [SimpleSetLog()]; // ضمان وجود Set واحد على الأقل

  // دالة تحويل الكائن إلى خريطة (Map) لحفظه
  Map<String, dynamic> toJson() => {
    'name': exerciseNameController.text,
    'sets': sets.map((setLog) => setLog.toJson()).toList(),
  };

  // دالة مصنع (Factory) لإنشاء الكائن من بيانات JSON
  factory SimpleLogEntry.fromJson(Map<String, dynamic> json) {
    // استعادة قائمة المجموعات (Sets)
    List<SimpleSetLog> sets = (json['sets'] as List<dynamic>?)
        ?.map((setJson) => SimpleSetLog.fromJson(setJson as Map<String, dynamic>))
        .toList() ?? [SimpleSetLog()];
        
    // ضمان وجود Set واحد على الأقل
    if (sets.isEmpty) {
      sets.add(SimpleSetLog());
    }

    return SimpleLogEntry(
      exerciseName: json['name'] as String? ?? '',
      initialSets: sets,
    );
  }
  
  // دالة للتخلص من controllers داخل الكائن
  void dispose() {
    exerciseNameController.dispose();
    for (var setLog in sets) {
      setLog.dispose();
    }
  }
}

// -------------------------------------------------------------------
// 2. The Simple Notepad Screen (الشاشة الرئيسية) - تم إضافة منطق الحفظ والتحميل
// -------------------------------------------------------------------

class SimpleWorkoutNotepad extends StatefulWidget {
  const SimpleWorkoutNotepad({Key? key}) : super(key: key);

  @override
  State<SimpleWorkoutNotepad> createState() => _SimpleWorkoutNotepadState();
}

class _SimpleWorkoutNotepadState extends State<SimpleWorkoutNotepad> {
  
  // قائمة تحمل جميع التمارين وسجلاتها
  List<SimpleLogEntry> _logs = [SimpleLogEntry()]; 
  
  final ScrollController _scrollController = ScrollController();
  
  // المفتاح المستخدم للتخزين المحلي
  static const String _logKey = 'fullWorkoutState'; 
  
  // --- Core Logic ---
  
  @override
  void initState() {
    super.initState();
    _loadLogs(); // استدعاء دالة التحميل عند بدء تشغيل الشاشة
  }

  void _addExercise() {
    setState(() {
      _logs.add(SimpleLogEntry());
    });
    
    // التمرير التلقائي للأسفل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // دالة الحفظ: تحويل الحالة إلى JSON وحفظها محليًا
  Future<void> _saveLog() async {
    // تصفية التمارين التي تحتوي على اسم أو بيانات قبل الحفظ
    final List<Map<String, dynamic>> jsonLogs = _logs
        .where((entry) => 
            entry.exerciseNameController.text.trim().isNotEmpty || 
            entry.sets.any((s) => s.repsController.text.isNotEmpty || s.weightController.text.isNotEmpty)
        )
        .map((entry) => entry.toJson())
        .toList();

    // تشفير القائمة إلى سلسلة نصية بصيغة JSON
    final String jsonString = jsonEncode(jsonLogs);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logKey, jsonString);

    // (المنطق القديم لطباعة الملخص تم استبداله بمنطق حفظ الحالة)
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('saved')),
  );
  }
  
  // دالة التحميل: استعادة الحالة من JSON
  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_logKey);
    
    if (jsonString != null && jsonString.isNotEmpty && jsonString != '[]') {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        
        // 1. التخلص من controllers الافتراضية قبل استبدال القائمة
        for (var entry in _logs) {
           entry.dispose();
        }
        
        // 2. إعادة بناء القائمة من JSON
        final List<SimpleLogEntry> loadedLogs = jsonList.map<SimpleLogEntry>((json) {
           return SimpleLogEntry.fromJson(json as Map<String, dynamic>);
        }).toList();

        // 3. تحديث الحالة
        setState(() {
          // إذا كانت القائمة المحملة فارغة، نبدأ بتمرين افتراضي واحد
          _logs = loadedLogs.isNotEmpty ? loadedLogs : [SimpleLogEntry()];
        });
        
      } catch (e) {
        print('Error loading/decoding log: $e');
      }
    }
  }

  @override
  void dispose() {
    // التخلص من جميع controllers لجميع التمارين والمجموعات لمنع تسرب الذاكرة
    _scrollController.dispose();
    for (var entry in _logs) {
      entry.dispose(); // استخدام دالة dispose الجديدة في SimpleLogEntry
    }
    super.dispose();
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Note', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade700,
        actions: [
          // 💡 Add Exercise Button
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white, size: 28),
            tooltip: 'Add New Exercise',
            onPressed: _addExercise,
          ),
          const SizedBox(width: 8),
          // Save Button (الآن يحفظ الحالة لاستعادتها)
          TextButton.icon(
  icon: const Icon(Icons.save, color: Colors.white),
  label: const Text('Save State', style: TextStyle(color: Colors.white, fontSize: 16)),
  onPressed: () async { // تأكد من وجود async إذا كانت عملية الحفظ غير متزامنة
    await _saveLog(); 
    // إذا لم تكن _saveLog تحتوي على pop، يمكنك إضافتها هنا:
    Navigator.pop(context);
  },
),
          
        ],
      ),
      
      body: _logs.isEmpty 
          ? _buildEmptyState()
          : ListView(
            controller: _scrollController, 
            padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 20),
            children: _logs.asMap().entries.map((logEntry) {
              final entry = logEntry.value;
              final index = logEntry.key;
              return _buildLogCard(entry, index);
            }).toList(),
          ),
    );
  }

  // Empty State UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_alt_outlined, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 10),
          const Text('Your notepad is empty.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Start Logging', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  // Card UI for one Exercise
  Widget _buildLogCard(SimpleLogEntry entry, int index) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Exercise Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.exerciseNameController,
                    decoration: InputDecoration(
                      labelText: 'Exercise Name',
                      prefixIcon: const Icon(Icons.label_important, size: 20, color: Colors.blueGrey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10)
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                  ),
                ),
                // Delete Exercise Button
                if (_logs.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                    onPressed: () {
                      setState(() {
                        // يجب التخلص من controllers قبل إزالتها
                        entry.dispose();
                        _logs.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            
            const Divider(height: 25, thickness: 1, color: Colors.blueGrey),

            // 2. Table Headers (Reps & Weight)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5),
              child: Row(
                children: [
                  Container(width: 30, alignment: Alignment.center, child: const Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Reps', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            // 3. Sets Log Rows
            ...entry.sets.asMap().entries.map((setEntry) {
              final setLog = setEntry.value;
              final setIndex = setEntry.key;
              return _buildSetRow(entry, setLog, setIndex);
            }).toList(),
            
            const SizedBox(height: 10),
            
            // 4. Add Set Line Button
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle, color: Colors.blueGrey),
                label: const Text('Add Set', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    entry.sets.add(SimpleSetLog());
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row UI for one Set
  Widget _buildSetRow(SimpleLogEntry entry, SimpleSetLog setLog, int setIndex) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set Number
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text('${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          
          // Reps Field
          Expanded(
            child: _buildLogTextField(
              controller: setLog.repsController,
              isInteger: true,
            ),
          ),
          const SizedBox(width: 8),
          
          // Weight Field
          Expanded(
            child: _buildLogTextField(
              controller: setLog.weightController,
              isInteger: false,
            ),
          ),
          
          // Delete Set Button
          if (entry.sets.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  // التخلص من controllers قبل الحذف
                  setLog.dispose();
                  entry.sets.removeAt(setIndex);
                });
              },
            ),
        ],
      ),
    );
  }
  
  // Helper function for clean text fields
  Widget _buildLogTextField({
    required TextEditingController controller,
    required bool isInteger,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: Colors.blueGrey.shade400, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      keyboardType: isInteger 
          ? TextInputType.number 
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isInteger 
          ? [FilteringTextInputFormatter.digitsOnly] 
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    );
  }
}