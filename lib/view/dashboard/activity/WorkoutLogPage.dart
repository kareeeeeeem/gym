import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// Data Models
// -----------------------------------------------------------------------------

class Exercise {
  final String name;
  final int sets;
  final String reps;
  int currentSet;
  final String initialWeight;
  final List<String> actualWeights;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.initialWeight,
    this.currentSet = 1,
    List<String>? actualWeights,
  }) : actualWeights = actualWeights ?? List.filled(sets, initialWeight);

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final List<dynamic> weightsList = json['actualWeights'] ?? [];
    final initialWeight = json['initialWeight'] as String? ?? '0kg';

    return Exercise(
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: json['reps'] as String,
      initialWeight: initialWeight,
      currentSet: 1,
      actualWeights: weightsList.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'initialWeight': initialWeight,
      'actualWeights': actualWeights,
    };
  }
}

class Routine {
  final String id;
  final String name;
  final bool isCustom;
  final List<Exercise> exercises;

  Routine({
    required this.id,
    required this.name,
    required this.isCustom,
    required this.exercises,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    final List<dynamic> exList = json['exercises'] ?? [];
    return Routine(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? 'Custom Routine',
      isCustom: json['isCustom'] ?? true,
      exercises: exList.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCustom': isCustom,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkoutLog {
  final String routineId;
  final String routineName;
  final DateTime date;
  final List<Exercise> completedExercises;

  WorkoutLog({
    required this.routineId,
    required this.routineName,
    required this.date,
    required this.completedExercises,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    final List<dynamic> exList = json['completedExercises'] ?? [];
    return WorkoutLog(
      routineId: json['routineId'] as String,
      routineName: json['routineName'] as String,
      date: DateTime.parse(json['date'] as String),
      completedExercises: exList.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routineId': routineId,
      'routineName': routineName,
      'date': date.toIso8601String(),
      'completedExercises': completedExercises.map((e) => e.toJson()).toList(),
    };
  }
}

// Default Routines
final List<Routine> defaultRoutines = [
  Routine(
    id: 'default-1',
    name: "Full Body Blast",
    isCustom: false,
    exercises: [
      Exercise(name: "Barbell Squats", sets: 3, reps: '10-12', initialWeight: '60kg'),
      Exercise(name: "Bench Press", sets: 3, reps: '10', initialWeight: '40kg'),
      Exercise(name: "Dumbbell Rows", sets: 3, reps: '10', initialWeight: '15kg'),
      Exercise(name: "Overhead Press", sets: 3, reps: '10', initialWeight: '20kg'),
    ],
  ),
  Routine(
    id: 'default-2',
    name: "Push Day (Chest, Shoulders, Triceps)",
    isCustom: false,
    exercises: [
      Exercise(name: "Incline Dumbbell Press", sets: 4, reps: '8', initialWeight: '30kg'),
      Exercise(name: "Lateral Raises", sets: 3, reps: '12', initialWeight: '5kg'),
      Exercise(name: "Triceps Pushdown", sets: 3, reps: '10-12', initialWeight: '10kg'),
    ],
  ),
];

// -----------------------------------------------------------------------------
// Styling Constants
// -----------------------------------------------------------------------------

abstract class AppColors {
  static const Color primary = Color(0xFF1E88E5); // Deep Ocean Blue
  static const Color accent = Color(0xFF00E5FF); // Electric Cyan
  static const Color background = Colors.white;
  static const Color card = Colors.white;
  static const Color darkText = Color(0xFF263238);
}

const double kBorderRadius = 25.0;

// -----------------------------------------------------------------------------
// Local Storage Service (Mockup)
// -----------------------------------------------------------------------------

class LocalStorageService {
  static const String _routinesKey = 'custom_routines_json';
  static const String _logsKey = 'workout_logs_json';
  static final Map<String, String> _storage = {};

  Future<List<Routine>> loadCustomRoutines() async {
    final String? routinesJsonString = _storage[_routinesKey];
    if (routinesJsonString == null || routinesJsonString.isEmpty) return [];

    try {
      final List<dynamic> routinesList = jsonDecode(routinesJsonString) as List<dynamic>;
      return routinesList
          .map((json) => Routine.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error decoding routines from local storage: $e");
      return [];
    }
  }

  Future<void> saveCustomRoutines(List<Routine> routines) async {
    try {
      final List<Map<String, dynamic>> routinesJsonList =
          routines.map((r) => r.toJson()).toList();
      final String routinesJsonString = jsonEncode(routinesJsonList);
      _storage[_routinesKey] = routinesJsonString;
    } catch (e) {
      print("Error saving routines to local storage: $e");
    }
  }
  
  Future<void> saveWorkoutLog(WorkoutLog log) async {
    try {
      List<WorkoutLog> logs = await loadWorkoutLogs();
      logs.removeWhere((l) => l.routineId == log.routineId);
      logs.add(log);

      final List<Map<String, dynamic>> logsJsonList =
          logs.map((l) => l.toJson()).toList();
      final String logsJsonString = jsonEncode(logsJsonList);
      _storage[_logsKey] = logsJsonString;
    } catch (e) {
      print("Error saving workout log: $e");
    }
  }

  Future<List<WorkoutLog>> loadWorkoutLogs() async {
    final String? logsJsonString = _storage[_logsKey];
    if (logsJsonString == null || logsJsonString.isEmpty) return [];

    try {
      final List<dynamic> logsList = jsonDecode(logsJsonString) as List<dynamic>;
      return logsList
          .map((json) => WorkoutLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error decoding workout logs from local storage: $e");
      return [];
    }
  }
}

// -----------------------------------------------------------------------------
// App Initialization
// -----------------------------------------------------------------------------

void main() {
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workout Tracker Pro',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.darkText),
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
          elevation: 8, // Stronger shadow
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius * 0.6)),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            elevation: 5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
           border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(kBorderRadius * 0.4),
             borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
           ),
           focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(kBorderRadius * 0.4),
             borderSide: const BorderSide(color: AppColors.primary, width: 2),
           ),
           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const WorkoutLogPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// Main Screen (WorkoutLogPage) - Home Screen
// -----------------------------------------------------------------------------

class WorkoutLogPage extends StatefulWidget {
  const WorkoutLogPage({super.key});

  @override
  State<WorkoutLogPage> createState() => _WorkoutLogPageState();
}

class _WorkoutLogPageState extends State<WorkoutLogPage> {
  final LocalStorageService _localStorage = LocalStorageService();
  List<Routine> _customRoutines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    try {
      final loadedRoutines = await _localStorage.loadCustomRoutines();
      setState(() {
        _customRoutines = loadedRoutines;
        _isLoading = false;
      });
    } catch (e) {
      print("Failed to load routines: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRoutine(String routineId, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this routine? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _customRoutines.removeWhere((r) => r.id == routineId);
      await _localStorage.saveCustomRoutines(_customRoutines);
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine deleted successfully.'), backgroundColor: Colors.lightBlue),
      );
    }
  }

  void _addRoutine(Routine newRoutine) async {
    _customRoutines.add(newRoutine);
    await _localStorage.saveCustomRoutines(_customRoutines);
    setState(() {});
  }

  void _startWorkout(BuildContext context, Routine routine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutScreen(routine: routine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Routines'),
        centerTitle: false,
      ),
      // Use LTR directionality for English text by default
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create Custom Routine Button - Stunning Accent Design
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kBorderRadius),
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateRoutineScreen(
                          onRoutineCreated: _addRoutine,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.white, size: 30),
                        SizedBox(width: 15),
                        Text(
                          'Custom Workout ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Available Routines',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const Divider(height: 20, thickness: 1.5, color: AppColors.primary),

            // Routines List
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(30.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ))
            else
             // ...defaultRoutines.map((routine) => _buildRoutineCard(context, routine)),
              ..._customRoutines.map((routine) => _buildRoutineCard(context, routine)).toList(),
          ],
        ),
      ),
    );
  }

  // Routine Card Design - Clean and Modern
  Widget _buildRoutineCard(BuildContext context, Routine routine) {
    final Color indicatorColor = routine.isCustom ? AppColors.accent : AppColors.primary;

    return Card(
      color: AppColors.card,
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: indicatorColor.withOpacity(0.2), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.darkText),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${routine.exercises.length} Exercises • ${routine.isCustom ? 'Custom' : 'Default'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              // Start Button
              ElevatedButton.icon(
                onPressed: () => _startWorkout(context, routine),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: indicatorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
              ),
              // Delete Button for Custom Routines
              if (routine.isCustom)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                  onPressed: () => _deleteRoutine(routine.id, context),
                  tooltip: 'Delete Routine',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Create Routine Screen
// -----------------------------------------------------------------------------

class CreateRoutineScreen extends StatefulWidget {
  final Function(Routine) onRoutineCreated;
  const CreateRoutineScreen({super.key, required this.onRoutineCreated});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _routineNameController = TextEditingController();
  final List<ExerciseInput> _exerciseInputs = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addExerciseInput();
  }

  void _addExerciseInput() {
    setState(() {
      _exerciseInputs.add(ExerciseInput(key: UniqueKey()));
    });
  }

  void _removeExerciseInput(Key key) {
    setState(() {
      _exerciseInputs.removeWhere((input) => input.key == key);
      if (_exerciseInputs.isEmpty) {
        _addExerciseInput();
      }
    });
  }

  void _saveRoutine() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        List<Exercise> exercises = [];
        for (var input in _exerciseInputs) {
          final data = input.getData();
          if (data != null) {
            exercises.add(data);
          }
        }

        if (exercises.isEmpty) {
          throw 'Please add at least one exercise.';
        }

        final newRoutine = Routine(
          id: const Uuid().v4(),
          name: _routineNameController.text.trim(),
          isCustom: true,
          exercises: exercises,
        );

        widget.onRoutineCreated(newRoutine);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom routine saved successfully!'), backgroundColor: Colors.lightBlue),
        );
        Navigator.of(context).pop();

      } catch (e) {
        print("Save Error: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save routine: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Routine'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Routine Name:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color:Colors.black),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                        style: const TextStyle(color: Colors.white), // 👈 هنا اللون الأسود

                      controller: _routineNameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Chest & Arm Workout',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a routine name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      'Exercises:',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
                    ),
                    const Divider(height: 20, thickness: 1),

                    ..._exerciseInputs.asMap().entries.map((entry) {
                      final input = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ExerciseInputCard(
                          key: input.key,
                          exerciseInput: input,
                          onRemove: _exerciseInputs.length > 1 ? () => _removeExerciseInput(input.key!) : null,
                        ),
                      );
                    }).toList(),

                    OutlinedButton.icon(
                      onPressed: _addExerciseInput,
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('Add New Exercise'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius * 0.4)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.only(
        top: 8.0, 
        left: 16.0, 
        right: 16.0, 
        bottom: 100.0,
      ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRoutine,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Routine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Exercise Input Components
// -----------------------------------------------------------------------------

class ExerciseInput {
  final Key key;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  ExerciseInput({required this.key}) {
    weightController.text = '';
  }

  Exercise? getData() {
    final name = nameController.text.trim();
    final setsText = setsController.text.trim();
    final reps = repsController.text.trim();
    final weight = weightController.text.trim();

    if (name.isNotEmpty && setsText.isNotEmpty && reps.isNotEmpty && weight.isNotEmpty) {
      final sets = int.tryParse(setsText);
      if (sets != null && sets > 0) {
        return Exercise(
          name: name,
          sets: sets,
          reps: reps,
          initialWeight: weight,
        );
      }
    }
    return null;
  }
}

class ExerciseInputCard extends StatelessWidget {
  final ExerciseInput exerciseInput;
  final VoidCallback? onRemove;

  const ExerciseInputCard({
    required super.key,
    required this.exerciseInput,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kBorderRadius * 0.7),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.shade200,
        //     blurRadius: 10,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exercise Details',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 24),
                  onPressed: onRemove,
                  tooltip: 'Remove Exercise',
                ),
            ],
          ),
          const Divider(height: 10, thickness: 1),
          TextFormField(
            controller: exerciseInput.nameController,
              style: const TextStyle(color: Colors.black), // 👈 هنا اللون الأسود

            decoration: const InputDecoration(
              hintText: 'e.g. Pull-ups',
              labelText: 'Name',
              isDense: true,
              
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                    style: const TextStyle(color: Colors.black), // 👈 هنا اللون الأسود

                  controller: exerciseInput.setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Sets',
                    labelText: 'Sets',
                    isDense: true,
                    
                    
                    
                  ),
                  validator: (value) {
                    if (value == null || int.tryParse(value) == null) return 'Must be a number';
                    if (int.parse(value) <= 0) return '> 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                    style: const TextStyle(color: Colors.black), // 👈 هنا اللون الأسود

                  controller: exerciseInput.repsController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 10 or 60s',
                    labelText: 'Reps/Duration',
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                    style: const TextStyle(color: Colors.black), // 👈 هنا اللون الأسود

                  controller: exerciseInput.weightController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 20kg',
                    labelText: 'Weight',
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Workout Execution Screen (Improved: Added Rest Timer)
// -----------------------------------------------------------------------------

class WorkoutScreen extends StatefulWidget {
  final Routine routine;
  const WorkoutScreen({super.key, required this.routine});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final LocalStorageService _localStorage = LocalStorageService();
  late List<Exercise> _exercises;
  int _currentExerciseIndex = 0;
  final TextEditingController _currentWeightController = TextEditingController();
  WorkoutLog? _lastLog;
  bool _isLoadingLog = true;

  // Rest Timer State
  Timer? _restTimer;
  static const int _restDuration = 60; // 60 seconds rest
  int _restSeconds = _restDuration;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _initializeExercises();
    _loadLastLog();
  }
  
  void _initializeExercises() {
      // Deep copy and initial setup
    _exercises = widget.routine.exercises.map((e) => Exercise(
      name: e.name,
      sets: e.sets,
      reps: e.reps,
      initialWeight: e.initialWeight,
      currentSet: 1,
      actualWeights: List.filled(e.sets, e.initialWeight),
    )).toList();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLastLog() async {
    final logs = await _localStorage.loadWorkoutLogs();
    final lastLog = logs.firstWhereOrNull((log) => log.routineId == widget.routine.id);

    setState(() {
      _lastLog = lastLog;
      _isLoadingLog = false;
    });
    _updateCurrentWeightController();
  }

  void _updateCurrentWeightController() {
    if (_currentExerciseIndex < _exercises.length) {
      final currentEx = _exercises[_currentExerciseIndex];
      final previousExLog = _lastLog?.completedExercises.firstWhereOrNull(
          (logEx) => logEx.name == currentEx.name
      );

      // Use last actual weight if available, otherwise use routine's initial weight
      if (previousExLog != null && previousExLog.actualWeights.isNotEmpty) {
          _currentWeightController.text = previousExLog.actualWeights.last;
      } else {
        _currentWeightController.text = currentEx.initialWeight;
      }
    } else {
      _currentWeightController.text = '';
    }
  }

  Exercise? _getPreviousExerciseLog(String exerciseName) {
    return _lastLog?.completedExercises.firstWhereOrNull(
      (logEx) => logEx.name == exerciseName,
    );
  }

  void _startRestTimer() {
    _restTimer?.cancel(); // Cancel any existing timer
    _restSeconds = _restDuration; // Reset timer value

    setState(() {
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() {
          _restSeconds--;
        });
      } else {
        _stopRestTimer();
      }
    });
  }
  
  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      // When timer stops, update the weight field for the *next* set/exercise
      _updateCurrentWeightController();
    });
  }


  void _nextSet() {
    if (_isResting) {
      // Allow user to skip rest
      _stopRestTimer();
      return;
    }

    setState(() {
      if (_currentExerciseIndex < _exercises.length) {
        final currentEx = _exercises[_currentExerciseIndex];
        final currentSetIndex = currentEx.currentSet - 1;

        // 1. Save the actual weight used
        final actualWeight = _currentWeightController.text.trim();
        if (actualWeight.isNotEmpty && currentSetIndex < currentEx.actualWeights.length) {
           currentEx.actualWeights[currentSetIndex] = actualWeight;
        }

        currentEx.currentSet++;

        if (currentEx.currentSet > currentEx.sets) {
          // Move to the next exercise
          _currentExerciseIndex++;
          // Skip rest if workout is completed or if it's the last set of the last exercise
          if (_currentExerciseIndex < _exercises.length) {
              _startRestTimer(); // Start rest timer before the next exercise
          }
        } else {
            _startRestTimer(); // Start rest timer between sets
        }
      }
    });
  }

  Future<void> _finishWorkout() async {
    _stopRestTimer(); // Ensure timer is stopped if user finishes early

    final workoutLog = WorkoutLog(
      routineId: widget.routine.id,
      routineName: widget.routine.name,
      date: DateTime.now(),
      completedExercises: _exercises,
    );
    await _localStorage.saveWorkoutLog(workoutLog);

    if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout logged successfully!'), backgroundColor:  Colors.lightBlue),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final int totalExercises = _exercises.length;
    final bool workoutCompleted = _currentExerciseIndex >= totalExercises;
    final Exercise? currentEx = workoutCompleted ? null : _exercises[_currentExerciseIndex];

    final double totalSets = _exercises.fold(0.0, (sum, ex) => sum + ex.sets);
    final double completedSets = _exercises.take(_currentExerciseIndex).fold(0.0, (sum, ex) => sum + ex.sets) +
                                (currentEx?.currentSet ?? 1) - 1;
    final double progress = totalSets > 0 ? completedSets / totalSets : 0.0;
    final String nextButtonText = workoutCompleted
        ? 'Finish Workout & Save Log'
        : _isResting
            ? 'Skip Rest / Set ${currentEx!.currentSet} Ready!'
            : 'Next Set / Done';


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        centerTitle: true,
      ),
      body: Column(
          children: [
            // Overall Progress Bar
            _buildProgressBar(progress),
            
            Expanded(
              child: workoutCompleted
                  ? _buildCompletionState(context)
                  : (_isResting
                      ? _buildRestTimer()
                      : _buildWorkoutState(currentEx!, totalExercises)),
            ),

            // Next Set / Finish Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: workoutCompleted ? _finishWorkout : _nextSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: workoutCompleted || _isResting
                      ? AppColors.accent
                      : AppColors.primary,
                  textStyle: const TextStyle(
                    color: Colors.black, // 👈 لون النص
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  minimumSize: const Size.fromHeight(70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadius * 0.6),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  nextButtonText,
                  style: const TextStyle(
                    color: Colors.white, // 👈 تأكيد اللون هنا برضه
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )

          ],
        ),
    );
  }
  
  Widget _buildProgressBar(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: AppColors.primary.withOpacity(0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText)),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    final minutes = (_restSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_restSeconds % 60).toString().padLeft(2, '0');

    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'REST TIME',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: _restSeconds / _restDuration,
                    strokeWidth: 10,
                    backgroundColor: AppColors.accent.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Recovery is Key!',
              style: TextStyle(fontSize: 18, color: AppColors.darkText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutState(Exercise currentEx, int totalExercises) {
    final prevEx = _getPreviousExerciseLog(currentEx.name);
    final int nextSetNumber = currentEx.currentSet > currentEx.sets ? currentEx.sets : currentEx.currentSet;
    final double currentExProgress = (currentEx.currentSet - 1) / currentEx.sets;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              'Exercise ${_currentExerciseIndex + 1} of $totalExercises',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            // Exercise Name Card
            Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      currentEx.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text.rich(
                      TextSpan(
                        text: 'SET ',
                        style: const TextStyle(fontSize: 20, color: Colors.white70),
                        children: [
                          TextSpan(
                            text: '$nextSetNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: AppColors.accent),
                          ),
                          const TextSpan(text: ' / '),
                          TextSpan(
                            text: '${currentEx.sets}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Target Reps & Initial Weight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTargetInfo(Icons.repeat, 'Reps', currentEx.reps),
                _buildTargetInfo(Icons.fitness_center_rounded, 'Target Weight', currentEx.initialWeight),
              ],
            ),

            const SizedBox(height: 30),

            // Input for Actual Weight
            TextFormField(
              controller: _currentWeightController,
                style: const TextStyle(color: Colors.white), // 👈 هنا اللون الأسود

              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              
              decoration: InputDecoration(
                
                labelText: 'Actual Weight Used for This Set',
                labelStyle: const TextStyle(color: AppColors.darkText),
                hintText: 'e.g. 50kg',
                prefixIcon: const Icon(Icons.balance, color: AppColors.primary),
                contentPadding: const EdgeInsets.all(18),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter the weight used';
                return null;
              },
            ),

            const SizedBox(height: 25),

            // Previous Performance Log
            if (_isLoadingLog)
              const Center(child: CircularProgressIndicator(color: AppColors.accent))
            else if (prevEx != null)
              _buildPreviousLogCard(prevEx),

            const SizedBox(height: 20),

            // Current Exercise Progress Bar
            _buildExerciseProgressBar(currentExProgress),

          ],
        ),
      ),
    );
  }

  Widget _buildTargetInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 30),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
      ],
    );
  }

  Widget _buildPreviousLogCard(Exercise prevEx) {
    return Card(
      elevation: 4,
      color: const Color(0xFFE3F2FD), // Very Light Blue Background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Performance 💪',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
            ),
            const Divider(height: 10),
            Wrap(
              spacing: 10.0,
              runSpacing: 8.0,
              children: List.generate(prevEx.actualWeights.length, (index) {
                return Chip(
                  label: Text(
                    'Set ${index + 1}: ${prevEx.reps} x ${prevEx.actualWeights[index]}',
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.8),
                );
              }),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildExerciseProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Current Exercise Progress', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText)),
            Text('${(progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildCompletionState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CONGRATULATIONS! 🎉', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(height: 15),
              Text(
                'You have successfully completed the routine "${widget.routine.name}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _finishWorkout,
                icon: const Icon(Icons.home_rounded, size: 24),
                label: const Text('Return to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper extension for list searching
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
