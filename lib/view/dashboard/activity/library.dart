import 'package:fitnessapp/view/dashboard/activity/WorkoutLogPage.dart';
import 'package:fitnessapp/view/dashboard/activity/note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
// ===================================================
// 1. UPDATED DATA MODELS (Exercise & Set Log)
// ===================================================

// **تم نسخ نماذج SimpleSetLog و SimpleLogEntry من الكود السابق وتم تعديلها**
class SimpleSetLog {
  final TextEditingController repsController; 
  final TextEditingController weightController; 

  SimpleSetLog({String reps = '', String weight = ''}) 
      : repsController = TextEditingController(text: reps),
        weightController = TextEditingController(text: weight);

  Map<String, dynamic> toJson() => {
    'reps': repsController.text,
    'weight': weightController.text,
  };

  factory SimpleSetLog.fromJson(Map<String, dynamic> json) {
    return SimpleSetLog(
      reps: json['reps'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
    );
  }
  
  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

// **تم دمج بيانات Exercise الأساسية مع بيانات SimpleLogEntry**
class ExerciseLogEntry {
  final int id;
  final String name;
  final String muscleGroup; 
  final String description; 
  final String gifUrl;
  final List<SimpleSetLog> sets; // التفاصيل الجديدة للمجاميع والعدات والأوزان
  
  ExerciseLogEntry({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.description,
    required this.gifUrl,
    List<SimpleSetLog>? initialSets,
  }) : sets = initialSets ?? [SimpleSetLog()]; // ضمان وجود Set واحد على الأقل

  // دالة تحويل الكائن إلى خريطة (Map) لحفظه
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'muscleGroup': muscleGroup,
    'description': description,
    'gifUrl': gifUrl,
    'sets': sets.map((setLog) => setLog.toJson()).toList(), // حفظ تفاصيل المجموعات
  };

  // دالة مصنع (Factory) لإنشاء الكائن من بيانات JSON
  factory ExerciseLogEntry.fromJson(Map<String, dynamic> json) {
    List<SimpleSetLog> sets = (json['sets'] as List<dynamic>?)
        ?.map((setJson) => SimpleSetLog.fromJson(setJson as Map<String, dynamic>))
        .toList() ?? [SimpleSetLog()];
        
    if (sets.isEmpty) {
      sets.add(SimpleSetLog());
    }

    return ExerciseLogEntry(
      id: json['id'] as int,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String,
      description: json['description'] as String,
      gifUrl: json['gifUrl'] as String,
      initialSets: sets,
    );
  }
  
  // دالة للتخلص من controllers داخل الكائن
  void dispose() {
    for (var setLog in sets) {
      setLog.dispose();
    }
  }
  
  // دالة مساعدة لتحويل Exercise بسيط إلى ExerciseLogEntry
  static ExerciseLogEntry fromSimpleExercise(Exercise exercise) {
    return ExerciseLogEntry(
      id: exercise.id,
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      description: exercise.description,
      gifUrl: exercise.gifUrl,
      initialSets: [SimpleSetLog()], // بدء بتفاصيل فارغة
    );
  }
}

class Exercise {
  final int id;
  final String name;
  final String muscleGroup; 
  final String description; 
  final String gifUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.description,
    required this.gifUrl,
  });
}

// ===================================================
// 2. API SERVICE (WgerApiService) - NO CHANGES
// ===================================================

class WgerApiService {
  static const String baseUrl = 'https://wger.de/api/v2';
  static const int languageId = 2;

