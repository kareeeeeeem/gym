import 'package:fitnessapp/view/dashboard/activity/WorkoutLogPage.dart';
import 'package:fitnessapp/view/dashboard/activity/activity_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 

// ===================================================
// 1. DATA MODEL (Exercise Model)
// ===================================================

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
// 2. API SERVICE (WgerApiService)
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
// 3. WORKOUT SERVICE (ChangeNotifier)
// ===================================================

class WorkoutService extends ChangeNotifier {
  static const String _workoutsKey = 'savedWorkouts';
  
  final List<Exercise> _currentWorkout = [];
  
  List<Exercise> get currentWorkout => _currentWorkout;
  
  // ADD EXERCISE TO CURRENT WORKOUT
  void addExerciseToCurrentWorkout(Exercise exercise) {
    if (!_currentWorkout.any((e) => e.id == exercise.id)) {
      _currentWorkout.add(exercise);
      notifyListeners(); 
    } 
  }
  
  // REMOVE EXERCISE FROM CURRENT WORKOUT
  void removeExerciseFromCurrentWorkout(Exercise exercise) {
    _currentWorkout.removeWhere((e) => e.id == exercise.id);
    notifyListeners(); 
  }
  
  // SAVE CURRENT WORKOUT AS PERMANENT ROUTINE
  Future<void> saveCurrentWorkout(String name) async {
    if (_currentWorkout.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final String currentWorkoutsJson = prefs.getString(_workoutsKey) ?? '[]';
    
    List<Map<String, dynamic>> savedWorkouts = 
        (json.decode(currentWorkoutsJson) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final workoutData = {
      'name': name,
      'exercises': _currentWorkout.map((e) => {
        'id': e.id,
        'name': e.name,
        'muscleGroup': e.muscleGroup,
        'description': e.description,
        'gifUrl': e.gifUrl,
      }).toList(),
      'date': DateTime.now().toIso8601String().substring(0, 10), 
    };
    
    savedWorkouts.add(workoutData);
    
    await prefs.setString(_workoutsKey, json.encode(savedWorkouts));
    
    _currentWorkout.clear();
    notifyListeners();
  }

  // LOAD ALL SAVED WORKOUTS
  Future<List<Map<String, dynamic>>> loadSavedWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String currentWorkoutsJson = prefs.getString(_workoutsKey) ?? '[]';
    
    return (json.decode(currentWorkoutsJson) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
  
  // DELETE SAVED WORKOUT
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
  
  // 💡 إضافة دالة إعادة التسمية هنا
  Future<void> renameSavedWorkout(String oldDate, String oldName, String newName) async {
    if (newName.trim().isEmpty || oldName == newName) return;

    final prefs = await SharedPreferences.getInstance();
    final String currentWorkoutsJson = prefs.getString(_workoutsKey) ?? '[]';
    
    List<Map<String, dynamic>> savedWorkouts = 
        (json.decode(currentWorkoutsJson) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // البحث عن الروتين المراد تعديله
    int index = savedWorkouts.indexWhere((w) => w['date'] == oldDate && w['name'] == oldName);
    
    if (index != -1) {
      // تحديث الاسم
      savedWorkouts[index]['name'] = newName;
    }
    
    await prefs.setString(_workoutsKey, json.encode(savedWorkouts));
    notifyListeners();
  }
}

final WorkoutService workoutService = WorkoutService();

// ===================================================
// 4. HELPER WIDGETS AND SCREENS
// ===================================================

// WORKOUT LIST ITEM FOR CURRENT WORKOUT SCREEN
class WorkoutListItem extends StatelessWidget {
  final Exercise exercise;
  const WorkoutListItem({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 1,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            exercise.gifUrl, 
            width: 60, height: 60, 
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
          ),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // ⚠️ تم التعطيل: إخفاء اسم مجموعة العضلات/الوصف
        // subtitle: Text(exercise.muscleGroup),
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () {
            workoutService.removeExerciseFromCurrentWorkout(exercise);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${exercise.name} removed from current routine.')),
            );
          },
        ),
      ),
    );
  }
}

