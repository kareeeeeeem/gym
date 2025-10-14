import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

// ======================================================================
// 0. Global Color & Style Definitions 
// ======================================================================

const Color primaryGradientStart = Color(0xFFF77737); // Orange-Pink
const Color primaryGradientEnd = Color(0xFFC13584); // Purple-Pink
const Color cardBackground = Colors.white; 
const Color textDark = Color(0xFF1E1E1E); // Nearly black for high contrast
const Color textMuted = Color(0xFF5A5A5A); // Dark gray for secondary text
const Color accentSuccess = Color(0xFF1DB954); // Green for log/success

LinearGradient getPrimaryGradient() {
  return const LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

LinearGradient getLightGradient() {
  return LinearGradient(
    colors: [primaryGradientEnd.withOpacity(0.1), primaryGradientStart.withOpacity(0.1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ======================================================================
// 1. Data Models 
// ======================================================================

class SetEntry {
  final int setNumber;
  final double weight;
  final int reps;
  final double e1RM;
  final int rpe;
  final double volume;

  SetEntry({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.e1RM,
    required this.rpe,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'e1RM': e1RM,
        'rpe': rpe,
        'volume': volume,
      };

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
        setNumber: json['setNumber'] as int,
        weight: (json['weight'] as num).toDouble(),
        reps: (json['reps'] as num).toInt(),
        e1RM: (json['e1RM'] as num).toDouble(),
        rpe: (json['rpe'] as num).toInt(),
        volume: (json['volume'] as num).toDouble(),
      );
}

class ExerciseLog {
  final String id; 
  final String exerciseName;
  final String date;
  List<SetEntry> sets;
  double personalRecordWeight;
  double totalVolume;

  ExerciseLog({
    required this.id,
    required this.exerciseName,
    required this.date,
    required this.sets,
    required this.personalRecordWeight,
    required this.totalVolume,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseName': exerciseName,
        'date': date,
        'sets': sets.map((s) => s.toJson()).toList(),
        'personalRecordWeight': personalRecordWeight,
        'totalVolume': totalVolume,
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
        id: json['id'] as String,
        exerciseName: json['exerciseName'] as String,
        date: json['date'] as String,
        sets: (json['sets'] as List)
            .map((s) => SetEntry.fromJson(s as Map<String, dynamic>))
            .toList(),
        personalRecordWeight: (json['personalRecordWeight'] as num).toDouble(),
        totalVolume: (json['totalVolume'] as num).toDouble(),
      );
}

class ExerciseTemplate {
  final String name; 
  final String muscleGroup; 

  ExerciseTemplate({
    required this.name,
    required this.muscleGroup,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'muscleGroup': muscleGroup,
  };

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) => ExerciseTemplate(
    name: json['name'] as String,
    muscleGroup: json['muscleGroup'] as String,
  );
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTemplate &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class WorkoutTemplate {
  final String name;
  final List<ExerciseTemplate> exercises;
  final String iconAsset; 
  final int durationMinutes;

  WorkoutTemplate({
    required this.name,
    required this.exercises,
    required this.iconAsset,
    required this.durationMinutes,
  });
}

// ======================================================================
// 2. Storage Management & Services 
// ======================================================================

class WorkoutLoggerRepository {
  static const String _logKey = 'all_workout_logs';
  static const String _exerciseTemplatesKey = 'exercise_templates'; 
  
  final Map<String, List<ExerciseTemplate>> _defaultExercises = {
    'Chest': [
      ExerciseTemplate(name: 'Barbell Bench Press', muscleGroup: 'Chest'),
      ExerciseTemplate(name: 'Dumbbell Flyes', muscleGroup: 'Chest'),
      ExerciseTemplate(name: 'Cable Crossover', muscleGroup: 'Chest'),
      ExerciseTemplate(name: 'Incline Dumbbell Press', muscleGroup: 'Chest'),
    ],
    'Back': [
      ExerciseTemplate(name: 'Barbell Row', muscleGroup: 'Back'),
      ExerciseTemplate(name: 'Lat Pulldown', muscleGroup: 'Back'),
      ExerciseTemplate(name: 'Deadlift', muscleGroup: 'Back'),
    ],
    'Legs': [
      ExerciseTemplate(name: 'Barbell Squat', muscleGroup: 'Legs'),
      ExerciseTemplate(name: 'Leg Press', muscleGroup: 'Legs'),
      ExerciseTemplate(name: 'Hamstring Curl', muscleGroup: 'Legs'),
    ],
    'Abs': [
      ExerciseTemplate(name: 'Plank', muscleGroup: 'Abs'),
      ExerciseTemplate(name: 'Crunches', muscleGroup: 'Abs'),
    ],
    'Shoulders': [
      ExerciseTemplate(name: 'Overhead Press', muscleGroup: 'Shoulders'),
      ExerciseTemplate(name: 'Lateral Raises', muscleGroup: 'Shoulders'),
    ],
    'Arms': [
      ExerciseTemplate(name: 'Bicep Curls', muscleGroup: 'Arms'),
      ExerciseTemplate(name: 'Tricep Extensions', muscleGroup: 'Arms'),
    ],
    'Other': [
      ExerciseTemplate(name: 'Calf Raises', muscleGroup: 'Other'),
    ]
  };

  Future<Map<String, List<ExerciseTemplate>>> getAllExerciseTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final userExercisesJson = prefs.getString(_exerciseTemplatesKey);
    
    Map<String, List<ExerciseTemplate>> allExercises = {};

    _defaultExercises.forEach((group, list) {
      allExercises[group] = List.from(list); 
    });

    if (userExercisesJson != null && userExercisesJson.isNotEmpty) {
      try {
        final List<dynamic> userList = jsonDecode(userExercisesJson);
        for (var json in userList) {
          final template = ExerciseTemplate.fromJson(json as Map<String, dynamic>);
          
          final currentGroupList = allExercises.putIfAbsent(template.muscleGroup, () => []);
          
          if (!currentGroupList.any((e) => e.name == template.name)) {
              currentGroupList.add(template);
          }
        }
      } catch (e) {
        debugPrint('Repository Error decoding user exercises: $e');
      }
    }
    return allExercises;
  }
  
  Future<void> saveNewExercise(ExerciseTemplate newExercise) async {
    final prefs = await SharedPreferences.getInstance();
    List<ExerciseTemplate> userAdditions = [];

    final userExercisesJson = prefs.getString(_exerciseTemplatesKey);
    if (userExercisesJson != null && userExercisesJson.isNotEmpty) {
      try {
        final List<dynamic> userList = jsonDecode(userExercisesJson);
        userAdditions = userList.map((json) => ExerciseTemplate.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error loading existing user exercises for saving: $e');
      }
    }

    if (!userAdditions.any((e) => e.name == newExercise.name)) {
        userAdditions.add(newExercise);
    } 

    final jsonString = jsonEncode(userAdditions.map((e) => e.toJson()).toList());
    await prefs.setString(_exerciseTemplatesKey, jsonString);
  }
  
  Future<List<ExerciseLog>> getAllLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_logKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ExerciseLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Repository Error decoding logs: $e');
      return [];
    }
  }

  Future<void> saveAllLogs(List<ExerciseLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(logs.map((e) => e.toJson()).toList());
    await prefs.setString(_logKey, jsonString);
  }
}

class WorkoutTemplateService {
  final WorkoutLoggerRepository _repository = WorkoutLoggerRepository();

  Future<List<WorkoutTemplate>> getPredefinedWorkouts() async {
    final exercises = await _repository.getAllExerciseTemplates();
    
    List<ExerciseTemplate> getExercises(String group, int count) {
      final groupExercises = exercises.values.expand((list) => list)
          .where((e) => e.muscleGroup == group)
          .toList();
      return groupExercises.take(count).toList();
    }
    
    final allAvailableExercises = exercises.values.expand((list) => list).toList();

    final customRoutine = allAvailableExercises.length > 4 ? allAvailableExercises.sublist(0, 4) : allAvailableExercises;
    
    return [
      WorkoutTemplate(
        name: 'Fullbody Workout',
        exercises: [
          ...getExercises('Chest', 1), 
          ...getExercises('Back', 1),  
          ...getExercises('Legs', 1),   
          ...getExercises('Abs', 1),   
        ],
        iconAsset: 'assets/person_jumping.png', 
        durationMinutes: 32,
      ),
      WorkoutTemplate(
        name: 'Lowerbody Workout',
        exercises: getExercises('Legs', 3), 
        iconAsset: 'assets/woman_dumbbell.png', 
        durationMinutes: 40,
      ),
      WorkoutTemplate(
        name: 'AB Workout',
        exercises: [
          ...getExercises('Abs', 2), 
          ExerciseTemplate(name: 'Leg Raises', muscleGroup: 'Abs'), 
        ],
        iconAsset: 'assets/man_laying.png', 
        durationMinutes: 20,
      ),
      WorkoutTemplate(
        name: 'Upperbody Workout',
        exercises: [
          ...getExercises('Chest', 2),
          ...getExercises('Back', 2),
          ...getExercises('Shoulders', 1),
          ...getExercises('Arms', 1),
        ],
        iconAsset: 'assets/man_lifting.png', 
        durationMinutes: 45,
      ),
      if (customRoutine.isNotEmpty)
        WorkoutTemplate(
            name: 'روتين مخصص (تجريبي)',
            exercises: customRoutine,
            iconAsset: 'assets/custom_icon.png',
            durationMinutes: 30,
        ),
    ];
  }
}

class WorkoutAnalysisService {
  final WorkoutLoggerRepository _repository = WorkoutLoggerRepository();
  
  double _calculateE1RM(double weight, int reps) {
    if (reps == 0 || reps > 12) return 0.0;
    return double.parse((weight / (1.0278 - (0.0278 * reps))).toStringAsFixed(2));
  }
  
  double _calculateVolume(double weight, int reps) {
    return weight * reps;
  }
  
  Future<ExerciseLog?> getCurrentDayLog(String exerciseName) async {
    final logs = await _repository.getAllLogs();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final logId = '$exerciseName-$today';
    final logIndex = logs.indexWhere((log) => log.id == logId);
    return logIndex != -1 ? logs[logIndex] : null;
  }

  Future<void> logNewSet({
    required String exerciseName,
    required double weight,
    required int reps,
    required int rpe,
  }) async {
    final logs = await _repository.getAllLogs();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final logId = '$exerciseName-$today';

    final e1RMValue = _calculateE1RM(weight, reps);
    final volumeValue = _calculateVolume(weight, reps);

    final existingLogIndex = logs.indexWhere((log) => log.id == logId);

    final newSet = SetEntry(
      setNumber: existingLogIndex != -1 ? logs[existingLogIndex].sets.length + 1 : 1,
      weight: weight,
      reps: reps,
      e1RM: e1RMValue,
      rpe: rpe,
      volume: volumeValue,
    );

    if (existingLogIndex != -1) {
      final log = logs[existingLogIndex];
      log.sets.add(newSet);
      log.totalVolume += volumeValue; 
      if (weight > log.personalRecordWeight) {
        log.personalRecordWeight = weight;
      }
    } else {
      final newLog = ExerciseLog(
        id: logId,
        exerciseName: exerciseName,
        date: today,
        sets: [newSet],
        personalRecordWeight: weight,
        totalVolume: volumeValue,
      );
      logs.add(newLog);
    }
    await _repository.saveAllLogs(logs);
  }

  Future<void> deleteSet({
    required String logId,
    required int setNumber,
  }) async {
    final logs = await _repository.getAllLogs();
    final logIndex = logs.indexWhere((log) => log.id == logId);

    if (logIndex != -1) {
      final log = logs[logIndex];
      final setToDeleteIndex = log.sets.indexWhere((set) => set.setNumber == setNumber);

      if (setToDeleteIndex != -1) {
        final setToDelete = log.sets[setToDeleteIndex];
        final deletedWeight = setToDelete.weight;
        
        log.sets.removeAt(setToDeleteIndex);
        log.totalVolume -= setToDelete.volume;

        if (deletedWeight >= log.personalRecordWeight) {
            log.personalRecordWeight = log.sets.isEmpty 
                ? 0.0 
                : log.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
        }

        for (int i = 0; i < log.sets.length; i++) {
          log.sets[i] = SetEntry(
            setNumber: i + 1,
            weight: log.sets[i].weight,
            reps: log.sets[i].reps,
            e1RM: log.sets[i].e1RM,
            rpe: log.sets[i].rpe,
            volume: log.sets[i].volume,
          );
        }

        if (log.sets.isEmpty) {
          logs.removeAt(logIndex);
        }
        
        await _repository.saveAllLogs(logs);
      }
    }
  }

  Future<SetEntry?> getLastRecordedSet(String exerciseName) async {
    final logs = await _repository.getAllLogs();
    final specificLogs = logs
        .where((log) => log.exerciseName == exerciseName)
        .toList();

    if (specificLogs.isEmpty) return null;

    specificLogs.sort((a, b) => b.date.compareTo(a.date));

    return specificLogs.first.sets.last;
  }
}

// ======================================================================
// 3. New Page: Statistics and Progress 
// ======================================================================

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('الإحصائيات والتقدم', style: TextStyle(color: textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: getPrimaryGradient(),
                ),
                child: const Text(
                  'سيتم هنا عرض الرسوم البيانية لتطور الأداء (الحجم الكلي والأرقام القياسية).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'قريباً: تتبع الحجم الأسبوعي وأفضل أداء (PRs) 📊',
                style: TextStyle(fontSize: 16, color: textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ======================================================================
// 4. UI: Custom Routine Creation BottomSheet (النسخة النهائية)
// ======================================================================

class CreateRoutineBottomSheet extends StatefulWidget {
  final List<ExerciseTemplate> availableExercises;
  final VoidCallback onRoutineCreated;

  const CreateRoutineBottomSheet({
    super.key, 
    required this.availableExercises,
    required this.onRoutineCreated,
  });

  @override
  State<CreateRoutineBottomSheet> createState() => _CreateRoutineBottomSheetState();
}

class _CreateRoutineBottomSheetState extends State<CreateRoutineBottomSheet> {
  final TextEditingController _routineNameController = TextEditingController();
  final List<ExerciseTemplate> _selectedExercises = [];
  
  @override
  void dispose() {
    _routineNameController.dispose();
    super.dispose();
  }

  void _addExercise(ExerciseTemplate exercise) {
    setState(() {
      if (!_selectedExercises.contains(exercise)) {
        _selectedExercises.add(exercise);
      }
    });
  }

  void _removeExercise(ExerciseTemplate exercise) {
    setState(() {
      _selectedExercises.remove(exercise);
    });
  }

  void _saveRoutine() {
    if (_routineNameController.text.trim().isEmpty || _selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الروتين واختيار تمرين واحد على الأقل.')),
      );
      return;
    }

    // هنا يجب إضافة منطق حفظ الروتين الفعلي إلى الشيرد بريفرينسز 

    Navigator.of(context).pop();
    widget.onRoutineCreated();
    
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الروتين "${_routineNameController.text.trim()}" بنجاح!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      // لضمان التعامل مع لوحة المفاتيح
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          // مهم جداً
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إنشاء روتين مخصص', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20),
            
            TextField(
              controller: _routineNameController,
              decoration: InputDecoration(
                labelText: 'اسم الروتين (مثل: صدر وباي)',
                labelStyle: TextStyle(color: textMuted),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGradientEnd)),
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(color: textDark),
            ),
            const SizedBox(height: 20),
            
            const Text('التمارين المختارة:', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8.0,
              children: _selectedExercises.map((exercise) {
                return Chip(
                  backgroundColor: primaryGradientEnd.withOpacity(0.15),
                  label: Text(exercise.name, style: TextStyle(color: primaryGradientEnd, fontWeight: FontWeight.w500)),
                  deleteIcon: Icon(Icons.close, size: 18, color: primaryGradientEnd),
                  onDeleted: () => _removeExercise(exercise),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 15),
            const Text('إضافة تمارين متوفرة:', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
            
            // استخدام ListBody لتجنب أي مشاكل تخطيط قد تنشأ من ListView داخل SingleChildScrollView
            ListBody(
              children: widget.availableExercises.map((exercise) {
                final isSelected = _selectedExercises.contains(exercise);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(exercise.name, style: TextStyle(color: textDark)),
                  subtitle: Text(exercise.muscleGroup, style: TextStyle(color: textMuted, fontSize: 12)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: primaryGradientStart)
                      : Icon(Icons.add_circle_outline, color: textMuted.withOpacity(0.5)),
                  onTap: () {
                    if (isSelected) {
                      _removeExercise(exercise);
                    } else {
                      _addExercise(exercise);
                    }
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 25),
            
            // زر الحفظ
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: getPrimaryGradient(),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('حفظ الروتين', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: _saveRoutine,
                ),
              ),
            ),
            const SizedBox(height: 10), 
          ],
        ),
      ),
    );
  }
}


// ======================================================================
// 5. UI: Main Workout Selection Page (MyTrainsPage)
// ======================================================================

class MyTrainsPage extends StatefulWidget {
  const MyTrainsPage({super.key});

  @override
  State<MyTrainsPage> createState() => _MyTrainsPageState();
}

class _MyTrainsPageState extends State<MyTrainsPage> {
  final WorkoutTemplateService _workoutService = WorkoutTemplateService();
  final WorkoutLoggerRepository _repository = WorkoutLoggerRepository(); 
  List<WorkoutTemplate> _availableWorkouts = [];
  final List<String> _muscleGroups = ['Chest', 'Back', 'Legs', 'Arms', 'Shoulders', 'Abs', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final workouts = await _workoutService.getPredefinedWorkouts();
    setState(() {
      _availableWorkouts = workouts;
    });
  }
  
  // دالة جديدة تستخدم BottomSheet لإضافة تمرين جديد (تجنباً لأخطاء Layout)
  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    String? selectedGroup = _muscleGroups.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'إضافة تمرين جديد',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      labelText: 'اسم التمرين',
                      labelStyle: TextStyle(color: textMuted),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGradientEnd)),
                      border: const OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: textDark), 
                ),
                const SizedBox(height: 15),
                
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setStateInner) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'المجموعة العضلية',
                        labelStyle: TextStyle(color: textMuted),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGradientEnd, width: 2)),
                      ),
                      value: selectedGroup,
                      items: _muscleGroups.map((group) {
                        return DropdownMenuItem(value: group, child: Text(group, style: const TextStyle(color: textDark)));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateInner(() {
                          selectedGroup = newValue;
                        });
                      },
                    );
                  }
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: getPrimaryGradient(),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, 
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('إضافة التمرين', style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () async {
                        if (nameController.text.isNotEmpty && selectedGroup != null) {
                          final newExercise = ExerciseTemplate(
                            name: nameController.text.trim(),
                            muscleGroup: selectedGroup!,
                          );
                          await _repository.saveNewExercise(newExercise);
                          await _loadWorkouts(); 
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تمت إضافة التمرين بنجاح!')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // دالة جديدة تستخدم BottomSheet لإنشاء روتين مخصص (تجنباً لأخطاء Layout)
  void _showCreateRoutineDialog() async {
    final Map<String, List<ExerciseTemplate>> allTemplates = await _repository.getAllExerciseTemplates();
    final List<ExerciseTemplate> allExercises = allTemplates.values.expand((list) => list).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CreateRoutineBottomSheet( // استخدام الكلاس الجديد
          availableExercises: allExercises,
          onRoutineCreated: _loadWorkouts,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text('الروتينات والتخطيط', style: TextStyle(color: textDark)),
        backgroundColor: Colors.white, 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: textDark), 
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsPage()),
                );
            },
            tooltip: 'الإحصائيات',
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: textDark),
            onPressed: _showAddExerciseDialog,
            tooltip: 'إضافة تمرين جديد',
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'ماذا تريد أن تتمرن اليوم؟',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
            ),
          ),
          // Create Custom Routine Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: OutlinedButton.icon(
              onPressed: _showCreateRoutineDialog,
              icon: Icon(Icons.create_new_folder, color: primaryGradientEnd),
              label: Text('إنشاء روتين مخصص', style: TextStyle(color: primaryGradientEnd, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryGradientEnd.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _availableWorkouts.length,
              itemBuilder: (context, index) {
                return _buildWorkoutCard(_availableWorkouts[index], context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutTemplate workout, BuildContext context) {
    final String durationText = '${workout.durationMinutes} دقيقة';
    final String exerciseCount = '${workout.exercises.length} تمارين';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackingPage(
              selectedExercises: workout.exercises,
              routineName: workout.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: textMuted.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5), 
            ),
          ],
          border: Border.all(color: textMuted.withOpacity(0.1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark, 
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$exerciseCount | $durationText',
                      style: const TextStyle(
                        fontSize: 14,
                        color: textMuted, 
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: getLightGradient(), 
                ),
                child: Center(
                  child: Icon(
                    workout.name.contains('Custom') ? Icons.folder_copy : Icons.directions_run, 
                    size: 35, 
                    color: primaryGradientEnd, 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// 6. UI: Live Tracking Page (TrackingPage) 
// ======================================================================

class TrackingPage extends StatefulWidget {
  final List<ExerciseTemplate> selectedExercises;
  final String routineName;

  const TrackingPage({super.key, required this.selectedExercises, required this.routineName});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final WorkoutAnalysisService _loggerService = WorkoutAnalysisService();
  
  double _currentWeight = 10.0;
  int _currentReps = 10;
  int _currentRpe = 8; 
  
  ExerciseLog? _currentExerciseLog;
  SetEntry? _lastSet; 
  int _currentExerciseIndex = 0;
  double _totalRoutineVolume = 0.0; 
  
  Timer? _restTimer;
  int _secondsRemaining = 0; 
  static const int _restDuration = 90; 

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
    _loadTotalRoutineVolume();
  }
  
  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
  
  E? firstWhereOrNull<E>(Iterable<E> iterable, bool Function(E element) test) {
    for (final element in iterable) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  Future<void> _loadTotalRoutineVolume() async {
      final allLogs = await _loggerService._repository.getAllLogs();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      double totalVolume = 0.0;
      for (var exercise in widget.selectedExercises) {
          final logId = '${exercise.name}-$today';
          final log = firstWhereOrNull(allLogs, (l) => l.id == logId);
          if (log != null) {
              totalVolume += log.totalVolume;
          }
      }
      setState(() {
          _totalRoutineVolume = totalVolume;
      });
  }

  Future<void> _loadExerciseData() async {
    final currentExerciseName = widget.selectedExercises[_currentExerciseIndex].name;
    final log = await _loggerService.getCurrentDayLog(currentExerciseName);
    final lastSet = await _loggerService.getLastRecordedSet(currentExerciseName);

    setState(() {
      _currentExerciseLog = log;
      _lastSet = lastSet;
      
      _currentWeight = _lastSet?.weight ?? 10.0;
      _currentReps = _lastSet?.reps ?? 10;
      _currentRpe = _lastSet?.rpe ?? 8;
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _secondsRemaining = _restDuration;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('انتهت فترة الراحة! ابدأ مجموعتك التالية 💪')),
        );
      }
    });
  }

  Future<void> _logAndNext() async {
    if (_currentWeight <= 0 || _currentReps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الوزن والعدات بشكل صحيح.')),
      );
      return;
    }

    await _loggerService.logNewSet(
      exerciseName: widget.selectedExercises[_currentExerciseIndex].name,
      weight: _currentWeight,
      reps: _currentReps,
      rpe: _currentRpe,
    );
    
    _startRestTimer();
    await _loadExerciseData(); 
    await _loadTotalRoutineVolume();
  }

  Future<void> _deleteSet(SetEntry set) async {
    if (_currentExerciseLog == null) return;
    final logId = _currentExerciseLog!.id; 
    await _loggerService.deleteSet(logId: logId, setNumber: set.setNumber);
    await _loadExerciseData(); 
    await _loadTotalRoutineVolume();
  }

  void _goToNextExercise() {
    if (_currentExerciseIndex < widget.selectedExercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      _loadExerciseData();
      _restTimer?.cancel(); 
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أنهيت جميع التمارين! تهانينا 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.selectedExercises[_currentExerciseIndex];
    final logSets = _currentExerciseLog?.sets ?? [];
    final progress = (_currentExerciseIndex + 1) / widget.selectedExercises.length;

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Text(widget.routineName, style: const TextStyle(color: textDark)),
        backgroundColor: Colors.white, 
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine Progress
            _buildProgressHeader(progress, currentExercise.name),
            const SizedBox(height: 20),
            
            // 5.1: مؤقت الراحة
            _buildTimerWidget(),
            const SizedBox(height: 20),
            
            // 5.2: إدخال المجموعة المقترحة
            const Text('تسجيل المجموعة الحالية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            _buildSuggestedSet(),
            const SizedBox(height: 10),

            Row(
              children: [
                _buildStepperInput(
                  label: 'الوزن (كجم)',
                  value: _currentWeight,
                  step: 2.5,
                  min: 0.0,
                  onChanged: (newValue) => setState(() => _currentWeight = max(0.0, newValue)),
                ),
                const SizedBox(width: 8),
                _buildStepperInput(
                  label: 'العدات',
                  value: _currentReps.toDouble(),
                  step: 1.0,
                  min: 1.0, 
                  onChanged: (newValue) => setState(() => _currentReps = max(1, newValue.toInt())),
                ),
                const SizedBox(width: 8),
                _buildStepperInput(
                  label: 'RPE',
                  value: _currentRpe.toDouble(),
                  step: 1.0,
                  min: 6.0,
                  max: 10.0,
                  onChanged: (newValue) => setState(() => _currentRpe = newValue.toInt()),
                ),
              ],
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: getPrimaryGradient(),
                ),
                child: ElevatedButton.icon(
                  onPressed: _logAndNext,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text('تسجيل المجموعة رقم ${logSets.length + 1}', style: const TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, 
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 5.3: زر الانتقال
             SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goToNextExercise,
                icon: const Icon(Icons.skip_next, color: textMuted),
                label: Text('انهاء ${currentExercise.name} والانتقال', style: const TextStyle(fontSize: 16, color: textMuted)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: textMuted,
                  side: BorderSide(color: textMuted.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 5.4: سجل المجموعات الحالي
            const Text('سجل المجموعات التي أكملتها:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            logSets.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('لم يتم تسجيل مجموعات بعد لهذا التمرين.', style: TextStyle(color: textMuted)),
                  )
                : _buildSetsTable(logSets),
          ],
        ),
      ),
    );
  }

  // ======================================================================
  // دوال بناء الواجهة المساعدة 
  // ======================================================================
  
  Widget _buildProgressHeader(double progress, String currentExerciseName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التمرين الحالي: $currentExerciseName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGradientEnd),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: textMuted.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(primaryGradientStart),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_currentExerciseIndex + 1} من ${widget.selectedExercises.length} تمارين مكتملة',
              style: const TextStyle(fontSize: 12, color: textMuted),
            ),
            Text(
              'الحجم الكلي اليوم: ${_totalRoutineVolume.toStringAsFixed(0)} كجم',
              style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerWidget() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final isRunning = _secondsRemaining > 0;
    
    return Card(
      elevation: 4,
      color: isRunning ? primaryGradientStart.withOpacity(0.1) : cardBackground, 
      child: ListTile(
        leading: Icon(isRunning ? Icons.timer_sharp : Icons.snooze, color: isRunning ? primaryGradientStart : textMuted, size: 30),
        title: Text(isRunning ? 'وقت الراحة المتبقي' : 'جاهز للمجموعة التالية!', style: const TextStyle(color: textDark)),
        subtitle: Text('$minutes:$seconds', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isRunning ? primaryGradientEnd : textDark)),
        trailing: isRunning ? TextButton(
          onPressed: () { _restTimer?.cancel(); setState(() => _secondsRemaining = 0); },
          child: const Text('إيقاف', style: TextStyle(color: primaryGradientStart)),
        ) : null,
      ),
    );
  }

  Widget _buildSuggestedSet() {
    if (_lastSet == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('لا يوجد سجل سابق لهذا التمرين.', style: TextStyle(color: textMuted)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'آخر مجموعة مسجلة: ${_lastSet!.weight.toStringAsFixed(1)} كجم × ${_lastSet!.reps} عدة، RPE: ${_lastSet!.rpe} (للمساعدة)',
        style: const TextStyle(fontSize: 14, color: textMuted), 
      ),
    );
  }

  Widget _buildStepperInput({
      required String label,
      required double value,
      required double step,
      required double min,
      double max = double.infinity,
      required ValueChanged<double> onChanged,
    }) {
    final isInteger = step == 1.0;
    final displayValue = isInteger ? value.toInt().toString() : value.toStringAsFixed(1);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: textMuted.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepperButton(Icons.remove, onPressed: () {
                  if (value > min) {
                    onChanged(value - step);
                  }
                }),
                Expanded(
                  child: Center(
                    child: Text(
                      displayValue,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                  ),
                ),
                _buildStepperButton(Icons.add, onPressed: () {
                  if (value < max) {
                    onChanged(value + step);
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepperButton(IconData icon, {required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primaryGradientEnd.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: primaryGradientEnd),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildSetsTable(List<SetEntry> sets) {
    if (_currentExerciseLog == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      color: cardBackground, 
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: textDark))),
            DataColumn(label: Text('الوزن (كجم)', style: TextStyle(fontWeight: FontWeight.bold, color: textDark))),
            DataColumn(label: Text('العدات', style: TextStyle(fontWeight: FontWeight.bold, color: textDark))),
            DataColumn(label: Text('RPE', style: TextStyle(fontWeight: FontWeight.bold, color: textDark))),
            DataColumn(label: Text('حجم', style: TextStyle(fontWeight: FontWeight.bold, color: textDark))),
            DataColumn(label: Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, color: textDark))),
          ],
          rows: sets.map((set) {
            return DataRow(cells: [
              DataCell(Text(set.setNumber.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark))),
              DataCell(Text(set.weight.toStringAsFixed(1), style: const TextStyle(color: textDark))),
              DataCell(Text(set.reps.toString(), style: const TextStyle(color: textDark))),
              DataCell(Text(set.rpe.toString(), style: const TextStyle(color: textDark))),
              DataCell(Text(set.volume.toStringAsFixed(0), style: const TextStyle(color: textDark))),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: primaryGradientStart),
                  onPressed: () => _deleteSet(set), 
                  tooltip: 'حذف المجموعة',
                  constraints: const BoxConstraints(),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}