  Future<Map<int, String>> fetchMuscleNames() async {
    final response = await http.get(Uri.parse('$baseUrl/exercisecategory/'));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      Map<int, String> muscleNames = {};
      for (var item in data['results']) {
        muscleNames[item['id']] = item['name'];
      }
      return muscleNames;
    }
    return {};
  }

  Future<Map<int, String>> fetchExerciseImages() async {
    final response = await http.get(Uri.parse('$baseUrl/exerciseimage/?limit=1500')); 
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      Map<int, String> imageMap = {};
      for (var item in data['results']) {
        int exerciseId = item['exercise'];
        if (item['image'] != null && !imageMap.containsKey(exerciseId)) {
          imageMap[exerciseId] = item['image'];
        }
      }
      return imageMap;
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchInitialData() async {
    final results = await Future.wait([
      fetchMuscleNames(),
      fetchExerciseImages(),
    ]);

    return {
      'muscleNames': results[0] as Map<int, String>,
      'imageMap': results[1] as Map<int, String>,
    };
  }

  Future<List<Exercise>> fetchExercisesByPage({
      int limit = 20, 
      int offset = 0,
      required Map<int, String> muscleNames,
      required Map<int, String> imageMap,
      String? muscleFilterName,
    }) async {
    
    int? categoryId;
    if (muscleFilterName != null && muscleFilterName != 'All') {
        for (var entry in muscleNames.entries) {
            if (entry.value == muscleFilterName) {
                categoryId = entry.key;
                break;
            }
        }
    }
    
    String filterQuery = categoryId != null ? '&category=$categoryId' : '';
    
    final exerciseUrl = '$baseUrl/exercise/?limit=$limit&offset=$offset&language=$languageId$filterQuery';
    final response = await http.get(Uri.parse(exerciseUrl));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> results = data['results'] ?? [];

      List<Exercise> exercises = [];
      for (var item in results) {
        int id = item['id'];
        
        String imageUrl = imageMap[id] ?? '';
        if (imageUrl.isEmpty || imageUrl.contains('placeholder')) { 
          continue; 
        }

        int categoryId = item['category'] ?? 0;

        String exerciseName = (item['name'] as String?)?.isNotEmpty == true 
                              ? item['name'] as String 
                              : item['name_original'] as String? ?? 'Exercise';

        String descriptionCleaned = (item['description'] as String?)
            ?.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim() ?? 'No description available.';
        
        exercises.add(Exercise(
          id: id,
          name: exerciseName,
          muscleGroup: muscleNames[categoryId] ?? 'General',
          description: descriptionCleaned,
          gifUrl: imageUrl, 
        ));
      }
      return exercises;
    } else {
      throw Exception('Failed to load exercises from API');
    }
  }
}

// ===================================================
// 3. WORKOUT SERVICE (ChangeNotifier) - UPDATED
// ===================================================

class WorkoutService extends ChangeNotifier {
  static const String _workoutsKey = 'savedWorkouts';
  
  // **تم تغيير النوع إلى ExerciseLogEntry**
  final List<ExerciseLogEntry> _currentWorkout = [];
  
  List<ExerciseLogEntry> get currentWorkout => _currentWorkout;
  
  // ADD EXERCISE TO CURRENT WORKOUT
  // **تم تعديل الدالة لتقبل Exercise بسيط وتحويله**
  void addExerciseToCurrentWorkout(Exercise exercise) {
    if (!_currentWorkout.any((e) => e.id == exercise.id)) {
      _currentWorkout.add(ExerciseLogEntry.fromSimpleExercise(exercise));
      notifyListeners(); 
    } 
  }
  
  // REMOVE EXERCISE FROM CURRENT WORKOUT
  // **تم تعديل الدالة لاستخدام ExerciseLogEntry**
  void removeExerciseFromCurrentWorkout(ExerciseLogEntry exercise) {
    exercise.dispose(); // التخلص من controllers قبل الحذف
    _currentWorkout.removeWhere((e) => e.id == exercise.id);
    notifyListeners(); 
  }
  