// SAVE WORKOUT SECTION
class _SaveWorkoutSection extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController(
    // 💡 تعديل الاسم الافتراضي
    text: 'تمرين اليوم ${DateTime.now().month}/${DateTime.now().day}' 
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
    
    // الرجوع إلى شاشة المكتبة بعد الحفظ
    Navigator.of(context).popUntil((route) => route.isFirst); 
  }
  
  @override
  Widget build(BuildContext context) {
    // 💡 تم تعديل البادينغ السفلي إلى 0.0 لرفع القسم
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
            // 💡 حقل التسمية مفعل
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 15),
            
            ElevatedButton(
              onPressed: () => _saveWorkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Save as Permanent Routine',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================
// 5. CURRENT WORKOUT SCREEN (TEMPORARY)
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
          // 💡 إضافة زر بـ Padding مخصص لتضييق المسافة
          Padding(
            padding: const EdgeInsets.only(right: 4.0), // تضييق المسافة إلى 4.0 بدلاً من الافتراضية (حوالي 12-16)
            child: IconButton(
              icon: const Icon(Icons.search), // أيقونة البحث كمثال
              onPressed: () {
                 // إضافة وظيفة البحث هنا
              },
              // 💡 إلغاء الـ padding الافتراضي لـ IconButton
              padding: EdgeInsets.zero, 
              constraints: const BoxConstraints(), // لضمان عدم وجود قيود إضافية على الحجم
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: workoutService,
        builder: (context, child) {
          final exercises = workoutService.currentWorkout;
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
                          final exercise = exercises[index];
                          return WorkoutListItem(exercise: exercise);
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
// 6. SAVED WORKOUTS SCREEN (PERMANENT) - NEW!
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
    // Listen for changes when a workout is saved or deleted
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

  // 💡 دالة لفتح نافذة إعادة التسمية
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

          final savedRoutines = snapshot.data!.reversed.toList(); // Newest first
          
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: savedRoutines.length,
            itemBuilder: (context, index) {
              final workout = savedRoutines[index];
              final date = workout['date'] as String;
              final exercises = (workout['exercises'] as List).map((e) => Exercise(
                id: e['id'], name: e['name'], muscleGroup: e['muscleGroup'], description: e['description'], gifUrl: e['gifUrl']
              )).toList();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                child: ExpansionTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(workout['name'] ?? 'Untitled Routine', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Date: $date | ${exercises.length} Exercises'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 💡 زر التعديل/إعادة التسمية الجديد
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
                  children: exercises.map((e) => ListTile(
                    contentPadding: const EdgeInsets.only(left: 30, right: 15),
                    title: Text(e.name),
                    subtitle: Text(e.muscleGroup),
                    leading: Image.network(e.gifUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, ee, s) => const Icon(Icons.fitness_center)),
                  )).toList(),
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
// 7. EXERCISE LIBRARY PAGE - Menu Icon to Saved Workouts
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

      if (newExercises.isEmpty && !isInitial) { setState(() { _isFetchingMore = false; }); return; }

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
    icon: const Icon(Icons.menu), // الأيقونة على الشمال
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
      icon: const Icon(Icons.fitness_center), // الأيقونة على اليمين
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkoutLogPage(),
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
// 8. EXERCISE DETAILS PAGE - Auto Pop implemented
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
                      // لم يتم تعديل اللون هنا بناءً على طلبك الأخير
                      // ولكن يمكنك استخدام: color: Colors.blue, 
                    ), 
                    maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start
                  ),
                  const SizedBox(height: 2),
                  // ⚠️ تم الإبقاء على عرض مجموعة العضلات هنا
                  Text(
                    exercise.muscleGroup, 
                    style: TextStyle(
                      color: Colors.grey[600], 
                      fontSize: 16
                      // يمكنك استخدام: color: Colors.purple,
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
    // **وظيفة الرجوع التلقائي**
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
                      // ⚠️ تم التعطيل: إخفاء عنوان الإرشادات
                      // const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      // const SizedBox(height: 10),
                      // ⚠️ تم التعطيل: إخفاء نص الوصف
                      // Text(exercise.description, style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.start),
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
                  // ⚠️ تم التعطيل: إخفاء اسم التمرين في شريط التنقل
                  // Text(exercise.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(children: const [ 
                    // ⚠️ تم التعطيل: إخفاء زر About
                    // TextButton(onPressed: () {}, child: const Text('About', style: TextStyle(color: Colors.black))), 
                    // ⚠️ تم التعطيل: إخفاء زر Progress
                    // TextButton(onPressed: () {}, child: const Text('Progress', style: TextStyle(color: Colors.black))) 
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
// 9. APP START POINT
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