  // SAVE CURRENT WORKOUT AS PERMANENT ROUTINE
  Future<void> saveCurrentWorkout(String name) async {
    if (_currentWorkout.isEmpty) return;
    
    // **التخلص من controllers التي لم تعد مستخدمة بعد الحفظ**
    final List<Map<String, dynamic>> exercisesToSave = _currentWorkout.map((e) {
      final json = e.toJson();
      e.dispose(); 
      return json;
    }).toList();


    final prefs = await SharedPreferences.getInstance();
    final String currentWorkoutsJson = prefs.getString(_workoutsKey) ?? '[]';
    
    List<Map<String, dynamic>> savedWorkouts = 
        (json.decode(currentWorkoutsJson) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final workoutData = {
      'name': name,
      'exercises': exercisesToSave, // قائمة التمارين المحولة مع تفاصيل السجل
      'date': DateTime.now().toIso8601String().substring(0, 10), 
    };
    
    savedWorkouts.add(workoutData);
    
    await prefs.setString(_workoutsKey, json.encode(savedWorkouts));
    
    _currentWorkout.clear();
    notifyListeners();
  }

  // LOAD ALL SAVED WORKOUTS - NO CHANGES
  Future<List<Map<String, dynamic>>> loadSavedWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String currentWorkoutsJson = prefs.getString(_workoutsKey) ?? '[]';
    
    return (json.decode(currentWorkoutsJson) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
  
  // DELETE SAVED WORKOUT - NO CHANGES
  Future<void> deleteSavedWorkout(String date, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final String currentWorkoutsJson = prefs.getString(_workoutsKey) ?? '[]';
    
    List<Map<String, dynamic>> savedWorkouts = 
        (json.decode(currentWorkoutsJson) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    savedWorkouts.removeWhere((w) => w['date'] == date && w['name'] == name);
    
    await prefs.setString(_workoutsKey, json.encode(savedWorkouts));
    notifyListeners();
  }
  
  // RENAME SAVED WORKOUT - NO CHANGES
  Future<void> renameSavedWorkout(String oldDate, String oldName, String newName) async {
    if (newName.trim().isEmpty || oldName == newName) return;

    final prefs = await SharedPreferences.getInstance();
    final String currentWorkoutsJson = prefs.getString(_workoutsKey) ?? '[]';
    
    List<Map<String, dynamic>> savedWorkouts = 
        (json.decode(currentWorkoutsJson) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    int index = savedWorkouts.indexWhere((w) => w['date'] == oldDate && w['name'] == oldName);
    
    if (index != -1) {
      savedWorkouts[index]['name'] = newName;
    }
    
    await prefs.setString(_workoutsKey, json.encode(savedWorkouts));
    notifyListeners();
  }
}

final WorkoutService workoutService = WorkoutService();

// ===================================================
// 4. HELPER WIDGETS AND SCREENS - UPDATED
// ===================================================

// **تم تعديل الـ Widget لاستقبال ExerciseLogEntry وإضافة منطق الأوزان/العدات**
class WorkoutListItem extends StatefulWidget {
  final ExerciseLogEntry exerciseLog;
  const WorkoutListItem({super.key, required this.exerciseLog});

  @override
  State<WorkoutListItem> createState() => _WorkoutListItemState();
}

class _WorkoutListItemState extends State<WorkoutListItem> {

  // إضافة دالة مساعدة لإنشاء حقل النص
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
      // أهم نقطة: إعادة بناء الواجهة عند تغيير النص لإجبار ListenableBuilder على التحديث
      onChanged: (_) {
         workoutService.notifyListeners(); 
      },
    );
  }
  
  // Row UI for one Set
  Widget _buildSetRow(SimpleSetLog setLog, int setIndex) {
    final entry = widget.exerciseLog;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            alignment: Alignment.center,
            child: Text('${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildLogTextField(controller: setLog.repsController, isInteger: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildLogTextField(controller: setLog.weightController, isInteger: false)),
          
          if (entry.sets.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  setLog.dispose();
                  entry.sets.removeAt(setIndex);
                  workoutService.notifyListeners(); // إخطار الخدمة بالتغيير
                });
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseLog = widget.exerciseLog;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Name, Image, Delete Button)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    exerciseLog.gifUrl, 
                    width: 50, height: 50, 
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exerciseLog.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () {
                    workoutService.removeExerciseFromCurrentWorkout(exerciseLog);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${exerciseLog.name} removed from current routine.')),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 15, thickness: 1),

            // 2. Table Headers (Reps & Weight)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5),
              child: Row(
                children: [
                  Container(width: 20, alignment: Alignment.center, child: const Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Reps', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            // 3. Sets Log Rows
            ...exerciseLog.sets.asMap().entries.map((setEntry) {
              final setLog = setEntry.value;
              final setIndex = setEntry.key;
              return _buildSetRow(setLog, setIndex);
            }).toList(),
            
            const SizedBox(height: 10),
            
            // 4. Add Set Line Button
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                label: const Text('Add Set', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    exerciseLog.sets.add(SimpleSetLog());
                    workoutService.notifyListeners(); // إخطار الخدمة بالتغيير
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// SAVE WORKOUT SECTION - NO CHANGES (Name Controller updated earlier)
class _SaveWorkoutSection extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController(
    text: 'Today Exrercise ${DateTime.now().month}/${DateTime.now().day}' 
  );

  _SaveWorkoutSection({super.key});

  void _saveWorkout(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the routine.')),
      );
      return;
    }

    await workoutService.saveCurrentWorkout(name);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Routine "$name" saved successfully!')),
    );
    
    Navigator.of(context).popUntil((route) => route.isFirst); 
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0, 
        left: 16.0, 
        right: 16.0, 
        bottom: 80.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
        ),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 15),
            
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                onPressed: () => _saveWorkout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Save Routine',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================
// 5. CURRENT WORKOUT SCREEN (TEMPORARY) - NO CHANGES TO STRUCTURE
// ===================================================

class CurrentWorkoutScreen extends StatelessWidget {
  const CurrentWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text('Current Daily Routine 🏋️'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                 // إضافة وظيفة البحث هنا
              },
              padding: EdgeInsets.zero, 
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: workoutService,
        builder: (context, child) {
          final exercises = workoutService.currentWorkout; // exercises now are ExerciseLogEntry
          return Column(
            children: [
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises selected for this routine yet.\nStart by adding one from the Library!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exerciseLog = exercises[index];
                          return WorkoutListItem(exerciseLog: exerciseLog); // تم تغيير اسم البراميتر
                        },
                      ),
              ),
              if (exercises.isNotEmpty)
                _SaveWorkoutSection(),
            ],
          );
        },
      ),
    );
  }
}

// ===================================================
// 6. SAVED WORKOUTS SCREEN (PERMANENT) - UPDATED
// ===================================================

class SavedWorkoutsScreen extends StatefulWidget {
  const SavedWorkoutsScreen({super.key});

  @override
  State<SavedWorkoutsScreen> createState() => _SavedWorkoutsScreenState();
}

class _SavedWorkoutsScreenState extends State<SavedWorkoutsScreen> {
  Future<List<Map<String, dynamic>>>? _savedWorkouts;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    workoutService.addListener(_loadWorkouts);
  }

  @override
  void dispose() {
    workoutService.removeListener(_loadWorkouts);
    super.dispose();
  }

  void _loadWorkouts() {
    setState(() {
      _savedWorkouts = workoutService.loadSavedWorkouts();
    });
  }
  
  void _confirmDelete(BuildContext context, Map<String, dynamic> workout) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete the routine: ${workout['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              workoutService.deleteSavedWorkout(workout['date'], workout['name']);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _renameWorkout(BuildContext context, Map<String, dynamic> workout) {
    final TextEditingController nameController = TextEditingController(text: workout['name']);
    final String oldDate = workout['date'];
    final String oldName = workout['name'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Rename Routine"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new routine name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                await workoutService.renameSavedWorkout(oldDate, oldName, newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Routine "$oldName" renamed to "$newName".')),
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text("Rename", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  // **تم تعديل هذا الجزء لعرض تفاصيل المجاميع والعدات والأوزان المحفوظة**
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Saved Routines'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 6, 46, 79),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _savedWorkouts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'You have no saved routines. \nSave your daily workout to see it here!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          final savedRoutines = snapshot.data!.reversed.toList();
          
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: savedRoutines.length,
            itemBuilder: (context, index) {
              final workout = savedRoutines[index];
              final date = workout['date'] as String;
              final List<dynamic> exercisesData = workout['exercises'] as List;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                child: ExpansionTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(workout['name'] ?? 'Untitled Routine', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Date: $date | ${exercisesData.length} Exercises'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _renameWorkout(context, workout),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, workout),
                      ),
                    ],
                  ),
                  children: exercisesData.map((e) {
                      // استخراج تفاصيل المجاميع
                      final List<dynamic> sets = e['sets'] as List? ?? [];
                      final String setsSummary = sets.map((s) {
                        return '(${s['reps'] ?? '-'}x) ${s['weight'] ?? '-'}kg';
                      }).join(' | ');

                      return Padding(
                        padding: const EdgeInsets.only(left: 30, right: 15, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(e['name'] ?? 'Exercise Name', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(e['muscleGroup'] ?? 'General'),
                              leading: Image.network(e['gifUrl'] ?? '', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, ee, s) => const Icon(Icons.fitness_center)),
                            ),
                            if (sets.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 55.0, bottom: 8),
                                child: Text(
                                  setsSummary,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            const Divider(height: 1, indent: 55),
                          ],
                        ),
                      );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// ---------------------------------------------------
// 7. EXERCISE LIBRARY PAGE - NO CHANGES
// ---------------------------------------------------

class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key});
  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  final WgerApiService _apiService = WgerApiService();
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
  String _selectedMuscle = 'All'; 
  
  Map<int, String> _muscleNames = {};
  Map<int, String> _imageMap = {};
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isFetchingMore = false; 

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAndPrepareExercises();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 && !_isFetchingMore) {
      _loadMoreExercises();
    }
  }
  
  Future<void> _fetchAndPrepareExercises() async {
    try {
      final initialData = await _apiService.fetchInitialData();
      _muscleNames = initialData['muscleNames'];
      _imageMap = initialData['imageMap'];

      await _loadExercises(isInitial: true);
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadExercises({bool isInitial = false}) async {
    if (!isInitial) { setState(() { _isFetchingMore = true; }); }

    try {
      final newExercises = await _apiService.fetchExercisesByPage(
        limit: _pageSize, offset: _currentPage * _pageSize, muscleNames: _muscleNames,
        imageMap: _imageMap, muscleFilterName: _selectedMuscle,
      );

      if (newExercises.isEmpty && !isInitial) { setState(() { _isFetchingMore = false; return; }); }

      setState(() {
        _allExercises.addAll(newExercises);
        _filteredExercises = (_selectedMuscle == 'All') ? _allExercises : _allExercises.where((e) => e.muscleGroup == _selectedMuscle).toList();
        _currentPage++; 
        _isLoading = false; _isFetchingMore = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _isFetchingMore = false; });
    }
  }
  
  Future<void> _loadMoreExercises() async {
    if (_isLoading || _isFetchingMore) return; 
    await _loadExercises();
  }

  void _filterExercises(String muscle) {
    if (_selectedMuscle == muscle && !_allExercises.isEmpty) return; 

    setState(() {
      _selectedMuscle = muscle;
      _allExercises = []; _filteredExercises = []; _currentPage = 0; 
      _isLoading = true;
    });
    
    _loadExercises(isInitial: true);
    if (_scrollController.hasClients) { _scrollController.jumpTo(0); }
  }

  Widget _buildMuscleFilterBar() {
    Set<String> muscles = {'All', ..._muscleNames.values}.toSet();
    
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        children: muscles.map((muscle) {
          final isSelected = _selectedMuscle == muscle;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              label: Text(muscle, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
              backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
              onPressed: () => _filterExercises(muscle),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double itemHeight = MediaQuery.of(context).size.height / 3.5;
    final double itemWidth = MediaQuery.of(context).size.width / 2;
    final double aspectRatio = itemWidth / itemHeight;

    return Scaffold(
      appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SavedWorkoutsScreen(),
        ),
      );
    },
  ),
  
  title: const Text('Exercise Library'),
  centerTitle: true,
  actions: [


    IconButton(
      icon: const Icon(Icons.sports_gymnastics),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CurrentWorkoutScreen(),
          ),
        );
      },
    ),


    IconButton(
      icon: const Icon(Icons.fitness_center),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkoutLogPage(),
          ),
        );
      },
    ),

    IconButton(
    icon: const Icon(Icons.note_add_outlined),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SimpleWorkoutNotepad(),
        ),
      );
    },
    ),
  ],
),

      body: Column(
        children: [
          _buildMuscleFilterBar(),
          Expanded(
            child: (_isLoading && _allExercises.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty && !_isLoading
                    ? Center( child: Text('No exercises found for "${_selectedMuscle}"', style: const TextStyle(fontSize: 16, color: Colors.grey)))
                    : GridView.builder(
                        controller: _scrollController, 
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0, childAspectRatio: aspectRatio * 0.9, 
                        ),
                        itemCount: _filteredExercises.length + (_isFetchingMore ? 1 : 0), 
                        itemBuilder: (context, index) {
                          if (index >= _filteredExercises.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                          }
                          final exercise = _filteredExercises[index];
                          return ExerciseGridItem(exercise: exercise);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// 8. EXERCISE DETAILS PAGE - NO CHANGES
// ---------------------------------------------------

class ExerciseGridItem extends StatelessWidget {
  final Exercise exercise;
  const ExerciseGridItem({super.key, required this.exercise});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ExerciseDetailPage(exercise: exercise))); },
      child: Container(
        decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3),]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(exercise.gifUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: Center(child: Text('Image for ${exercise.muscleGroup}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name, 
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                    ), 
                    maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.muscleGroup, 
                    style: TextStyle(
                      color: Colors.grey[600], 
                      fontSize: 16
                    ), 
                    textAlign: TextAlign.start
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailPage({super.key, required this.exercise});
  
  void _addRoutineAndPop(BuildContext context) {
    workoutService.addExerciseToCurrentWorkout(exercise);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${exercise.name} added to current routine.')),
    );
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 300, width: double.infinity, color: Colors.grey[100],
                  child: Image.network(exercise.gifUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Center(child: Text('GIF loading failed'))),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // **زر إضافة إلى الروتين الحالي**
                      ElevatedButton.icon(
                        onPressed: () => _addRoutineAndPop(context),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add to Current Routine', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(height: 10),
                      // **زر عرض الروتين الحالي**
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CurrentWorkoutScreen()));
                        },
                        icon: const Icon(Icons.list_alt, color: Colors.black),
                        label: const Text('View Current Routine', style: TextStyle(color: Colors.black, fontSize: 16)),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                      const Divider(height: 40),
                      // **إظهار اسم التمرين**
                      Text(exercise.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 10),
                      // **إظهار اسم العضلة**
                      Text(exercise.muscleGroup, style: const TextStyle(fontSize: 16, color: Colors.blue)),
                      const SizedBox(height: 20),
                      // **إظهار عنوان الإرشادات**
                      const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // **إظهار نص الوصف**
                      Text(exercise.description, style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.start),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 10, right: 10),
              height: 50 + MediaQuery.of(context).padding.top, color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
                  // **إظهار اسم التمرين في شريط التنقل**
                  // Text(exercise.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(children: const [ 
                    // **تم حذف هذه الأزرار بناءً على الكود السابق**
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// 9. APP START POINT - NO CHANGES
// ---------------------------------------------------

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Exercise Library',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.white, elevation: 0.5,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      home: const ExerciseLibraryPage(),
    );
  }
}